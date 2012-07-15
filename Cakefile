vendorify = require "vendorify"

task "vendorify", "Download vendored assets", ->
  vendorify.pull ["jquery"], (file) ->
    console.log "Installed #{file}"
