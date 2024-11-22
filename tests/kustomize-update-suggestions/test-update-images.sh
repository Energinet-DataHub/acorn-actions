#!/bin/bash

set -e

BASE=$(dirname "$0")
SCRIPT="$BASE/../../actions/kustomize-update-suggestions/update-images.sh"
RESOURCES="$BASE/resources"
TMP=$(mktemp -d)
TAGGING="$TMP/tagging"

echo "alpine:3" > "$TAGGING"

reset_resources() {
    git checkout "$RESOURCES" 2> /dev/null
}
reset_resources

echo "Test 1"
bash "$SCRIPT" "$RESOURCES" /dev/null "$TAGGING" >"$TMP/out1" 2>&1
set -x
grep -q '+ yq' "$TMP/out1"
grep -q 'cert-manager' "$TMP/out1"
test 1 -eq $(wc -l < "$TMP/out1")
set +x
reset_resources

echo "Test 2"
echo "$RESOURCES" >"$TMP/conf2"
bash "$SCRIPT" "$RESOURCES" "$TMP/conf2" "$TAGGING" >"$TMP/out2" 2>&1
set -x
test 0 -eq $(wc -l < "$TMP/out2")
set +x
reset_resources

echo "Test 3"
bash "$SCRIPT" "$RESOURCES" /dev/null /dev/null >"$TMP/out3" 2>&1
set -x
test 0 -eq $(wc -l < "$TMP/out3")
set +x
reset_resources

echo "Test 4"
echo "doesnotmatter\nalsoirrelevant" >"$TMP/conf4"
bash "$SCRIPT" "$RESOURCES" "$TMP/conf4" "$TAGGING" >"$TMP/out4" 2>&1
set -x
grep -q '+ yq' "$TMP/out4"
grep -q 'cert-manager' "$TMP/out4"
test 1 -eq $(wc -l < "$TMP/out4")
set +x
reset_resources

echo "Test 5"
echo "nginx:latest\nubuntu:latest" >"$TMP/conf5"
bash "$SCRIPT" "$RESOURCES" /dev/null "$TMP/conf5" >"$TMP/out5" 2>&1
set -x
test 0 -eq $(wc -l < "$TMP/out5")
set +x
reset_resources

echo "Success!"
