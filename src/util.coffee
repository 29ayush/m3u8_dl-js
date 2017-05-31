# util.coffee, m3u8_dl-js/src/

url = require 'url'

async_ = require './async'
log = require './log'
config = require './config'


last_update = ->
  new Date().toISOString()

# pretty-print JSON text
print_json = (data) ->
  JSON.stringify data, '', '    '


WRITE_REPLACE_FILE_SUFFIX = '.tmp'
# atomic write-replace for a file
write_file = (file_path, text) ->
  tmp_file = file_path + WRITE_REPLACE_FILE_SUFFIX
  await async_.write_file tmp_file, text
  await async_.mv tmp_file, file_path

create_lock_file = (file_path) ->
  try
    fd = await async_.fs_open file_path, 'wx'
    # FIXME TODO remove LOCK file on process exit
    return fd
  catch e
    log.e "can not create LOCK file #{file_path} "
    throw e


# do a simple http GET download a file throw the proxy config
# TODO support more options ? (like user-agent, referer ? )
dl_with_proxy = (file_url, filename) ->
  new Promise (resolve, reject) ->
    info = url.parse file_url
    # check proxy
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
          # TODO support socks proxy
          opt = {
            # TODO
          }
        # else: TODO
    else  # no proxy
      opt = {
        hostname: info.hostname
        port: info.port
        path: info.path
      }
    # make http request
    req = http.request opt
    req.on 'error', (err) ->
      reject err
    req.on 'response', (res) ->
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


module.exports = {
  last_update
  print_json

  WRITE_REPLACE_FILE_SUFFIX
  write_file  # async

  create_lock_file  # async

  dl_with_proxy  # async
}
