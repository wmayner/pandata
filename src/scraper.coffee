# External dependencies
whenjs = require 'when'
unfoldList = require 'when/unfold/list'
cheerio = require 'cheerio'

# Internal dependencies
DATA_FEED_URLS = require './data_urls'
Parser = require './parser'
Downloader = require './downloader'

# # Pandata #

# This is the main class of the module, which exposes the API. Use
# like so:
#
#     Pandata = require 'pandata'
#     Pandata.get 'john@example.com', (err, webname) ->
#       scraper = new Pandata webname
#

module.exports = class Pandata
  constructor: (@webname) ->
    @parser = new Parser

  # ### get ###
  # Get a Pandora webname by searching for a string (such as an
  # email address), and execute a callback on it.
  #
  # The callback must have the signature `(error, webname)`.
  @get: (user_id, callback) ->
    search_url = DATA_FEED_URLS.user_search.replace('%{searchString}', user_id)
    Downloader.read_page search_url, (data) ->
      $ = cheerio.load data
      webnames = Parser.get_webnames_from_search($)

      if user_id in webnames
        callback null, user_id
      else if webnames.length is 1 and /.*@.*\..*/.test user_id
        callback null, webnames[0]
      else if webnames? and webnames[0] isnt undefined
        callback null, webnames[0]
      else
        callback Error("""[Pandata] Couldn't find a Pandora user with that
          email or webname."""), null

  # ## API ##

  # ### recent_activity ###
  # Get a list of artists and tracks a user has listened to
  # recently.
  #
  # Returns a promise for an array of tracks and artists. A track
  # is an object with `track` and `artist` fields. An artist is
  # just a string.
  #
  #     [ {track: 'Promises', artist: 'The Range'}
  #     , 'The Range'
  #     , 'MGMT'
  #     , {track: 'Kids', artist: 'MGMT'}
  #     ]
  recent_activity: ->
    @_scrape_for('recent_activity', 'get_recent_activity')

  # ### playing_station ###
  # Get the user's currently playing station. Get the station a
  # user is currently playing (this means the one that is
  # currently selected for playback in Pandora; the user may not
  # actually be on pandora.com listening to it.)
  #
  # Returns a promise for the name of the currently playing
  # station as a string:
  #
  #     'The Range Radio'
  playing_station: ->
    @_scrape_for('playing_station', 'get_playing_station')
      .then (result) -> return result[0]

  # ### stations ###
  # Get the stations a user has listened to or created.
  #
  # Returns a promise for an array of station names:
  #
  #     ['The Range Radio', 'MGMT Radio']
  stations: ->
    @_scrape_for('stations', 'get_stations')

  # ### bookmarks ###
  # Get tracks and artists a user has bookmarked.
  #
  # Returns a promise for an object of `tracks` and `artists`:
  #
  #     { tracks: [
  #         {track: 'Promises', artist: 'The Range'}
  #       , {track: 'Kids', artits: 'MGMT'}
  #       ]
  #     , artists: ['The Range', 'MGMT']
  #     }
  #
  # Also accepts an optional string argument to limit the
  # result to a particular category, either `'tracks'`,
  # `'artists'`, `'stations'`, or `'albums'`.
  #
  # For example, `scraper.bookmarks('tracks')` returns a
  # promise for an array of tracks:
  #
  #     [ {track: 'Promises', artist: 'The Range'}
  #     , {track: 'Kids', artist: 'MGMT'}
  #     ]
  bookmarks: (bookmark_type = 'all') ->
    switch bookmark_type
      when 'tracks'
        return @_scrape_for('bookmarked_tracks', 'get_bookmarked_tracks')
      when 'artists'
        return @_scrape_for('bookmarked_artists', 'get_bookmarked_artists')
      when 'all'
        # Wait for all the scraping promises to resolve before
        # combining them into the returned object
        whenjs.all([
          @bookmarks('artists')
          @bookmarks('tracks')
        ]).then(
          (results) ->
            artists: results[0]
            tracks: results[1]
          (reason) ->
            console.error reason
        )

  # ### likes ###
  # Get tracks, artists, stations, and albums a user has liked.
  #
  # Returns a promise for an object containing arrays of
  # tracks, artists, stations, and albums:
  #
  #     { tracks: [
  #         {track: 'Promises', artist: 'The Range'}
  #       , {track: 'Kids', artist: 'MGMT'}
  #       ]
  #     , artists: ['The Range', 'MGMT']
  #     , stations: ['The Range Radio', 'MGMT Radio']
  #     , albums: [
  #         {album: 'Nonfiction', artist: 'The Range' }
  #       , {album: 'Oracular Spectacular', artist: 'MGMT'}
  #       ]
  #     }
  #
  # Also accepts an optional string argument to limit the
  # result to a particular category, either `'tracks'`,
  # `'artists'`, `'stations'`, or `'albums'`.
  #
  # For example, `scraper.likes('tracks')` returns a promise for
  # an array of tracks:
  #
  #     [ {track: 'Promises', artist: 'The Range'}
  #     , {track: 'Kids', artist: 'MGMT'}
  #     ]
  likes: (like_type = 'all') ->
    switch like_type
      when 'tracks'
        @_scrape_for('liked_tracks', 'get_liked_tracks')
      when 'artists'
        @_scrape_for('liked_artists', 'get_liked_artists')
      when 'stations'
        @_scrape_for('liked_stations', 'get_liked_stations')
      when 'albums'
        @_scrape_for('liked_albums', 'get_liked_albums')
      when 'all'
        # Wait for all the scraping promises to resolve before
        # combining them into the returned object
        whenjs.all([
          @likes('artists')
          @likes('albums')
          @likes('stations')
          @likes('tracks')
        ]).then(
          (results) ->
            artists: results[0]
            albums: results[1]
            stations: results[2]
            tracks: results[3]
          (reason) ->
            console.error reason
        )

  # ### following ###
  # Get the Pandora users that follow this user.
  #
  # Returns a promise for an array of user objects:
  #
  #     [ { name: 'Will Mayner'
  #       , webname: 'wmayner'
  #       , href: '/profile/wmayner'
  #       }
  #     ]
  following: ->
    @_scrape_for('following', 'get_following')

  # ### followers ###
  # Get the Pandora users this user is following.
  #
  # Returns a promise for an array of user objects:
  #
  #     [ { name: 'Will Mayner'
  #       , webname: 'wmayner'
  #       , href: '/profile/wmayner'
  #       }
  #     ]
  followers: ->
    @_scrape_for('followers', 'get_followers')

  # ## Private methods ##

  # Downloads all data of a given type and calls the supplied
  # `Parser` method.
  #
  # Returns a promise for the array of results.
  _scrape_for: (data_type, parser_method) ->
    # This is called iteratively by `unfoldList` as long as
    # `condition` is not met
    unspool = (next_data_indices) =>
      # Must return a promise
      deferred = whenjs.defer()
      # We'll give the resolver to the `Downloader`
      resolver = deferred.resolver
      url = @_get_url data_type, next_data_indices
      Downloader.read_page url, (data) =>
        # Check if we're getting XML, use `xmlMode: true` with `cheerio` if so
        $ = cheerio.load data, (if /\.xml/.test url then {xmlMode: yes} else {})
        # Pass the parsed DOM object to the `Parser` method
        result = @parser[parser_method]($)
        next_data_indices = @parser.get_next_data_indices($)
        # `result` is added to the list, `next_data_indices` is passed to the
        # next `condition` and `unspool` calls
        return resolver.resolve([result, next_data_indices])
      return deferred.promise

    # The condition upon which `unfoldList` will stop
    condition = (next_data_indices) =>
      return (if next_data_indices? then \
        @_is_empty next_data_indices else next_data_indices)

    # The initial seed for `unfoldList`
    initial_data_indices = null
    seed = initial_data_indices

    # `unfoldList` handles the sequential execution of an unkown number of
    # iterations of an asynchronous function, which is in this case grabbing
    # data from the Pandora feeds (they may or may not have more pages, which
    # is only known after fetching the current one), and returns a promise for
    # an array of the results.
    return unfoldList(unspool, condition, seed)
      .then(
        # Resolution
        (results) ->
          # Flatten the resulting array
          return [].concat results...
        # Rejection
        (reason) ->
          console.error reason
      )

  # Grab a URL from `DATA_FEED_URLS` and format it appropriately.
  _get_url: (data_type, next_data_indices = null) ->
    unless next_data_indices?
      next_data_indices =
        nextStartIndex: 0
        nextLikeStartIndex: 0
        nextThumbStartIndex: 0
    #! We want to set the webname parameter as well
    next_data_indices['webname'] = @webname
    #! Grab the proper URL
    url = DATA_FEED_URLS[data_type]
    #! Replace the parameters with values
    for url_string_param of next_data_indices
      url = url.replace(
        new RegExp("%{"+url_string_param+"}")
      , next_data_indices[url_string_param])
    return url

  # Utility method to check if an object is empty or not.
  _is_empty: (obj) ->
    if obj is null then return yes
    if obj.length and obj.length > 0 then return no
    if obj.length is 0 then return yes
    for key of obj
      if hasOwnProperty.call(obj, key) then return no
    return yes

