#!/bin/bash

apk add jq;
apk add wget;
apk add unzip;

folder="/share/f1";
year_GP="${1:-2024}";

current_version=$(curl -s GET "https://api.github.com/repos/f1db/f1db/tags?per_page=1" | jq -r '.[].name');
short_version="${current_version:1}";

mkdir "$folder";
mkdir "$folder"/raw;
cd "$folder"/raw;

wget -O "$folder"/raw/f1.zip  https://github.com/f1db/f1db/releases/download/$current_version/f1db-json-splitted-$short_version.zip;
unzip "$folder"/raw/f1.zip

(mv **/* .) > /dev/null 2>&1;

driver_ids=$(jq "[.[] | select(.year==$year_GP)] | map(.driverId) | unique" f1db-races-race-results.json);
constructor_ids=$(jq "[.[] | select(.year==$year_GP)] | map(.constructorId) | unique" f1db-races-race-results.json);
GP_ids=$(jq ".[] | select(.year==$year_GP) | .id" f1db-races.json);

echo "[]" > drivers.json;
echo "[]" > constructors.json;

echo "$driver_ids" | jq -r '.[]' | while read -r driver_id; do
    driver=$(jq "[.[] | select(.id==\"$driver_id\")]" f1db-drivers.json);
    jq --argjson driver "$driver" '. += $driver' drivers.json > tmpFile.json && mv tmpFile.json drivers.json

    pointDriver=$(jq --arg driver_id "$driver_id" --argjson year "$year_GP" '[.[] | select(.driverId==$driver_id and .year==$year)]' f1db-seasons-driver-standings.json);

    jq \
        --slurpfile formatedDrivers drivers.json \
        --argjson driver "$pointDriver" \
        'map( if .id == $driver[0].driverId then . + $driver[0] else . end | .wins //= 0)' \
        drivers.json \
        > tmpFile.json && mv tmpFile.json drivers.json;
    jq '. | sort_by(.positionNumber)' drivers.json > tmpFile.json && mv tmpFile.json drivers.json;
done;


echo "$constructor_ids" | jq -r '.[]' | while read -r constructor_id; do
    constructor=$(jq "[.[] | select(.id==\"$constructor_id\")]" f1db-constructors.json);
    jq --argjson constructor "$constructor" '. += $constructor' constructors.json > tmpFile.json && mv tmpFile.json constructors.json

    pointConstructor=$(jq --arg constructor_id "$constructor_id" --argjson year "$year_GP" '[.[] | select(.constructorId==$constructor_id and .year==$year)]' f1db-seasons-constructor-standings.json);

    jq \
        --slurpfile formatedConstructors constructors.json \
        --argjson constructor "$pointConstructor" \
        'map( if .id == $constructor[0].constructorId then . + $constructor[0] else . end | .wins //= 0)' \
        constructors.json \
        > tmpFile.json && mv tmpFile.json constructors.json;
    jq '. | sort_by(.positionNumber)' constructors.json > tmpFile.json && mv tmpFile.json constructors.json;
done;

wins_data=$(jq '[.[] | select(.year==2023) | select(.positionNumber==1)]
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

cp drivers.json ../drivers.json;
cp constructors.json ../constructors.json;

(rm "$folder"*.zip) > /dev/null 2>&1;
(rm -rf "$folder"/raw) > /dev/null 2>&1;
