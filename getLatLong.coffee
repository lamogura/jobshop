chalk        = require 'chalk'
async        = require 'async'
fs           = require 'fs'
NodeGeocoder = require 'node-geocoder'
require 'dotenv/config'

API_LIMIT = 5000 # self imposed to stay under quota/debug

options =
  provider: 'google'
  apiKey: process.env.GOOGLE_GEO_API_KEY
  httpAdapter: 'https'
  formatter: null

geocoder = NodeGeocoder(options)

getLatLong = (inCSVFile, outCSVFile, done) ->
  unless inCSVFile? and outCSVFile? then throw new Error("Must pass an input and output csv file path!")
  unless fs.existsSync(inCSVFile) then throw new Error("No file exists at path: #{inCSVFile}")

  fs.readFile inCSVFile, 'utf8', (err, data) ->
    throw err if err?cp

    delimiter = '\n'
    if data.indexOf('\r\n') > -1
      delimiter = '\r\n'
      console.log "Using delimiter: \\r\\n"
    else if data.indexOf('\r') > -1
      delimiter = '\r'
      console.log "Using delimiter: \\r"
    else console.log "Using delimiter: \\n"

    console.log "Doing max #{chalk.cyan(API_LIMIT)} geocodes."

    lines = data.split(delimiter)

    startAtLineNo = 0
    if fs.existsSync(outCSVFile)
      existingOutputCSV = fs.readFileSync(outCSVFile, 'utf8')
      startAtLineNo = existingOutputCSV.split(delimiter).length-1
      console.log "Found existing output file: #{chalk.cyan(outCSVFile)} with #{chalk.cyan(startAtLineNo)} lines, resuming..."

      lines = lines[startAtLineNo...lines.length]
      console.log "Found #{chalk.cyan(lines.length)} lines remaining in csv source"

      csvOutStream = fs.createWriteStream(outCSVFile, flags: 'a')
    else
      console.log "Found #{chalk.cyan(lines.length)} lines in csv source"
      csvOutStream = fs.createWriteStream(outCSVFile)

    logfile = fs.createWriteStream("geocode.log", flags: 'a')

    apiHitCount = 0

    geocodeLine = (line, next) ->
      return next(null) unless line.length > 0

      [company, address] = line.split(',')
      # console.log "Got: #{company} @ #{address}"

      geocoder.geocode address, (err, hits) ->
        apiHitCount += 1

        if err
          console.error msg = "Couldn't geocode address: #{address}"
          console.error err
          logfile.write msg + "\n"
          logfile.write err + "\n"
          csvOutStream.write "\n" # leave it blank
          return next()

        if hits.length > 0
          firstHit = hits[0]

          logfile.write("#{address}: ")
          logfile.write("(#{hit.latitude}, #{hit.longitude}) ") for hit in hits
          logfile.write('\n')

          precision = if (firstHit.city? and hits.length is 1) then "exact" else "rough"

          csvOutStream.write([
            company
            address
            firstHit.latitude
            firstHit.longitude
            precision
          ].join(',') + '\n')

        else
          console.log msg ="No hits for address '#{address}'"
          logfile.write msg + '\n'

        if apiHitCount >= API_LIMIT
          next("Exceeded our self-imposed limit of #{API_LIMIT}.")
        else
          waitTime = 20
          # console.log "Time for a #{waitTime}ms timeout."
          setTimeout(next, waitTime)

    async.eachSeries lines, geocodeLine, (err) ->
      console.error err if err
      csvOutStream.end(done)

module.exports = getLatLong

if require.main is module
  args = process.argv.splice(2)
  csvFile = args[0] or "jobdata.csv"
  outCSVFile = args[1] or "jobshop.latlong.csv"
  getLatLong csvFile, outCSVFile, ->
    console.log "Done."