# # Parser #

# Parses HTML/XML pages from Pandora for relevant data.
module.exports = class Parser

  # The `$` paramter in some of the functions in this file must be a
  # jQuery-like object such as the one returned by
  # `require('cheerio').load(<some html document>)`

  # Return the array of webnames from a user ID search.
  @get_webnames_from_search: ($) ->
    webnames = []
    $('.user_name a').each (index, a) -> webnames.push $(a).text()
    return webnames

  # Return the query parameters necessary to get the next page of
  # data from Pandora, or `false` if there are no more pages.
  get_next_data_indices: ($) ->
    show_more = $($('.show_more')[0])
    if show_more
      next_indices = {}
      data_attributes = [
        'nextStartIndex'
        'nextLikeStartIndex'
        'nextThumbStartIndex'
      ]
      for attr_name in data_attributes
        attr = show_more.attr('data-'+attr_name.toLowerCase())
        if attr? then next_indices[attr_name] = attr
      return next_indices
    else
      return false

  # Return an array of recent activity names.
  get_recent_activity: ($) ->
    results = []
    for item in @_xml_items($)
      item = item.title.split(" by ")
      if item.length is 2
        results.push
          track: item[0]
          artist: item[1]
      else results.push item[0]
    return results

  # Return an array of station names.
  get_stations: ($) ->
    return (item.title for item in @_xml_items($))

  # Return the currently playing station, or a placeholder
  # string if there is no currently playing station.
  get_playing_station: ($) ->
    items = @_xml_items($)
    unless items.length is 0
      return items[0].title
    else
      return 'No station is currently playing.'

  # Return an array of bookmarked tracks (objects with `track` and
  # `artist` keys).
  get_bookmarked_tracks: ($) ->
    return ({track: item.title.split(' by ')[0], \
      artist: item.title.split(' by ')[1]} for item in @_xml_items($))

  # Return array of bookmarked artist names.
  get_bookmarked_artists: ($) ->
    return (item.title for item in @_xml_items($))

  # Return an array of liked tracks (objects with `track` and `artist` keys).
  get_liked_tracks: ($) ->
    return ({track: infobox.title, artist: infobox.subtitle} \
      for infobox in @_infoboxes($))

  # Return an array of liked artists.
  get_liked_artists: ($) ->
    return @_get_infobox_titles($)

  # Return an array of liked stations.
  get_liked_stations: ($) ->
    return @_get_infobox_titles($)

  # Return an array of liked albums (objects with `album` and `artist` keys).
  get_liked_albums: ($) ->
    return ({album: infobox.title, artist: infobox.subtitle} \
      for infobox in @_infoboxes($))

  # Return an array of Pandora users this user follows (objects with `name`,
  # `webname`, and `href keys`).
  get_following: ($) ->
    return @_get_followx_users($)

  # Return an array of Pandora users following this user (objects with `name`,
  # `webname`, and `href keys`).
  get_followers: ($) ->
    return @_get_followx_users($)


  # ### Private methods ###

  # Take the parsed XML feed returned by `xml2js`.
  # Return the title and description of each `item` in the feed.
  _xml_items: ($) ->
    result = []
    $('item').each (index, item) ->
      item = $(item)
      title = item.find('title').first().text()
      description = item.find('description').first().text()
      result.push
        title: title
        description: description
    return result

  # Return the title and description of each `infobox` on the page.
  _infoboxes: ($) ->
    infoboxes = []
    $('.infobox').each (index, infobox) ->
      infobox = $(infobox)
      infobox_body = infobox.find('.infobox-body')

      title_link = infobox_body.find('h3 a').text()
      subtitle_link = infobox_body.find('p a').first()
      if subtitle_link then subtitle_link = subtitle_link.text()

      infoboxes.push
        title: title_link
        subtitle: subtitle_link

    return infoboxes

  # Return an array of titles from infoboxes.
  _get_infobox_titles: ($) ->
    return (infobox.title for infobox in @_infoboxes($))

  # Return the users found in a follower/following search, in the format
  # `{name: <name>, webname: <webname>, href: <href>}`
  _get_followx_users: ($) ->
    users = []
    $('.follow_section').each (index, section) ->
      section = $(section)
      listener_name = section.find('.listener_name').first()
      webname = listener_name.attr('webname')

      # Remove any 'spans with a space' that sometimes appear with special
      # characters.
      listener_name.remove('span')
      # Strip tabs that sometimes appear
      name = listener_name.text().replace(/\t/, '')

      href = section.find('a').first().attr('href')

      users.push
        name: name
        webname: webname
        href: href

    return users

