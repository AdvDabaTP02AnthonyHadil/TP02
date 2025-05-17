#!/bin/bash
# wait-for-neo4j.sh

set -e

host="${1:-neo4j-service}"
port="${2:-7687}"

echo "⏳ Waiting for Neo4j at $host:$port ..."

for i in {1..30}; do
    if nc -z "$host" "$port"; then
        echo "✅ Neo4j is ready!"
        exit 0
    fi
    echo "⌛ Still waiting ($i)..."
    sleep 2
done

echo "❌ Timeout waiting for Neo4j"
exit 1
