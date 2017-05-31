# dl_one_file.coffee, m3u8_dl-js/src/

url = require 'url'
path = require 'path'
http = require 'http'

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'
decrypt = require './decrypt'


_add_zero = (raw, len) ->
  while raw.length < len
    raw = '0' + raw
  raw

_make_filename = (m3u8_info, index) ->
  len = m3u8_info.clip.length.toString().length
  base = _add_zero('' + index, len)
  # output
  {
    part: base + config.CLIP_SUFFIX_DL_PART
    encrypted: base + config.CLIP_SUFFIX_ENCRYPTED
    ts_tmp: base + config.CLIP_SUFFIX_TS + util.WRITE_REPLACE_FILE_SUFFIX
    ts: base + config.CLIP_SUFFIX_TS
  }

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

_decrypt_clip = (name, clip) ->
  new Promise (resolve, reject) ->
    iv = config.m3u8_iv()
    if ! iv?
      iv = clip.media_sequence
    c = decrypt.create_decrypt_stream(config.m3u8_key(), iv)
    r = fs.createReadStream name.encrypted
    w = fs.createWriteStream name.ts_tmp
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
  name = _make_filename m3u8_info, index
  # check already exist and skip it
  if await async_.file_exist(name.ts)
    log.d "dl_one_file: skip exist file #{name.ts}"
    return
  clip = m3u8_info.clip[index]
  # download file (support proxy)
  try
    clip_url = _check_clip_base_url name, clip.url
    # DEBUG
    log.d "dl_one_file: #{name.ts}: start download #{clip_url}"
    await util.dl_with_proxy clip_url, name.part
  catch e
    log.e "dl_one_file: #{name.ts}: download error ! "
    throw e
  # download one file done, rename it
  await async_.mv name.part, name.encrypted

  await _decrypt_clip name, clip
  # download one clip done
  await async_.mv name.ts_tmp, name.ts


module.exports = dl_one_file  # async
