# config.coffee, m3u8_dl-js/src/

# m3u8_dl program version
P_VERSION = 'm3u8_dl-js version 0.1.0-1 test20170531 2341'


# local file struct
LOCK_FILE = 'm3u8_dl.lock'
META_FILE = 'm3u8_dl.meta.json'
RAW_M3U8 = 'raw.m3u8'
RAW_KEY = 'raw.key'  # the key for m3u8
LIST_FILE = 'ffmpeg_merge.list'
# clip file
CLIP_SUFFIX_DL_PART = '.ts.part'
CLIP_SUFFIX_ENCRYPTED = '.ts.encrypted'
CLIP_SUFFIX_TS = '.ts'
# TODO support not '.ts' in m3u8 ?


_etc = {}

# get / set proxy
proxy = (p) ->
  if p?
    _etc.proxy = p
  _etc.proxy

m3u8_base_url = (base) ->
  if base?
    _etc.m3u8_base_url = base
  _etc.m3u8_base_url

m3u8_key = (k) ->
  if k?
    _etc.m3u8_key = k
  _etc.m3u8_key

m3u8_iv = (iv) ->
  if iv?
    _etc._m3u8_iv = iv
  _etc._m3u8_iv


module.exports = {
  P_VERSION

  LOCK_FILE
  META_FILE
  RAW_M3U8
  RAW_KEY
  LIST_FILE

  CLIP_SUFFIX_DL_PART
  CLIP_SUFFIX_ENCRYPTED
  CLIP_SUFFIX_TS

  proxy  # get / set
  m3u8_base_url  # get /set
  m3u8_key  # get / set
  m3u8_iv  # get / set
}
