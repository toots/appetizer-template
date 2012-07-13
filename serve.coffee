{app} = require "./src/app.coffee"

app.get "*", (req, res) ->
  res.render "index.eco"
