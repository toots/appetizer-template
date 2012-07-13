#= require jquery

$ ->
  fn = ->
    $("#main").text "Hello world!"
    $("html").removeClass "loading"

  setTimeout fn, 3000
