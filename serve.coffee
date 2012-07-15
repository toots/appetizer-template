app = require("./src/app.coffee")
  vendorify: ["jquery"]

app.get "*", (req, res) ->
  res.render "index.eco"
