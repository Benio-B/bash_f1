#!/bin/bash

year_GP="${1:-2024}";

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