chalk   = require 'chalk'
async   = require 'async'
secrets = require './secrets'
fs      = require 'fs'

API_LIMIT = 2350 # self imposed to stay under quota/debug

options =
  apiKey: secrets.apiKey
  formatter: 'gpx'

geocoder = require("node-geocoder").getGeocoder("google", "https", options)

getLatLong = (inCSVFile, outCSVFile, done) ->
  unless inCSVFile? and outCSVFile? then throw new Error("Must pass an input and output csv file path!")
  unless fs.existsSync(inCSVFile) then throw new Error("No file exists at path: #{inCSVFile}")

  fs.readFile inCSVFile, 'utf8', (err, data) ->
    throw err if err?

    delimiter = '\n'
    if data.indexOf('\r\n') > -1
      delimiter = '\r\n'
      console.log "Using delimiter: \\r\\n"
    else if data.indexOf('\r') > -1
      delimiter = '\r'
      console.log "Using delimiter: \\r"
    else console.log "Using delimiter: \\n"

    lines = data.split(delimiter)

    startAtLineNo = 0
    if fs.existsSync(outCSVFile)
      existingKml = fs.readFileSync(outCSVFile, 'utf8')
      startAtLineNo = existingKml.split(delimiter).length-1
      console.log "Found existing output file: #{outCSVFile} with #{startAtLineNo} lines, resuming..."

      lines = lines[startAtLineNo...lines.length]
      console.log "Found #{chalk.cyan(lines.length)} lines remaining in csv source"

      kmlStream = fs.createWriteStream(outCSVFile, flags: 'a')
    else 
      console.log "Found #{chalk.cyan(lines.length)} lines in csv source"
      kmlStream = fs.createWriteStream(outCSVFile)

    logfile = fs.createWriteStream("geocode.log", flags: 'a')

    apiHitCount = 0

    geocodeLine = (line, next) ->
      return next(null) unless line.length > 0

      [company, address] = line.split(',')
      # console.log "Got: #{company} @ #{address}"

      geocoder.geocode address, (err, res) ->
        apiHitCount += 1

        if err
          console.error msg = "Couldn't geocode address: #{address}"
          console.error err
          logfile.write msg + "\n"
          logfile.write err + "\n"
          kmlStream.write "\n" # leave it blank
          return next()

        if m = res.match /(<wpt.*lat="(.*?)".*lon="(.*?)".*wpt\>)/
          wpt = m[1]
          lat = m[2]
          lon = m[3]
          logfile.write "#{address}, #{wpt}\n"
          kmlStream.write "#{[company, address, lat, lon].join(',')}\n"

        if apiHitCount >= API_LIMIT
          next("Exceeded our self-imposed limit of #{API_LIMIT}.")
        else
          waitTime = 250
          # console.log "Time for a #{waitTime}ms timeout."
          setTimeout(next, waitTime)

    async.eachSeries lines, geocodeLine, (err) ->
      console.error err if err
      kmlStream.end(done)

module.exports = getLatLong

if require.main is module
  args = process.argv.splice(2)
  csvFile = args[0] or "jobdata.csv"
  outCSVFile = args[1] or "jobshop.latlong.csv"
  getLatLong csvFile, outCSVFile, ->
    console.log "Done."