#!/usr/bin/env bash
# Builds the bike_project database from the CSVs and runs every analysis in order.
#
# Usage (from the repository root):
#   ./run_all.sh [mysql client options]
#   e.g. ./run_all.sh -u root -p
set -euo pipefail

cd "$(dirname "$0")"
MYSQL_ARGS=("$@")

for script in sql/0*.sql; do
    echo ">> $script" >&2
    mysql --local-infile=1 "${MYSQL_ARGS[@]}" < "$script" > /dev/null
done

echo "All queries ran successfully." >&2
