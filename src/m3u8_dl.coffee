# m3u8_dl.coffee, m3u8_dl-js/src/

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'
do_dl = require './do_dl'


_p_help = ->
  console.log """
  m3u8_dl-js [OPTIONS] M3U8
  Usage:
    -o, --output DIR  Download files to this Directory

        --proxy-http IP:PORT    Set http proxy
        --proxy-socks5 IP:PORT  Set socks5 proxy

        --thread NUM  Set number of download thread (default: 1)

        --m3u8-base-url URL       Set base URL of the m3u8 file
        --m3u8-key HEX            Set decrypt KEY (in HEX format)
        --m3u8-iv HEX             Set decrypt IV (in HEX format)
        --m3u8-key-base64 BASE64  Set decrypt KEY (in base64 format)
        --m3u8-iv-base64 BASE64   Set decrypt IV (in base64 format)
        --m3u8-key-file FILE      Read decrypt KEY from FILE (in binary format)
        --m3u8-iv-file FILE       Read decrypt IV from FILE (in binary format)

        --version  Show version of this program
        --help     Show this help text
  More information online <https://github.com/sceext2/m3u8_dl-js>
  """

_p_bad_command_line = ->
  log.e "bad command line, please try `--help` "

_p_arg = (args) ->
  rest = args

  _next = ->
    o = rest[0]
    rest = rest[1..]
    o
  _split_ip_port = (raw) ->
    p = raw.split ':'
    o = {
      hostname: p[0]
      port: Number.parseInt p[1]
    }

  o = {}
  while rest.length > 0
    one = _next()
    switch one
      when '--help', '--version'
        o.type = one
      when '-o', '--output'
        config.output_dir _next()
      when '--proxy-http'
        p = _split_ip_port _next()
        p.type = 'http'
        config.proxy p
      when '--proxy-socks5'
        p = _split_ip_port _next()
        p.type = 'socks5'
        config.proxy p
      when '--thread'
        t = Number.parseInt _next()
        config.dl_thread t
        if t < 1
          throw new Error "bad thread num #{t}"
      when '--m3u8-base-url'
        config.m3u8_base_url _next()
      when '--m3u8-key'
        config.m3u8_key Buffer.from(_next(), 'hex')
      when '--m3u8-iv'
        config.m3u8_iv Buffer.from(_next(), 'hex')
      when '--m3u8-key-base64'
        config.m3u8_key Buffer.from(_next(), 'base64')
      when '--m3u8-iv-base64'
        config.m3u8_iv Buffer.from(_next(), 'base64')
      when '--m3u8-key-file'
        o.m3u8_key_file = _next()
      when '--m3u8-iv-file'
        o.m3u8_iv_file = _next()
      else  # default: m3u8
        # warning before set
        if o.m3u8?
          log.w "set M3U8 to #{one}"
        o.m3u8 = one
  if (! o.type?) && (! o.m3u8?)
    throw new Error "empty command line"
  o

_normal = (a) ->
  # check load m3u8 key_file and iv_file
  if a.m3u8_key_file
    log.d "load KEY file #{a.m3u8_key_file}"
    config.m3u8_key await async_.read_file_byte(a.m3u8_key_file)
  if a.m3u8_iv_file
    log.d "load IV file #{a.m3u8_iv_file}"
    config.m3u8_iv await async_.read_file_byte(a.m3u8_iv_file)

  await do_dl a.m3u8

main = (argv) ->
  try
    a = _p_arg argv
  catch e
    _p_bad_command_line()
    process.exit 1  # bad command line
  switch a.type
    when '--help'
      _p_help()
    when '--version'
      # print version
      console.log config.P_VERSION
    else
      await _normal a

_start = ->
  try
    await main(process.argv[2..])
  catch e
    # DEBUG
    console.log "ERROR: #{e.stack}"
    #throw e
    process.exit 1
_start()
