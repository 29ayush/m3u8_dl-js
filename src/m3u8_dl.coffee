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

        --m3u8-base-url URL   Set base URL of the m3u8 file
        --m3u8-key HEX        Set decrypt KEY (in HEX format)
        --m3u8-iv HEX         Set decrypt IV (in HEX format)
        --m3u8-key-file FILE  Read decrypt KEY from FILE (in binary format)
        --m3u8-iv-file FILE   Read decrypt IV from FILE (in binary format)

        --version  Show version of this program
        --help     Show this help text
  More information online <https://github.com/sceext2/m3u8_dl-js>
  """

_p_bad_command_line = ->
  log.e "bad command line, please try `--help` "

_p_arg = (args) ->
  o = {}
  rest = args
  while rest.length > 0
    [one, rest] = [ rest[0], rest[1..] ]
    switch one
      when '--help', '--version'
        o.type = one
      # TODO
      else  # default: m3u8
        # TODO warning before set
        o.m3u8 = one
  if (! o.type?) && (! o.m3u8?)
    throw new Error "empty command line"
  o

_normal = (a) ->
  throw new Error "NOT IMPLEMENTED"
  # TODO

  # TODO
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
