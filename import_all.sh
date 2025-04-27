#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Usage:
#   ./import_all.sh [JSON_FILE] [LIMIT]
#
#   JSON_FILE  : raw DBLP JSON (default: dblpv14.json)
#   LIMIT      : optional max number of articles to use in TSV generation
# -----------------------------------------------------------------------------

# 1) parse args
JSON_IN="${1:-dblpv14.json}"
LIMIT="${2-}"

# 2) enforce env vars
: "${NEO4J_AUTH:?You must set NEO4J_AUTH (e.g. export NEO4J_AUTH='neo4j/password')}"
: "${TEAM_NAME:?You must set TEAM_NAME (e.g. export TEAM_NAME='YourTeam')}"

# 3) ensure raw JSON exists
if [[ ! -f "$JSON_IN" ]]; then
  echo "Error: $JSON_IN not found. Exiting." >&2
  exit 1
else
  echo "ℹ️  Found local $JSON_IN, proceeding"
fi

# 4) generate TSVs directly from JSON
echo "🔄 Generating TSVs from $JSON_IN"
CMD=(python3 to_tsvs_from_json.py "$JSON_IN" "$TEAM_NAME")
if [[ -n "$LIMIT" ]]; then
  echo "🔢 Limiting to first $LIMIT records"
  CMD+=("$LIMIT")
fi
"${CMD[@]}"

# 5) import into Neo4j
echo "🚀 Importing into Neo4j"
# parse NEO4J_AUTH credentials
IFS='/' read -r NEO4J_USER NEO4J_PASSWORD <<< "$NEO4J_AUTH"
# construct cypher-shell command
CY_CMD=(cypher-shell)
# allow custom URI (e.g. bolt://neo4j-server:7687)
if [[ -n "${NEO4J_URI-}" ]]; then
  CY_CMD+=("-a" "$NEO4J_URI")
fi
CY_CMD+=("-u" "$NEO4J_USER" "-p" "$NEO4J_PASSWORD" "--format" "plain" "--database" "neo4j")
# execute with import script piped in
"${CY_CMD[@]}" < import_flat.cypher

echo "✅ All done!"