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

    -T, --thread NUM            Set number of download thread (default: 1)
        --auto-remove           Remove raw file after decrypt success
    -H, --header NAME:VALUE     Set http header (can use more than once)
        --proxy-http IP:PORT    Set http proxy
        --proxy-socks5 IP:PORT  Set socks5 proxy
        --m3u8-base-url URL     Set base URL of the m3u8 file

    Set KEY (and IV) for AES-128 decrypt. Use HEX format, base64 format,
    or local binary file. Use ID to set multi-keys.

        --m3u8-key         [ID:]HEX
        --m3u8-iv          [ID:]HEX
        --m3u8-key-base64  [ID:]BASE64
        --m3u8-iv-base64   [ID:]BASE64
        --m3u8-key-file    [ID::]FILE
        --m3u8-iv-file     [ID::]FILE

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
  headers = {}
  _set_header = (raw) ->
    name = raw.split(':', 1)
    value = raw[(name.length + 1) ..]
    headers[name] = value
  _set_key_iv = (key_iv, format, value) ->
    # TODO support multi-keys
    #when '--m3u8-key'
    #  config.m3u8_key Buffer.from(_next(), 'hex')
    #when '--m3u8-iv'
    #  config.m3u8_iv Buffer.from(_next(), 'hex')
    #when '--m3u8-key-base64'
    #  config.m3u8_key Buffer.from(_next(), 'base64')
    #when '--m3u8-iv-base64'
    #  config.m3u8_iv Buffer.from(_next(), 'base64')
    #when '--m3u8-key-file'
    #  o.m3u8_key_file = _next()
    #when '--m3u8-iv-file'
    #  o.m3u8_iv_file = _next()
  # TODO support --continue to just continue download (with meta file ?)

  o = {}
  while rest.length > 0
    one = _next()
    switch one
      when '--help', '--version'
        o.type = one
      when '-o', '--output'
        config.output_dir _next()

      when '-T', '--thread'
        t = Number.parseInt _next()
        config.dl_thread t
        if t < 1
          throw new Error "bad thread num #{t}"
      when '--auto-remove'
        config.auto_remove true
      when '-H', '--header'
        _set_header _next()

      when '--proxy-http'
        p = _split_ip_port _next()
        p.type = 'http'
        config.proxy p
      when '--proxy-socks5'
        p = _split_ip_port _next()
        p.type = 'socks5'
        config.proxy p

      when '--m3u8-base-url'
        config.m3u8_base_url _next()

      when '--m3u8-key'
        _set_key_iv 'key', 'hex', _next()
      when '--m3u8-iv'
        _set_key_iv 'iv', 'hex', _next()
      when '--m3u8-key-base64'
        _set_key_iv 'key', 'base64', _next()
      when '--m3u8-iv-base64'
        _set_key_iv 'iv', 'base64', _next()
      when '--m3u8-key-file'
        _set_key_iv 'key', 'file', _next()
      when '--m3u8-iv-file'
        _set_key_iv 'iv', 'file', _next()

      else  # default: m3u8
        # warning before set
        if o.m3u8?
          log.w "set M3U8 to #{one}"
        o.m3u8 = one
  if (! o.type?) && (! o.m3u8?)
    throw new Error "empty command line"
  # check set headers
  if Object.keys(headers).length > 0
    log.d "use headers #{util.print_json headers}"
    config.headers headers
  o

_normal = (a) ->
  # FIXME support multi-keys
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
