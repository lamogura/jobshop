chalk   = require 'chalk'
async   = require 'async'
secrets = require './secrets'
fs      = require 'fs'

options =
  apiKey: secrets.apiKey
  formatter: 'gpx'
  # formatter: 'string' # 'gpx', 'string', ...
  # formatterPattern: "%n, %S, %z, %P, %p, %c, %T, %t"

geocoder = require("node-geocoder").getGeocoder("google", "https", options)

parseLatLon = (gpx) ->
  # FIXME
  return [null, null]

jobshop = (csvFile, kmlFile, batchSize=100) ->
  unless csvFile? and kmlFile? then throw new Error("Must pass csv and kml file path!")
  unless fs.existsSync(csvFile) then throw new Error("No file exists at path: #{csvFile}")

  addresses = parseFile(csvFile)
  batches = Math.ceil(addresses.length / batchSize)

  kmlStream = fs.createWriteStream(kmlFile)

  async.each [0...batches], (i) ->
    batch = addresses[(i*batchSize)...((i+1)*batchSize)]
    geocoder.batchGeocode batch, (values) ->
      parseLanLon(val) for val in values
      # write out to kml

  # geocoder.geocode("4802 N Bend Rd, 44004")
  #   .then (res) ->
  #     console.dir res
  #   .catch (err) ->
  #     console.log "Error: #{chalk.red(err)}"

  # geocoder.batchGeocode addresses, (values) ->
  #   console.log values

module.exports = jobshop

if require.main is module
  args = process.argv.splice(2)
  file = args[0] or "jobshop.csv"
  kmlfile = args[1] or "jobshop.kml"
  jobshop(file, kmlfile, 1)