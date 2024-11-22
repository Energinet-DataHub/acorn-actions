#!/bin/bash

set -e

BASE=$(dirname "$0")
SCRIPT="$BASE/../../actions/kustomize-update-suggestions/update-helm.sh"
RESOURCES="$BASE/resources"
TMP=$(mktemp -d)

reset_resources() {
    git checkout "$RESOURCES" 2> /dev/null
}
reset_resources

echo "Test 1"
bash "$SCRIPT" "$RESOURCES" /dev/null >"$TMP/out1" 2>&1
set -x
stat "$TMP/out1" > /dev/null
grep -q '+ yq' "$TMP/out1"
grep -q 'cert-manager' "$TMP/out1"
test 1 -eq $(wc -l < "$TMP/out1")
set +x
reset_resources

echo "Test 2"
echo "$RESOURCES" >"$TMP/conf2"
bash "$SCRIPT" "$RESOURCES" "$TMP/conf2" >"$TMP/out2" 2>&1
set -x
stat "$TMP/out2" > /dev/null
test 0 -eq $(wc -l < "$TMP/out2")
set +x
reset_resources

echo "Test 3"
echo "doesnotmatter\nalsoirrelevant" >"$TMP/conf3"
bash "$SCRIPT" "$RESOURCES" "$TMP/conf3" /dev/null >"$TMP/out3" 2>&1
set -x
stat "$TMP/out3" > /dev/null
grep -q '+ yq' "$TMP/out3"
grep -q 'cert-manager' "$TMP/out3"
test 1 -eq $(wc -l < "$TMP/out3")
set +x
reset_resources

echo "Success!"
