# do_dl.coffee, m3u8_dl-js/src/

path = require 'path'

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'
parse_m3u8 = require './parse_m3u8'
dl_one_file = require './dl_one_file'
thread_pool = require './thread_pool'


_create_meta_file = (m3u8, m3u8_info) ->
  o = {
    p_version: config.P_VERSION
    m3u8: m3u8
    cwd: process.cwd()
    m3u8_info: m3u8_info
    last_update: util.last_update()
  }
  text = util.print_json o
  await util.write_file config.META_FILE, text

# create ffmpeg merge list
_create_list_file = (m3u8_info) ->
  # TODO

_check_change_cwd = ->
  to = config.output_dir()
  if ! to?
    return
  process.chdir to
  cwd = process.cwd()
  if path.resolve(cwd) != path.resolve(to)
    log.w "can not change current directory to `#{to}`, current directory is `#{cwd}`"
  # check lock file
  util.create_lock_file config.LOCK_FILE
  # TODO remove LOCK on process exit

_check_and_download_key = (m3u8_info) ->
  if config.m3u8_key()?
    return  # do not override command line
  if ! m3u8_info.key?
    return  # no encrypt key info
  # check key method
  if m3u8_info.key.method != 'AES-128'
    log.e "not support encrypt method `#{m3u8_info.key.method}`"
    return
  key_url = m3u8_info.key.uri
  log.d "download key file #{key_url}"
  await util.dl_with_proxy key_url, config.RAW_KEY
  # read key
  key = await async_.read_file_byte config.RAW_KEY
  config.m3u8_key key  # save to config

_download_clips = (m3u8_info) ->
  worker = (item) ->
    # TODO
  # TODO download with multi-thread ?
  # FIXME no just use loop
  log.d "start download #{m3u8_info.clip.length} clips "
  # TODO more error process
  for i in [0... m3u8_info.clip.length]
    dl_one_file m3u8_info, i


do_dl = (m3u8) ->
  # check is remote file (http) or local file
  # TODO support https:// ?
  if m3u8.startsWith 'http://'
    # remote file
    if ! config.m3u8_base_url()?  # not override command line
      config.m3u8_base_url m3u8  # set base_url
    # change working directory now
    _check_change_cwd()
    # download that m3u8 file
    log.d "download m3u8 file #{m3u8}"
    dl_tmp_file = config.RAW_M3U8 + util.WRITE_REPLACE_FILE_SUFFIX
    await util.dl_with_proxy m3u8, dl_tmp_file
    await async_.mv dl_tmp_file, config.RAW_M3U8
    # read that text
    m3u8_text = await async_.read_file config.RAW_M3U8
  else  # local file
    log.d "local m3u8 file: #{path.resolve m3u8}"
    m3u8_text = await async_.read_file m3u8
    # change working directory here
    _check_change_cwd()
    # create raw m3u8 file
    await util.write_file config.RAW_M3U8, m3u8_text
  # parse m3u8 text, and create meta file
  m3u8_info = parse_m3u8 m3u8_text
  await _create_meta_file m3u8, m3u8_info
  await _create_list_file m3u8_info

  # check and download key file
  await _check_and_download_key m3u8_info

  await _download_clips m3u8_info
  # FIXME
  log.d "[ OK ] all download done. "


module.exports = do_dl  # async
