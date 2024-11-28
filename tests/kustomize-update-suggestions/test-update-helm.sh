#!/bin/bash

set +e

BASE=$(dirname "$0")
SCRIPT="$BASE/../../actions/kustomize-update-suggestions/update-helm.sh"
FIXTURES="$BASE/fixtures"
RESOURCES="/tmp/fixtures"
TMP=/tmp/logs

reset_resources() {
    find "$TMP" -type f -not -name .gitignore -delete
    rm -rf "$RESOURCES" 2>/dev/null
    mkdir -p "$RESOURCES"
    cp -r "$FIXTURES" "$RESOURCES"
}

reset_resources
echo "Test cert-manager is marked as updatable"
bash "$SCRIPT" "$RESOURCES" /dev/null >"$TMP/out" 2>&1
set -ex
stat "$TMP/out" > /dev/null
grep -q '+ yq' "$TMP/out"
grep -q 'cert-manager' "$TMP/out"
test 1 -eq "$(wc -l < "$TMP/out")"
set +ex

reset_resources
echo "Test excludes correctly prevents cert-manager from being marked"
echo "$RESOURCES" >"$TMP/excludes"
bash "$SCRIPT" "$RESOURCES" "$TMP/excludes" >"$TMP/out" 2>&1
set -ex
stat "$TMP/out" > /dev/null
test 0 -eq "$(wc -l < "$TMP/out")"
set +ex

reset_resources
echo "Test cert-manager is marked as updatable when other things are excluded"
printf "doesnotmatter\nalsoirrelevant\n" >"$TMP/excludes"
bash "$SCRIPT" "$RESOURCES" "$TMP/excludes" /dev/null >"$TMP/out" 2>&1
set -ex
stat "$TMP/out" > /dev/null
grep -q '+ yq' "$TMP/out"
grep -q 'cert-manager' "$TMP/out"
test 1 -eq "$(wc -l < "$TMP/out")"
set +ex

echo "Success!"
