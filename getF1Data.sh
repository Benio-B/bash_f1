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

/bin/bash ../calculateDrivers.sh $year_GP;
/bin/bash ../calculateConstructors.sh $year_GP;
/bin/bash ../calculateWinners.sh $year_GP;
/bin/bash ../calculateNextRace.sh $year_GP;

# Add version on files
jq --argjson year "$year_GP" --arg version "$current_version" '{ "year": $year, "version": $version, "data": {"drivers": .}}' drivers.json > tmpFile.json && mv tmpFile.json drivers.json;
jq --argjson year "$year_GP" --arg version "$current_version" '{ "year": $year, "version": $version, "data": {"constructors": .}}' constructors.json > tmpFile.json && mv tmpFile.json constructors.json;
jq --argjson year "$year_GP" --arg version "$current_version" '{ "year": $year, "version": $version, "data": {"grandPrix": .}}' nextGP.json > tmpFile.json && mv tmpFile.json nextGP.json;


# Clean files
mv drivers.json ../drivers.json;
mv constructors.json ../constructors.json;
mv nextGP.json ../nextGP.json;

cd ..;

(rm -rf ./raw) > /dev/null 2>&1;
