#!/bin/bash

apt-get install jq;
apt-get install wget;
apt-get install unzip;

year_GP="${1:-2024}";

current_version=$(curl -s GET "https://api.github.com/repos/f1db/f1db/tags?per_page=1" | jq -r '.[].name');
short_version="${current_version:1}";

saved_version=$(jq -r '.version // ""' ./drivers.json) > /dev/null 2>&1;
saved_year=$(jq -r '.year // ""' ./drivers.json) > /dev/null 2>&1;

if [ "$current_version" == "$saved_version" ] && [ "$year_GP" -eq "$saved_year" ]; then
  echo "Same data already used";
  exit;
fi

echo "Data is not same. Refresh it";

mkdir raw;

cd raw;

wget "https://github.com/f1db/f1db/releases/download/$current_version/f1db-json-splitted.zip" -O "f1.zip";
unzip "f1.zip";

(mv **/* .) > /dev/null 2>&1;

driver_ids=$(jq "[.[] | select(.year==$year_GP)] | map(.driverId) | unique" f1db-races-race-results.json);
constructor_ids=$(jq "[.[] | select(.year==$year_GP)] | map(.constructorId) | unique" f1db-races-race-results.json);

echo "[]" > drivers.json;
echo "[]" > constructors.json;

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

wins_data=$(jq --argjson year "$year_GP" '[.[] | select(.year==$year) | select(.positionNumber==1)]
  | reduce .[] as $item (
      {drivers: {}, constructors: {}};
      $item.driverId as $driverId
      | $item.constructorId as $constructorId
      | if $driverId then .drivers[$driverId] += 1 else . end
      | if $constructorId then .constructors[$constructorId] += 1 else . end)
      | {drivers: .drivers, constructors: .constructors}' \
    f1db-races-race-results.json);

jq \
  --argjson wins_data "$wins_data" \
  '$wins_data.drivers as $drivers
  | map(if $drivers[.driverId] then .wins = $drivers[.driverId] else . end)' \
  drivers.json > tmpFile.json && mv tmpFile.json drivers.json;

jq \
  --argjson wins_data "$wins_data" \
  '$wins_data.constructors as $constructors
  | map(if $constructors[.constructorId] then .wins = $constructors[.constructorId] else . end)' \
  constructors.json > tmpFile.json && mv tmpFile.json constructors.json;

jq --argjson year "$year_GP" --arg version "$current_version" '{ "year": $year, "version": $version, "data": {"drivers": .}}' drivers.json > tmpFile.json && mv tmpFile.json drivers.json;
jq --argjson year "$year_GP" --arg version "$current_version" '{ "year": $year, "version": $version, "data": {"constructors": .}}' constructors.json > tmpFile.json && mv tmpFile.json constructors.json;

mv drivers.json ../drivers.json;
mv constructors.json ../constructors.json;

cd ..;

(rm -rf ./raw) > /dev/null 2>&1;
