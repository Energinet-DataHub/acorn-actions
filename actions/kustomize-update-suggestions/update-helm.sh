#!/bin/bash

TARGET="$1"
EXCLUDES="$2"

LIST=$(find "$TARGET" -iname kustomization.yaml | sort)
tmp=$(mktemp -d)
#shellcheck disable=SC2064
trap "rm -rf $tmp" EXIT

for ITEM in $LIST; do
    yq '[.helmCharts[] | del(.valuesInline, .releaseName, .namespace, .includeCRDs)] | .[]' -o json < "$ITEM" | jq -rc | while IFS= read -r item; do
        if [ "$item" = "" ]; then
            continue
        fi

        while read -r exclude; do
            echo "$ITEM" | grep "^$exclude" >/dev/null
            if [ "$?" -eq 0 ]; then
                break 2
            fi
        done < "$EXCLUDES"

        name=$(echo "$item" | jq -r '.name' -)
        repo=$(echo "$item" | jq -r '.repo' -)
        version=$(echo "$item" | jq -r '.version' -)

        helm repo remove "$name" 2>/dev/null >/dev/null || true
        helm repo add "$name" "$repo" 2>/dev/null >/dev/null

        helm search repo "$name/$name" -o json --fail-on-no-result > "$tmp/info"
        status=$?
        helm repo remove "$name" 2>/dev/null >/dev/null
        if [ $status -ne 0 ]; then
            echo "::error::failed to lookup '$name' in '$repo'" 1>&2
            continue
        fi

        updatedVersion=$(jq --arg name "$name/$name" -rc '.[] | select(.name == $name) | .version' < "$tmp/info")
        if [ "$updatedVersion" = "$version" ]; then
            continue
        fi

        echo "yq -ie \"(.helmCharts[] | select(.name == \\\"$name\\\") | .version) = \\\"$updatedVersion\\\"\" $ITEM"
    done | sh -x
done
