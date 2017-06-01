# dl_one_file.coffee, m3u8_dl-js/src/

url = require 'url'
path = require 'path'
http = require 'http'

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'
decrypt = require './decrypt'


# TODO move this in ./do_dl ?
_check_clip_base_url = (name, clip_url) ->
  o = url.parse clip_url
  if ! o.protocol?
    base = config.m3u8_base_url()
    if ! base?
      log.e "dl_one_file: #{name.ts}: no base URL "
      throw new Error "no base URL"
    base_url = url.parse base
    # merge base url
    o.pathname = path.join path.dirname(base_url.pathname), o.pathname
  # FIXME maybe error ?
  url.format o

_decrypt_clip = (clip) ->
  new Promise (resolve, reject) ->
    iv = config.m3u8_iv()
    if ! iv?
      iv = clip.media_sequence
    c = decrypt.create_decrypt_stream(config.m3u8_key(), iv)
    r = fs.createReadStream clip.name.encrypted
    w = fs.createWriteStream clip.name.ts_tmp
    r.pipe(c).pipe(w)
    r.on 'error', (err) ->
      reject err
    c.on 'error', (err) ->
      reject err
    w.on 'error', (err) ->
      reject err
    w.on 'finish', () ->
      resolve()


dl_one_file = (m3u8_info, index) ->
  clip = m3u8_info.clip[index]
  # check already exist and skip it
  if await async_.file_exist(clip.name.ts)
    log.d "dl_one_file: skip exist file #{clip.name.ts}"
    return
  # download file (support proxy)
  try
    clip_url = _check_clip_base_url clip.name, clip.url
    # DEBUG
    log.d "dl_one_file: #{clip.name.ts}: start download #{clip_url}"
    await util.dl_with_proxy clip_url, clip.name.part
  catch e
    log.e "dl_one_file: #{clip.name.ts}: download error ! "
    throw e
  # check need decrypt clip
  if config.m3u8_key()?
    # download one file done, rename it
    await async_.mv clip.name.part, clip.name.encrypted
    await _decrypt_clip clip
    await async_.mv clip.name.ts_tmp, clip.name.ts
    # TODO remove encrypted (tmp) clip file ?
  else  # no need to decrypt
    await async_.mv clip.name.part, clip.name.ts
  # download one clip done


module.exports = dl_one_file  # async
