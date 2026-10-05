#!/usr/bin/env bash
# memory.sh — remember, recall, forget

# es.sh and fallback.sh must be sourced before this file

# Generate a memory ID
_mem_id() {
  echo "mem-$(date +%s)-$(openssl rand -hex 4)"
}

# Store a memory
# Usage: mem_remember <type> <content> [--title "title"] [--tags t1,t2] [--scope shared] [--category cat]
mem_remember() {
  local type="$1" content="$2"
  shift 2

  local title="" tags="[]" scope="${BRIDGE_AGENT_ID}-only" category=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title) title="$2"; shift 2 ;;
      --tags) tags="$(echo "$2" | jq -R 'split(",")' 2>/dev/null || echo "[]")"; shift 2 ;;
      --scope) scope="$2"; shift 2 ;;
      --category) category="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  local mem_id
  mem_id="$(_mem_id)"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  local doc
  doc="$(jq -n \
    --arg mid "$mem_id" \
    --arg agent "$BRIDGE_AGENT_ID" \
    --arg type "$type" \
    --arg category "$category" \
    --arg title "$title" \
    --arg content "$content" \
    --argjson tags "$tags" \
    --arg source "bridge-cli" \
    --arg created "$now" \
    --arg updated "$now" \
    --arg scope "$scope" \
    '{
      memory_id: $mid,
      agent: $agent,
      type: $type,
      category: $category,
      title: $title,
      title_semantic: $title,
      content: $content,
      content_semantic: $content,
      tags: $tags,
      source: $source,
      created_at: $created,
      updated_at: $updated,
      access_scope: $scope
    }')"

  if es_online; then
    local result
    result="$(es_index "$IDX_MEMORY" "$mem_id" "$doc")"
    if echo "$result" | jq -e '.result == "created"' > /dev/null 2>&1; then
      echo "Remembered [$type]: ${title:-${content:0:60}}... [${mem_id}]"
    else
      fallback_queue "$IDX_MEMORY" "$mem_id" "$doc"
      echo "ES error — queued to fallback [${mem_id}]" >&2
    fi
  else
    fallback_queue "$IDX_MEMORY" "$mem_id" "$doc"
    echo "Offline — queued memory [${mem_id}]"
  fi
}

# ES|QL's DECAY takes a time_duration (milliseconds up to hours); a date
# period like "45d" is rejected. Turn 45d / 12h / 90m into "1080 hours" etc.
# Anything else is passed through as an ES|QL literal.
_esql_decay_duration() {
  local window="$1" num="${1%?}"
  [[ "$num" =~ ^[0-9]+$ ]] || { echo "$window"; return; }
  case "$window" in
    *d) echo "$(( num * 24 )) hours" ;;
    *h) echo "$num hours" ;;
    *m) echo "$num minutes" ;;
    *)  echo "$window" ;;
  esac
}

# Search memories
# Usage: mem_recall <query> [--type X] [--category X] [--limit 5] [--semantic|--keyword|--hybrid]
mem_recall() {
  local query="$1"
  shift

  local type_filter="" category_filter="" limit=5 mode="hybrid"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type) type_filter="$2"; shift 2 ;;
      --category) category_filter="$2"; shift 2 ;;
      --limit) limit="$2"; shift 2 ;;
      --semantic) mode="semantic"; shift ;;
      --keyword) mode="keyword"; shift ;;
      --hybrid) mode="hybrid"; shift ;;
      *) shift ;;
    esac
  done

  local safe_query="${query//\\/\\\\}"
  safe_query="${safe_query//\"/\\\"}"

  local type_clause="" category_clause=""
  [[ -n "$type_filter" ]]     && type_clause="| WHERE type == \"${type_filter}\""
  [[ -n "$category_filter" ]] && category_clause="| WHERE category == \"${category_filter}\""

  if ! es_online; then
    echo "Offline — searching fallback memory"
    fallback_search_memory "$query"
    return
  fi

  # Build scope filter: show shared + own agent's memories
  local filter_clauses="[]"
  filter_clauses="$(jq -n \
    --arg agent "$BRIDGE_AGENT_ID" \
    '[
      {"bool": {"should": [
        {"term": {"access_scope": "shared"}},
        {"term": {"access_scope": ($agent + "-only")}},
        {"term": {"agent": $agent}}
      ]}}
    ]')"

  # Hide retired memories: superseded by the curation workflow or `forget`
  # (status), by `forget` before it set status (type), and later copies of an
  # existing memory (duplicate_of). A term or exists on a field the index
  # doesn't map matches nothing, so this works with and without the curation
  # mapping. Hybrid recall passes it as the ES|QL request filter for the same reason.
  local not_retired='{"bool": {"must_not": [
    {"term": {"status": "superseded"}},
    {"term": {"type": "superseded"}},
    {"exists": {"field": "duplicate_of"}}
  ]}}'
  filter_clauses="$(echo "$filter_clauses" | jq --argjson r "$not_retired" '. + [$r]')"

  if [[ -n "$type_filter" ]]; then
    filter_clauses="$(echo "$filter_clauses" | jq --arg t "$type_filter" '. + [{"term": {"type": $t}}]')"
  fi
  if [[ -n "$category_filter" ]]; then
    filter_clauses="$(echo "$filter_clauses" | jq --arg c "$category_filter" '. + [{"term": {"category": $c}}]')"
  fi

  local search_body
  case "$mode" in
    semantic)
      search_body="$(jq -n \
        --arg q "$query" \
        --argjson filter "$filter_clauses" \
        --argjson limit "$limit" \
        '{
          "retriever": {
            "standard": {
              "query": {
                "bool": {
                  "must": [{"semantic": {"field": "content_semantic", "query": $q}}],
                  "filter": $filter
                }
              }
            }
          },
          "size": $limit
        }')"
      ;;
    keyword)
      search_body="$(jq -n \
        --arg q "$query" \
        --argjson filter "$filter_clauses" \
        --argjson limit "$limit" \
        '{
          "query": {
            "bool": {
              "must": [{"multi_match": {"query": $q, "fields": ["title^2", "content", "tags"]}}],
              "filter": $filter
            }
          },
          "sort": [{"_score": "desc"}, {"updated_at": "desc"}],
          "size": $limit
        }')"
      ;;
    hybrid)
      local esql_query
      esql_query="$(cat <<ESQL
