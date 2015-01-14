# jobshop
Scripts to geocode and create a kml file for jobshop customer list

Expects you to have a "secrets" folder that exports an "apiKey" for the google goecoding API use (max 2500req/day)

# getLatLong.coffee
Takes in a csv file where each line is "customer,address" and will output a csv file where each line is "customer,address,latitude,longitude,precision" where precision is either "exact" or "rough" depending on the geocoding results. 
* "geocode.log" logs the details of each query success or failure
* having multiple lat,long results is considered a "rough" result (all matches are logged to geocode.log)
* will put a blank line if there was no result
* usually will take multiple runs due to api restrictions, so it will resume and append to output file assuming the lines in output correspond to input line# (hence the blank line in output)

Use on the command line as: coffee getLatLong.coffee (inputcsv) (outputcsv)
# makeKML.coffee
Takes in that output csv from getLatLong() and generates the kml file. Using green and yellow markers for the "exact" and "rough" geocoded addresses.

Use on the command line as: coffee makeKML.coffee (inputcsv) (outputkml)
