_              = require "underscore"
eco            = require "eco"
express        = require "express"
vendorify      = require "vendorify"

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

module.exports = (options = {}) ->
  app = express.createServer()

  app.configure "production", ->
    process.addListener "uncaughtException", (err) ->
      console.error "Uncaught exception: #{err}"

  port = parseInt process.env.PORT or 8000

  vendorify.status options.vendorify, (results) ->
    changed = _.compact _.map results, (result) ->
      return result.name if _.any result.files, (file) -> file.changed

    cb = _.after _.size(changed), ->
      app.listen port, ->
        console.log "Listening on port " + app.address().port + "."

    vendorify.pull changed, (name) ->
      console.log "Installed #{name}"
      cb()

  app.use resolveProxy if options.resolveProxy?

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

  app
