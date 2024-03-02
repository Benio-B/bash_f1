# Formula 1 Data Dashboard for Home Assistant

> No data is provided by this repository.

## Introduction

This repository contains a script to fetch Formula 1 data using wget from https://github.com/f1db/f1db, format the data into JSON.
The goal is to display it in a dashboard using Home Assistant with creating sensor to recovery it.

## Data
The script tries to download last data provided by [f1db](https://github.com/f1db/f1db) at each run.
It creates 2 files with some data like id, name, abbreviation, number seasons points, number seasons wins, total points, etc. (for more details, see below):
- drivers.json
- constructors.json
These files are added at /share/f1/.

## Getting Started

### Prerequisites

- Home Assistant installed and running.

### Run
This script used 4 libs, automatically added if necessary:
- jq
- wget
- unzip

You can set a year as first param to download data, by default it's the current season (2024).
```bash
./getF1Data.sh 2023
```
or
```bash
./getF1Data.sh
```

### Installation

1. Clone this repository in home assistant /config/shell:

   ```bash
   git clone https://github.com/Benio-B/bash_f1
   cd bash_f1
   ```

2. Create a shell_command in `configuration.yml`
    ```yml
    shell_command:
      update_f1_data: bash /config/shell/bash_f1/getF1Data.sh {{ year }}
   ```

3. Create automation to get fresh data every day
    ```yml
    alias: Update F1 data every nights
    description: ""
    trigger:
    - platform: time
      at: "02:00:00"
      condition: []
      action:
      - service: shell_command.update_f1_data
        data:
        year: 2023
        mode: single
    ```

4. Create sensors to use data in lovelace. Rest sensor is used to retrieve all json, fetch twice a day
    ```yml
    rest:
      - scan_interval: 43200
        resource_template: http://{YOUR_HOMEASSISTANT_IP}:8123/local/formula1/drivers.json
        sensor:
          - name: "Rest Drivers"
            value_template: "OK"
            json_attributes_path: "$.data"
            json_attributes:
              - "drivers"
      - scan_interval: 43200
        resource_template: http://{YOUR_HOMEASSISTANT_IP}:8123/local/formula1/constructors.json
        sensor:
          - name: "Rest Constructors"
            value_template: "OK"
            json_attributes_path: "$.data"
            json_attributes:
              - "constructors"
    ```

## Data
### drivers.json
> ```json 
> { 
>   "id": "sergio-perez",
>   "name": "Sergio Pérez",
>   "firstName": "Sergio",
>   "lastName": "Pérez",
>   "fullName": "Sergio Pérez Mendoza",
>   "abbreviation": "PER",
>   "permanentNumber": "11",
>   "gender": "MALE",
>   "dateOfBirth": "1990-01-26",
>   "dateOfDeath": null,
>   "placeOfBirth": "Guadalajara",
>   "countryOfBirthCountryId": "mexico",
>   "nationalityCountryId": "mexico",
>   "secondNationalityCountryId": null,
>   "bestChampionshipPosition": 2,
>   "bestStartingGridPosition": 1,
>   "bestRaceResult": 1,
>   "totalChampionshipWins": 0,
>   "totalRaceEntries": 259,
>   "totalRaceStarts": 257,
>   "totalRaceWins": 6,
>   "totalRaceLaps": 14225,
>   "totalPodiums": 35,
>   "totalPoints": 1486,
>   "totalChampionshipPoints": 1486,
>   "totalPolePositions": 3,
>   "totalFastestLaps": 11,
>   "totalDriverOfTheDay": 14,
>   "totalGrandSlams": 0,
>   "year": 2023,
>   "positionDisplayOrder": 2,
>   "positionNumber": 2,
>   "positionText": "2",
>   "driverId": "sergio-perez",
>   "points": 285,
>   "wins": 2
> }
> ```

### constructors.json
> ```json
> {
>   "id": "ferrari",
>   "name": "Ferrari",
>   "fullName": "Scuderia Ferrari",
>   "countryId": "italy",
>   "bestChampionshipPosition": 1,
>   "bestStartingGridPosition": 1,
>   "bestRaceResult": 1,
>   "totalChampionshipWins": 16,
>   "totalRaceEntries": 1076,
>   "totalRaceStarts": 1074,
>   "totalRaceWins": 243,
>   "total1And2Finishes": 85,
>   "totalRaceLaps": 121180,
>   "totalPodiums": 807,
>   "totalPodiumRaces": 615,
>   "totalChampionshipPoints": 9625.0,
>   "totalPolePositions": 249,
>   "totalFastestLaps": 261,
>   "year": 2023,
>   "positionDisplayOrder": 3,
>   "positionNumber": 3,
>   "positionText": "3",
>   "constructorId": "ferrari",
>   "engineManufacturerId": "ferrari",
>   "points": 406,
>   "wins": 1
> }
> ```
