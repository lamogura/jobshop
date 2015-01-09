chalk = require 'chalk'

geocoderProvider = "google"
httpAdapter = "http"

# optional
extra =
  apiKey: "YOUR_API_KEY" # for Mapquest, OpenCage, Google Premier
  formatter: null # 'gpx', 'string', ...

geocoder = require("node-geocoder").getGeocoder(geocoderProvider, httpAdapter, extra)

# Using callback
geocoder.geocode "29 champs elysée paris", (err, res) ->
  console.log res

# Or using Promise
geocoder.geocode("29 champs elysée paris")
  .then (res) ->
    console.log res
  .catch (err) ->
    console.log err

# ## Advanced usage (only google provider)
addressInfo = 
  address: "29 champs elysée"
  country: "France"
  zipcode: "75008"

geocoder.geocode addressInfo, (err, res) ->
  console.log res

# Reverse example
# Using callback
geocoder.reverse 45.767, 4.833, (err, res) ->
  console.log res

# Or using Promise
geocoder.reverse(45.767, 4.833)
  .then((res) ->
    console.log res
  .catch (err) ->
    console.log err

# Batch geocode
addresses = [
  "13 rue sainte catherine"
  "another adress"
]
geocoder.batchGeocode addresses, (values) ->
  console.log values