FROM ${IDX_MEMORY} METADATA _id, _score, _index
| FORK (
    WHERE (access_scope == "shared" OR access_scope == "${BRIDGE_AGENT_ID}-only" OR agent == "${BRIDGE_AGENT_ID}") AND (content:"${safe_query}" OR title:"${safe_query}" OR tags:"${safe_query}")
    ${type_clause}
    ${category_clause}
    | SORT _score DESC | LIMIT 50
) (
    WHERE (access_scope == "shared" OR access_scope == "${BRIDGE_AGENT_ID}-only" OR agent == "${BRIDGE_AGENT_ID}") AND content_semantic:"${safe_query}"
    ${type_clause}
    ${category_clause}
    | SORT _score DESC | LIMIT 50
)
| FUSE
| EVAL final_score = _score * DECAY(created_at, NOW(), $(_esql_decay_duration "$BRIDGE_MEMORY_DECAY_WINDOW"))
| EVAL display = COALESCE(title, SUBSTRING(content, 1, 80))
| SORT final_score DESC | LIMIT ${limit}
| KEEP memory_id, type, display, access_scope, agent, content
ESQL
)"
      ;;
  esac

  local result count

  if [[ "$mode" == "hybrid" ]]; then
    result="$(es_request POST "/_query" "$(jq -n --arg q "$esql_query" --argjson f "$not_retired" '{query: $q, filter: $f}')")"
    if echo "$result" | jq -e '.error' > /dev/null 2>&1; then
      echo "ES|QL error: $(echo "$result" | jq -r '.error.reason // .error.type')" >&2
      return 1
    fi
    count="$(echo "$result" | jq '.values | length')"
    if [[ "$count" == "0" ]]; then
      echo "No memories found for: $query"
      return
    fi
    # KEEP order: memory_id[0], type[1], display[2], access_scope[3], agent[4], content[5]
    # The content excerpt matters: the title alone often isn't the answer.
    echo "$result" | jq -r '.values[] | "[\(.[1])] \(.[2]) (scope: \(.[3]), agent: \(.[4])) [\(.[0])]"
      + (if ((.[5] // "") | length) > 0 then "\n    " + ((.[5] | gsub("\\s+"; " ") | ltrimstr(" "))[0:300]) else "" end)'
  else
    result="$(es_search "$IDX_MEMORY" "$search_body")"
    count="$(echo "$result" | jq '.hits.total.value // 0')"
    if [[ "$count" == "0" ]]; then
      echo "No memories found for: $query"
      return
    fi
    echo "$result" | jq -r '.hits.hits[]._source | "[\(.type)] \(.title // .content[:80]) (scope: \(.access_scope), agent: \(.agent)) [\(.memory_id)]"
      + (if ((.content // "") | length) > 0 then "\n    " + ((.content | gsub("\\s+"; " ") | ltrimstr(" "))[0:300]) else "" end)'
  fi
}

# Mark a memory as superseded
# Usage: mem_forget <memory_id> [--superseded-by new_id]
mem_forget() {
  local mem_id="$1"
  shift

  local superseded_by=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --superseded-by) superseded_by="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  # Same fields the curation workflow sets; `type` stays the memory's kind.
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local update_body
  update_body="$(jq -n --arg now "$now" --arg by "$superseded_by" \
    '{status: "superseded", superseded_at: $now, updated_at: $now}
     + (if $by != "" then {superseded_by: $by} else {} end)')"

  local result
  result="$(es_update "$IDX_MEMORY" "$mem_id" "$update_body")"
  if echo "$result" | jq -e '.result == "updated"' > /dev/null 2>&1; then
    echo "Forgot [$mem_id]"
  else
    echo "Failed to forget [$mem_id]" >&2
  fi
}
