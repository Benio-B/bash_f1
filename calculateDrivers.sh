#!/bin/bash

year_GP="${1:-2024}";

echo "[]" > drivers.json;

driver_ids=$(jq "[.[] | select(.year==$year_GP)] | map(.driverId) | unique" f1db-races-race-results.json);

echo "$driver_ids" | jq -r '.[]' | while read -r driver_id; do
    driver=$(jq --arg driver_id "$driver_id" '[.[] | select(.id==$driver_id) | { "id": .id, "name": .name, "abbreviation" : .abbreviation}]' f1db-drivers.json);
    jq --argjson driver "$driver" '. += $driver' drivers.json > tmpFile.json && mv tmpFile.json drivers.json

    pointDriver=$(jq --arg driver_id "$driver_id" --argjson year "$year_GP" '[.[] | select(.driverId==$driver_id and .year==$year)]' f1db-seasons-driver-standings.json);

    jq \
        --argjson driver "$pointDriver" \
        'map( if .id == $driver[0].driverId then . + $driver[0] else . end | .wins //= 0)' \
        drivers.json \
        > tmpFile.json && mv tmpFile.json drivers.json;
    jq '. | sort_by(.positionNumber)' drivers.json > tmpFile.json && mv tmpFile.json drivers.json;

    constructorId=$(jq -r \
        --argjson year "$year_GP" --arg driver_id "$driver_id" \
        '.[] | select(.year==$year) | select(.driverId==$driver_id) | .constructorId' \
        f1db-seasons-entrants-drivers.json\
    );
    constructorName=$(jq -r \
      --arg constructorId "$constructorId" \
      '.[] | select(.id == $constructorId) | .name' \
      f1db-constructors.json
    );

    jq \
        --arg driver_id "$driver_id" \
        --arg constructorId "$constructorId" \
        --arg constructorName "$constructorName" \
        'map( if .id==$driver_id then . + { "constructorId": $constructorId, "constructorName": $constructorName } else . end)' \
        drivers.json \
        > tmpFile.json && mv tmpFile.json drivers.json;
done;