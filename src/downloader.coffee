URI = require 'URIjs'
request = require 'request'

# # Downloader #

# Retrieves data from Pandora.com and handles network errors.
module.exports = class Downloader

  # A GitHub Gist that contains an updated cookie allowing access to
  # 'login-only' visible data.
  CONFIG_URL = """
    https://gist.github.com/ustasb/596f1ee96d03463fde77/raw/pandata_config.json
    """

  # The cached cookie.
  @cookie: null

  # Downloads and reads a page from a URL, then executes a callback on the
  # data.
  @read_page: (url, callback) =>
    @get_cookie =>
      @download url, @cookie, (data) =>
        return callback(data)

  # Downloads a page, handles errors, and executes a callback on the data.
  @download: (url, cookie, callback) =>
    jar = request.jar()
    jar.add(request.cookie(cookie))

    # Normalize URL
    url = new URI(url).normalize().toString()

    request {uri: url, jar: jar}, (error, response, body) ->
      if error
        console.log """The network request for:\n  #{url}\n
          returned an error:\n  #{error.message}"
          Please try again later or update Pandata.
          Sorry about that!\n\nFull error:"""
        console.log error.stack
      else
        callback(body)

  # Sets `@cookie` to the cached cookie, or retrieves it if it's not already
  # there, and executes the callback
  @get_cookie: (callback) =>
    unless @cookie?
      @download_cookie (cookie) =>
        @cookie = cookie
        return callback()
    else return callback()

  # Fetches an up-to-date cookie based on the `CONFIG_URL` and
  # executes the callback on the parsed response
  @download_cookie: (callback) =>
    @download CONFIG_URL, '', (body) =>
      callback(JSON.parse(body).cookie)

