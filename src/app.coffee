_              = require "underscore"
eco            = require "eco"
express        = require "express"

Snockets       = require "snockets"
Snockets.compilers.eco =
  match: /\.eco$/
  compileSync: (sourcePath, source) ->
    basename = path.basename sourcePath, ".eco"
    "(function(){App.Template[\"#{basename}\"] = #{eco.precompile source}}).call(this);"

express.assets = require "connect-assets"

resolveProxy = (req, res, next) ->
  forwardedIpsStr = req.header "x-forwarded-for"
  if forwardedIpsStr?
    [ipAddress] = forwardedIpsStr.split ","
  ipAddress = req.connection.remoteAddress unless ipAddress?
  req.connection.remoteAddress = ipAddress
  next()

module.exports.app = app = express.createServer()

app.configure "production", ->
  process.addListener "uncaughtException", (err) ->
    console.error "Uncaught exception: #{err}"

port = parseInt process.env.PORT or 8000
app.listen port, ->
  console.log "Listening on port " + app.address().port + "."

app.use resolveProxy

logFormat = ":remote-addr :method :url (:status) took :response-time ms."
app.use express.logger logFormat

app.use express.cookieParser()
app.use express.session
  secret: process.env.APP_SESSION_SECRET || "skjghskdjfhbqigohqdiouk"

app.use express.static "public"

options =
  src      : ["vendor", "app"]
  buildDir : "tmp"

if process.env.NODE_ENV != "production"
  options = _.extend options,
    build          : false
    buildFilenamer : (file) -> file

app.use express.assets options

app.set "views",       "app/views"
app.set "view engine", "eco"
