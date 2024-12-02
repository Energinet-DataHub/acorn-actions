#!/bin/bash

echo "ARGH!" 1>&2

TARGET="$1"
EXCLUDES="$2"

echo "Starting at '$TARGET'" 1>&2
echo "I am at '$(pwd)'" 1>&2

LIST=$(find "$TARGET" -iname kustomization.yaml | sort)
tmp=$(mktemp -d)
#shellcheck disable=SC2064
trap "rm -rf $tmp" EXIT

for ITEM in $LIST; do
    echo "Checking '$ITEM'" 1>&2
    yq '[.helmCharts[] | del(.valuesInline, .releaseName, .namespace, .includeCRDs)] | .[]' -o json < "$ITEM" | jq -rc | while IFS= read -r item; do
        if [ "$item" = "" ]; then
            continue
        fi

        echo "not empty" 1>&2

        while read -r exclude; do
            echo "$ITEM | grep ^$exclude" 1>&2
            echo "$ITEM" | grep "^$exclude" >/dev/null
            if [ "$?" -eq 0 ]; then
                echo "break" 1>&2
                break 2
            fi
        done < "$EXCLUDES"

        echo "not excluded" 1>&2

        name=$(echo "$item" | jq -r '.name' -)
        repo=$(echo "$item" | jq -r '.repo' -)
        version=$(echo "$item" | jq -r '.version' -)

        if [[ "$repo" = oci://* ]]; then
            updatedVersion=$(helm show chart "$repo/$name" 2>/dev/null | yq .version)
        else
            updatedVersion=$(helm show chart "$name" --repo "$repo" | yq .version)
        fi

        echo " - $updatedVersion" 1>&2

        if [ "$updatedVersion" = "" ]; then
            echo "::error::failed to lookup '$name' in '$repo'" 1>&2
            continue
        fi

        if [ "$updatedVersion" = "$version" ]; then
            continue
        fi

        echo "yq -ie \"(.helmCharts[] | select(.name == \\\"$name\\\") | .version) = \\\"$updatedVersion\\\"\" $ITEM"
    done | sh -x
done
