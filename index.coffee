chalk   = require 'chalk'
async   = require 'async'
secrets = require './secrets'
fs      = require 'fs'

DAILY_LIMIT = 2000

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

  fs.readFile csvFile, 'utf8', (err, data) ->
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
    if fs.existsSync(kmlFile)
      existingKml = fs.readFileSync(kmlFile, 'utf8')
      startAtLineNo = existingKml.split(delimiter).length
      console.log "Found existing kml file: #{kmlFile} with #{startAtLineNo} lines, resuming..."
      lines = lines[startAtLineNo...lines.length]
      console.log "Found #{chalk.cyan(lines.length)} lines remaining in csv source"
      kmlStream = fs.createWriteStream(kmlFile, flags: 'a')
    else 
      console.log "Found #{chalk.cyan(lines.length)} lines in csv source"
      kmlStream = fs.createWriteStream(kmlFile)

    logfile = fs.createWriteStream("geocode.log")

    count = 0

    geocodeLine = (line, next) ->
      [company, address] = line.split(',')
      # console.log "Got: #{company} @ #{address}"

      geocoder.geocode address, (err, res) ->
        return next(err) if err
        count += 1

        if m = res.match /(<wpt.*lat="(.*?)".*lon="(.*?)".*wpt\>)/
          wpt = m[1]
          lat = m[2]
          lon = m[3]
          logfile.write wpt + '\n'
          kmlStream.write "#{[company, address, lat, lon].join(',')}\n"
        if count < DAILY_LIMIT
          waitTime = 500
          # console.log "Time for a #{waitTime}ms timeout."
          setTimeout(next, waitTime)
        else 
          kmlStream.end ->
            console.log "Exceeded limit, closing."
            process.exit()

    async.each lines, geocodeLine, (err) ->
      console.error err

    # async.each [0...batches], (i) ->
    #   batch = addresses[(i*batchSize)...((i+1)*batchSize)]
    #   geocoder.batchGeocode batch, (values) ->
    #     parseLanLon(val) for val in values
    #     # write out to kml

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
  # file = args[0] or "jobdata.small.csv"
  file = args[0] or "jobdata.csv"
  kmlfile = args[1] or "jobshop.kml"
  jobshop(file, kmlfile, 1)