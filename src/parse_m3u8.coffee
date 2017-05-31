# parse_m3u8.coffee, m3u8_dl-js/src/

log = require './log'


_split_lines = (raw_text) ->
  lines = raw_text.split '\n'
  o = []
  for l in lines
    l = l.trim()
    if l != ''
      o.push l
  o

_parse_key = (raw_line) ->
  # support key line: `#EXT-X-KEY:METHOD=AES-128,URI="http://XXXX.key"`

  # TODO support more format parse
  o = {}
  rest = raw_line
  M = 'METHOD='
  if rest.startsWith M
    rest = rest[M.length ..]
    i = rest.indexOf(',')
    if i is -1
      o.method = rest
    else
      o.method = rest[0...i]
      rest = rest[(i + 1)..]

      U = 'URI='
      if rest.startsWith U
        rest = rest[U.length ..]
        if rest.startsWith '"'
          o.uri = rest[1..]
          if o.uri.endsWith '"'
            o.uri = o.uri[0... o.uri.length - 1]
        else
          o.uri = rest
      # TODO maybe more process
  # else: TODO unknow format
  o


parse_m3u8 = (raw_m3u8_text) ->
  M3U  = '#EXTM3U'
  V    = '#EXT-X-VERSION:'
  MS   = '#EXT-X-MEDIA-SEQUENCE:'
  TD   = '#EXT-X-TARGETDURATION:'
  K    = '#EXT-X-KEY:'
  INFO = '#EXTINF:'
  END  = '#EXT-X-ENDLIST'

  line = _split_lines raw_m3u8_text
  # check format
  if line[0] != M3U
    log.w "parse_m3u8: file format is not `#EXTM3U` "

  media_sequence = 0
  clip_s = -1  # clip time_s
  o = {
    clip: []
  }
  for l in line
    if l.startsWith '#'
      if l.startsWith INFO
        clip_s = Number.parseInt l[INFO.length ..]
      if l.startsWith V
        o.version = l[V.length ..]
      else if l.startsWith MS
        media_sequence = Number.parseInt l[MS.length ..]
      else if l.startsWith TD
        o.target_duration = l[TD.length ..]
      else if l.startsWith K
        o.key = _parse_key l[K.length ..]
      else if l is END
        return o  # got file end
      # else: ignore this line
    else
      # is a clip file line
      o.clip.push {
        media_sequence
        url: l
        time_s: clip_s
      }
      clip_s = -1  # reset clip time_s
      media_sequence += 1
  # no `#EXT-X-ENDLIST`
  log.w "parse_m3u8: not found m3u8 end `#EXT-X-ENDLIST` "
  o

module.exports = parse_m3u8
