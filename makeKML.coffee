chalk      = require 'chalk'
async      = require 'async'
fs         = require 'fs'
Handlebars = require 'handlebars'

kmlHeader = """
<?xml version='1.0' encoding='UTF-8'?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Style id="sn_open-diamond">
      <IconStyle>
        <color>ff00ff00</color>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/open-diamond.png</href>
        </Icon>
      </IconStyle>
    </Style>
"""

kmlNode = """\n
    <Placemark>
      <name>{{company}}</name>
      <description>{{address}}</description>
      <styleUrl>#sn_open-diamond</styleUrl>
      <Point>
        <coordinates>{{long}},{{lat}},0</coordinates>
      </Point>
    </Placemark>
"""

kmlNodeTemplate = Handlebars.compile(kmlNode)

kmlFooter = """\n
  </Document>
</kml>
"""

makeKML = (csvFile, kmlFile, done) ->
  unless csvFile? and kmlFile? then throw new Error("Must pass an input csv and output kml file path!")
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
    lineCount = lines.length
    console.log "Found #{lineCount} entries."

    kmlStream = fs.createWriteStream(kmlFile)
    
    idx = lineCount

    
    kmlStream.write(kmlHeader, 'utf8')

    writeFinished = -> kmlStream.write(kmlFooter, 'utf8', done)

    do writeKMLNodes = ->
      isOK = true
      while isOK and idx > 0
        idx -= 1
        line = lines[idx]
        continue unless line.length > 0
        
        [company, address, lat, long] = line.split(',')
        continue unless lat? and long?

        outputLine = kmlNodeTemplate({company: company, address: address, lat: lat, long: long})
        if idx is 0 # last one
          kmlStream.write(outputLine, 'utf8', writeFinished)
        else
          isOK = kmlStream.write(outputLine, 'utf8')

      if idx > 0
        kmlStream.once('drain', writeKMLNodes)

module.exports = makeKML

if require.main is module
  args = process.argv.splice(2)
  csvFile = args[0] or "jobshop.latlong.csv"
  kmlFile = args[1] or "jobshop.kml"
  makeKML csvFile, kmlFile, ->
    console.log "Done."