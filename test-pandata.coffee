Pandata = require '../pandata'

Pandata.get 'wmayner', (err, webname) ->
  if err? then return console.error err

  pandata = new Pandata(webname)
  console.log 'WEBNAME:'
  console.log webname

  # ### End to end (semi-manual) tests ###

  # Working
  pandata.recent_activity()
    .then(
      (r) ->
        console.log "################"
        console.log "RECENT ACTIVITY:"
        console.log "################"
        console.log r
      (reason) ->
        console.error reason
    )

  # Working
  pandata.playing_station()
    .then(
      (r) ->
        console.log "################"
        console.log "PLAYING_STATION:"
        console.log "################"
        console.log r
      (reason) ->
        console.error reason
    )

  # Working
  pandata.stations()
    .then(
      (r) ->
        console.log "################"
        console.log "STATIONS:"
        console.log "################"
        console.log r
      (reason) ->
        console.error reason
    )

  # Working
  pandata.bookmarks()
    .then(
      (r) ->
        console.log "################"
        console.log "BOOKMARKS:"
        console.log "################"
        console.log r
      (reason) ->
        console.error reason
    )

  # Working
  pandata.likes()
    .then(
      (r) ->
        console.log "################"
        console.log "LIKES:"
        console.log "################"
        console.log r
      (reason) ->
        console.error reason
    )

  # Working
  pandata.following()
    .then(
      (r) ->
        console.log "################"
        console.log "FOLLOWING:"
        console.log "################"
        console.log r
      (reason) ->
        console.error reason
    )

  # Working
  pandata.followers()
    .then(
      (r) ->
        console.log "################"
        console.log "FOLLOWERS:"
        console.log "################"
        console.log r
      (reason) ->
        console.error reason
    )

