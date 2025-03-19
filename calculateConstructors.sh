#!/bin/bash

year_GP="${1:-2025}";

echo "[]" > constructors.json;

constructor_ids=$(jq "[.[] | select(.year==$year_GP)] | map(.constructorId) | unique" f1db-races-race-results.json);

echo "$constructor_ids" | jq -r '.[]' | while read -r constructor_id; do
    constructor=$(jq --arg constructor_id "$constructor_id" '[.[] | select(.id==$constructor_id) | { "id": .id, "name": .name }]' f1db-constructors.json);
    jq --argjson constructor "$constructor" '. += $constructor' constructors.json > tmpFile.json && mv tmpFile.json constructors.json

    pointConstructor=$(jq --arg constructor_id "$constructor_id" --argjson year "$year_GP" '[.[] | select(.constructorId==$constructor_id and .year==$year)]' f1db-seasons-constructor-standings.json);

    jq \
        --argjson constructor "$pointConstructor" \
        'map( if .id == $constructor[0].constructorId then . + $constructor[0] else . end | .wins //= 0)' \
        constructors.json \
        > tmpFile.json && mv tmpFile.json constructors.json;
    jq '. | sort_by(.positionNumber)' constructors.json > tmpFile.json && mv tmpFile.json constructors.json;
done;