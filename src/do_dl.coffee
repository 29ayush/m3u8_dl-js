# do_dl.coffee, m3u8_dl-js/src/

path = require 'path'
url = require 'url'
fs = require 'fs'

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'

parse_m3u8 = require './parse_m3u8'
dl_clip = require './dl_clip'
dl_with_proxy = require './dl_with_proxy'
thread_pool = require './thread_pool'


_create_meta_file = (m3u8, m3u8_info) ->
  _save_key = ->
    o = {}
    if config.m3u8_key()?
      o.key = config.m3u8_key().toString 'base64'
    if config.m3u8_iv()?
      o.iv = config.m3u8_iv().toString 'base64'
    o

  o = {
    p_version: config.P_VERSION
    m3u8: m3u8
    cwd: process.cwd()
    # save KEY and IV in meta file
    decrypt: _save_key()

    m3u8_info: m3u8_info
    last_update: util.last_update()
  }
  text = util.print_json o
  await util.write_file config.META_FILE, text

_make_filename = (m3u8_info) ->
  _add_zero = (raw, len) ->
    while raw.length < len
      raw = '0' + raw
    raw
  len = m3u8_info.clip.length.toString().length

  _one_filename = (index) ->
    base = _add_zero('' + index, len)
    # output
    {
      part: base + config.CLIP_SUFFIX_DL_PART
      encrypted: base + config.CLIP_SUFFIX_ENCRYPTED
      ts_tmp: base + config.CLIP_SUFFIX_TS + util.WRITE_REPLACE_FILE_SUFFIX
      ts: base + config.CLIP_SUFFIX_TS
    }
  for i in [0... m3u8_info.clip.length]
    c = m3u8_info.clip[i]
    c.name = _one_filename i
  m3u8_info

# check and process clip base url
_check_clip_base_url = (m3u8_info) ->
  _check_one_clip = (name, raw_url) ->
    _path = path.posix  # FIX url path on Windows

    o = url.parse raw_url
    if ! o.protocol?
      base = config.m3u8_base_url()
      if ! base?
        log.e "no base URL for m3u8 clip #{name.ts}"
        throw new Error "no base URL"
      base_url = url.parse base
      # merge base url
      base_url.pathname = _path.join base_url.pathname, o.pathname
      url.format base_url
    else
      raw_url
  # DEBUG
  if config.m3u8_base_url()?
    log.d "base URL #{config.m3u8_base_url()}"
  for c in m3u8_info.clip
    c.clip_url = _check_one_clip c.name, c.url
  m3u8_info

# create ffmpeg merge list
_create_list_file = (m3u8_info) ->
  o = []
  for c in m3u8_info.clip
    o.push "file \'#{c.name.ts}\'"
  text = o.join('\n') + '\n'
  # write list file
  await util.write_file config.LIST_FILE, text

_check_change_cwd = ->
  to = config.output_dir()
  if ! to?
    return
  to_path = path.resolve to
  process.chdir to
  cwd = process.cwd()
  if path.resolve(cwd) != to_path
    log.w "can not change current directory to `#{to_path}`, current directory is `#{cwd}`"
  # check lock file
  await util.create_lock_file config.LOCK_FILE

  _remove_lock = ->
    fs.unlinkSync config.LOCK_FILE
  # remove LOCK on process exit
  process.on 'exit', _remove_lock
  # FIXME other ways to exit this process
  process.on 'SIGINT', () ->
    log.d "recv SIGINT, exiting .. . "
    process.exit 0

_check_and_download_key = (m3u8_info) ->
  if config.m3u8_key()?
    # DEBUG
    log.d "use KEY #{config.m3u8_key().toString('hex')} (#{config.m3u8_key().toString('base64')})"
    return  # do not override command line
  if ! m3u8_info.key?
    return  # no encrypt key info
  # check key method
  if m3u8_info.key.method != 'AES-128'
    log.e "not support encrypt method `#{m3u8_info.key.method}`"
    return
  key_url = m3u8_info.key.uri
  log.d "download key file #{key_url}"
  await dl_with_proxy key_url, config.RAW_KEY
  # read key
  key = await async_.read_file_byte config.RAW_KEY
  config.m3u8_key key  # save to config
  # TODO support iv ?

_download_clips = (m3u8_info) ->
  # single-thread mode: just use loop
  _single_thread = ->
    # TODO more error process
    for i in [0... m3u8_info.clip.length]
      await dl_clip m3u8_info, i
  # use thread_pool
  _multi_thread = (n) ->
    _worker = (i) ->
      await dl_clip m3u8_info, i
    # create task list
    t = []
    for i in [0... m3u8_info.clip.length]
      t.push i
    pool = thread_pool n
    await pool.run t, _worker

  log.d "download #{m3u8_info.clip.length} clips "
  # check number of download thread
  thread_n = config.dl_thread()
  if (! thread_n?) || (thread_n <= 1)
    await _single_thread()
  else
    log.d "  with #{thread_n} threads "
    await _multi_thread thread_n


do_dl = (m3u8) ->
  # DEBUG
  if config.proxy()?
    log.d "use proxy #{JSON.stringify config.proxy()}"

  _set_base_url = (raw_url) ->
    _path = path.posix
    o = url.parse raw_url
    # clear values
    o.hash = null
    o.search = null
    o.query = null
    o.path = null
    o.href = null

    o.pathname = _path.dirname o.pathname
    config.m3u8_base_url url.format(o)
  # check is remote file (http) or local file
  if m3u8.startsWith('http://') || m3u8.startsWith('https://')
    # remote file
    if ! config.m3u8_base_url()?  # not override command line
      _set_base_url m3u8  # set base_url
    # change working directory now
    await _check_change_cwd()
    # download that m3u8 file
    log.d "download m3u8 file #{m3u8}"
    dl_tmp_file = config.RAW_M3U8 + util.WRITE_REPLACE_FILE_SUFFIX
    await dl_with_proxy m3u8, dl_tmp_file
    await async_.mv dl_tmp_file, config.RAW_M3U8
    # read that text
    m3u8_text = await async_.read_file config.RAW_M3U8
  else  # local file
    log.d "local m3u8 file #{path.resolve m3u8}"
    m3u8_text = await async_.read_file m3u8
    # change working directory here
    _check_change_cwd()
    # create raw m3u8 file
    await util.write_file config.RAW_M3U8, m3u8_text
  # parse m3u8 text, and create meta file
  m3u8_info = parse_m3u8 m3u8_text
  # create clip filename
  m3u8_info = _make_filename m3u8_info
  m3u8_info = _check_clip_base_url m3u8_info

  # check and download key file (before create meta file to save key)
  await _check_and_download_key m3u8_info

  await _create_meta_file m3u8, m3u8_info
  await _create_list_file m3u8_info

  await _download_clips m3u8_info
  log.d "[ OK ] all download done. "


module.exports = do_dl  # async
