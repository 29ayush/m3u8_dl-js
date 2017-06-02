# dl_with_proxy.coffee, m3u8_dl-js/src/

fs = require 'fs'
url = require 'url'
http = require 'http'
https = require 'https'

socks = require 'socks'

log = require './log'
config = require './config'


#  HTTP 200 OK
#  HTTP 301 Moved Permanently
#  HTTP 302 Found
#  HTTP 307 Temporary Redirect
#  HTTP 308 Permanent Redirect
_do_dl = (opt, filename, protocol) ->
  new Promise (resolve, reject) ->
    _on_res = (res) ->
      # TODO support http 302 Found ?
      # check res code
      if res.statusCode != 200
        reject new Error "res code `#{res.statusCode}` is not 200 !"
      # TODO process gzip compress ?
      # create write stream
      w = fs.createWriteStream filename
      res.pipe(w)
      res.on 'error', (err) ->
        reject err
      w.on 'error', (err) ->
        reject err
      w.on 'finish', () ->
        resolve()
    # make http/https request
    switch protocol
      when 'http:'
        req = http.request opt, _on_res
      when 'https:'
        opt.rejectUnauthorized = false
        req = https.request opt, _on_res
      else
        throw new Error "unknow protocol `#{protocol}`"
    # FIXME support https-proxy ?
    req.on 'error', (err) ->
      reject err
    req.on 'aborted', (err) ->
      if err?
        reject err
      else
        reject new Error "aborted"
    # DO start request
    req.end()


# do a simple http GET download a file throw the proxy config
dl_with_proxy = (file_url, filename) ->
  info = url.parse file_url
  # check proxy
  # TODO FIXME support https with proxy ?
  proxy = config.proxy()
  if proxy?
    switch proxy.type
      when 'http'
        opt = {
          hostname: proxy.hostname
          port: proxy.port
          path: file_url
          headers: {
            'Host': info.hostname
          }
        }
      when 'socks5'
        # TODO move socks agent creation to ./config
        # TODO improve: not create so much socks agent
        p = {
          ipaddress: proxy.hostname
          port: proxy.port
          type: 5  # socks5
        }
        if info.protocol is 'https:'
          agent = new socks.Agent {
            proxy: p
          }, true,  # true for https server
          false
        else
          agent = new socks.Agent {
            proxy: p
          }, false,  # false for http server
          false
        opt = {
          hostname: info.hostname
          port: info.port
          path: info.path

          agent: agent  # use socks5 proxy
        }
      # else: unknow proxy type ?
  else  # no proxy
    opt = {
      hostname: info.hostname
      port: info.port
      path: info.path
    }
  # add custom headers
  ch = config.headers()
  if ch?
    if opt.headers?
      Object.assign opt.headers, ch
    else
      opt.headers = ch
  await _do_dl opt, filename, info.protocol
  # FIXME close socks proxy agent when error
  # try close socks proxy socket
  if agent?
    agent.encryptedSocket.end()


module.exports = dl_with_proxy  # async
