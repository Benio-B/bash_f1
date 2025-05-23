#!/bin/bash

year_GP="${1:-2025}";

nextGP=$(jq --arg current_date "$(date +%F)"  '[.[] | select(.date >= $current_date)] | .[0]' f1db-races.json)
nextGPShortName=$(jq -r --argjson nextGP "$nextGP" '$nextGP.grandPrixId as $id | .[] | select(.id==$id) | .shortName' f1db-grands-prix.json)
nextGPCircuit=$(jq --argjson nextGP "$nextGP" '$nextGP.circuitId as $id | .[] | select(.id==$id)' f1db-circuits.json)
nextGPCountry=$(jq -r --argjson nextGPCircuit "$nextGPCircuit" '$nextGPCircuit.countryId as $id | .[] | select(.id==$id) | .name' f1db-countries.json)
nextGPAlphaCode=$(jq -r --argjson nextGPCircuit "$nextGPCircuit" '$nextGPCircuit.countryId as $id | .[] | select(.id==$id) | .alpha2Code' f1db-countries.json)
nextGPCity=$(jq -r --argjson nextGP "$nextGP" '$nextGP.circuitId as $id | .[] | select(.id==$id) | .placeName' f1db-circuits.json)
nextGPFlagUrl="https://flagcdn.com/w320/${nextGPAlphaCode,,}.png"
nextGPFlagV2Url="https://flagsapi.com/${nextGPAlphaCode}/shiny/64.png"

flagEmoji=""
for (( i=0; i<${#nextGPAlphaCode}; i++ )); do
  char="${nextGPAlphaCode:$i:1}"
  flagEmoji+="$(echo -e "\U$(printf "%04x" $((127397 + $(printf "%d" "'$char"))))")"
done

jq -n "$nextGP" | jq\
  --argjson nextGP "$nextGP" \
  --arg nextGPShortName "$nextGPShortName" \
  --argjson nextGPCircuit "$nextGPCircuit" \
  --arg nextGPCountry "$nextGPCountry" \
  --arg nextGPAlphaCode "$nextGPAlphaCode" \
  --arg nextGPFlagUrl "$nextGPFlagUrl" \
  --arg nextGPFlagV2Url "$nextGPFlagV2Url" \
  --arg flagEmoji "$flagEmoji" \
  --arg nextGPCity "$nextGPCity" \
  '{ "name": $nextGPShortName, "country": $nextGPCountry, "flagEmoji": $flagEmoji, "alphaCode": $nextGPAlphaCode, "iconUrl": $nextGPFlagUrl, "iconV2Url": $nextGPFlagV2Url, "city": $nextGPCity, "round": .round, "type": .circuitType, date, time, qualifyingDate, qualifyingTime, sprintRaceDate, sprintRaceTime, laps, courseLength, distance, "latitude": $nextGPCircuit.latitude, "longitude": $nextGPCircuit.longitude, "circuitName": $nextGPCircuit.fullName }' > nextGP.json

# Fastest Lap
allRacesFromGP=$(jq -r --argjson nextGP "$nextGP" '$nextGP.circuitId as $id | $nextGP.laps as $laps | $nextGP.distance as $distance | [.[] | select(.circuitId==$id and .laps==$laps and .distance==$distance)]' f1db-races.json);
echo "[]" > fastest_lap.json;
echo $allRacesFromGP | jq -c '.[]' | while read -r race; do
    raceToAdd=$(jq --argjson race "$race" '[.[] | select(.gap==null and .year==$race.year and .round==$race.round)]' f1db-races-fastest-laps.json);
    jq --argjson raceToAdd "$raceToAdd" '. += $raceToAdd' fastest_lap.json > tmpFile.json && mv tmpFile.json fastest_lap.json
done;

fastestLap=$(jq '([ .[].timeMillis ] | min) as $m | map(select(.timeMillis== $m) | { driverId, constructorId, time, year } )' fastest_lap.json);

driver=$(jq --argjson fastestLap "$fastestLap" '.[] | select(.id==$fastestLap[0].driverId) | { "driverName": .name, "driverAbbreviation" : .abbreviation}' f1db-drivers.json);
constructor=$(jq --argjson fastestLap "$fastestLap" '.[] | select(.id==$fastestLap[0].constructorId) | { "constructorName": .name }' f1db-constructors.json);

jq \
  --argjson fastestLap "$fastestLap" \
  --argjson driver "$driver" \
  --argjson constructor "$constructor" \
  '.fastestLap = $fastestLap[0] | .fastestLap += $driver | .fastestLap += $constructor' \
  nextGP.json > tmpFile.json && mv tmpFile.json nextGP.json;

# Calculate img GP
circuitId=$(jq -n "$nextGP" | jq -r '.grandPrixId');

word_with_spaces=$(echo "${circuitId}" | sed 's/-/ /g')
capitalized_word=$(echo "$word_with_spaces" | awk '{for(j=1;j<=NF;j++) $j=toupper(substr($j,1,1)) substr($j,2)}1')
circuitName=$(echo "$capitalized_word" | tr ' ' '_')

grandPrixIdsWithEquivalentF1=(
    "monaco,Monoco"
    "azerbaijan,Baku"
    "united-states,USA"
)

for exception in "${grandPrixIdsWithEquivalentF1[@]}"; do
    circuitIdException=$(echo "$exception" | cut -d',' -f1)
    name=$(echo "$exception" | cut -d',' -f2)
    if [ "$circuitIdException" == "$circuitId" ]; then
        circuitName=$name
        break
    fi
done

circuitUrl="https://media.formula1.com/image/upload/f_auto/q_auto/v1677244985/content/dam/fom-website/2018-redesign-assets/Circuit%20maps%2016x9/${circuitName}_Circuit.png.transform/7col-retina/image.png"
jq --arg circuitUrl "$circuitUrl" '.circuitUrl = $circuitUrl' nextGP.json > tmpFile.json && mv tmpFile.json nextGP.json;
