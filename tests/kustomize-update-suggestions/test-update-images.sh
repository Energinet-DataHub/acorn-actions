#!/bin/bash

set +e

BASE=$(dirname "$0")
SCRIPT="$BASE/../../actions/kustomize-update-suggestions/update-images.sh"
FIXTURES="$BASE/fixtures"
RESOURCES="/tmp/fixtures"
TMP=/tmp/logs
TAGGING="/tmp/tagging"

echo "alpine:3" > "$TAGGING"

reset_resources() {
    find "$TMP" -type f -not -name .gitignore -delete
    rm -rf "$RESOURCES" 2>/dev/null
    mkdir -p "$RESOURCES"
    cp -r "$FIXTURES" "$RESOURCES"
}

reset_resources
echo "Test that only the configured alpine is set to a hash"
bash "$SCRIPT" "$RESOURCES" /dev/null "$TAGGING" >"$TMP/out" 2>&1
set -ex
grep -q '+ sed -i' "$TMP/out"
grep -q 'alpine@sha256' "$TMP/out"
test 1 -eq "$(grep -c '@sha256' < "$TMP/out")"
set +ex

reset_resources
echo "Test that excludes prevents updates"
echo "$RESOURCES" >"$TMP/excludes"
bash "$SCRIPT" "$RESOURCES" "$TMP/excludes" "$TAGGING" >"$TMP/out" 2>&1
set -ex
test 0 -eq "$(grep -cv '::notice' < "$TMP/out")"
set +ex

reset_resources
echo "Test that no configurations results in no updates"
bash "$SCRIPT" "$RESOURCES" /dev/null /dev/null >"$TMP/out" 2>&1
set -ex
test 0 -eq "$(grep -cv '::notice' < "$TMP/out")"
set +ex
reset_resources

reset_resources
echo "Test that only the configured alpine is set to a hash when other things are excluded"
printf "doesnotmatter\nalsoirrelevant\n" >"$TMP/excludes"
bash "$SCRIPT" "$RESOURCES" "$TMP/excludes" "$TAGGING" >"$TMP/out" 2>&1
set -ex
grep -q '+ sed -i' "$TMP/out"
grep -q 'alpine@sha256' "$TMP/out"
test 1 -eq "$(grep -c '@sha256' < "$TMP/out")"
set +ex
reset_resources

reset_resources
echo "Test that non-matching configurations results in no updates"
printf "nginx:latest\nubuntu:latest\n" >"$TMP/tags"
bash "$SCRIPT" "$RESOURCES" /dev/null "$TMP/tags" >"$TMP/out" 2>&1
set -ex
test 0 -eq "$(grep -cv '::notice' < "$TMP/out")"
set +ex

echo "Success!"
