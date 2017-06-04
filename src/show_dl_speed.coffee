# show_dl_speed.coffee, m3u8_dl-js/src/
path = require 'path'

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'
dl_speed = require './dl_speed'


_p_help = ->
  console.log '''
  show_dl_speed [OPTIONS] [DIR]
  Usage:

    --retry-after SEC  Retry after this seconds (default: 10)
    --retry-hide SEC   Hide retry debug info in this seconds (default: 5)

    --put-exit-flag    Enable retry function (put flag file)

    --version  Show version of this program
    --help     Show this help text
  More information online <https://github.com/sceext2/m3u8_dl-js>
  '''

_p_arg = (args) ->
  rest = args
  _next = ->
    o = rest[0]
    rest = rest[1..]
    o

  o = {}
  while rest.length > 0
    one = _next()
    switch one
      when '--help', '--version'
        o.type = one

      when '--retry-after'
        o.retry_after = Number.parseInt _next()
      when '--retry-hide'
        o.retry_hide = Number.parseInt _next()
      when '--put-exit-flag'
        o.put_exit_flag = true

      else  # default: DIR
        config.output_dir one
  o

_etc = {
  ed_print_lock_not_exist: false
  ed_print_speed_zero: false

  retry_after: 10
  retry_hide: 5

  speed_0_count: 0
  put_exit_flag: false
}

_put_flag_file = ->
  log.d "put exit flag file `#{path.resolve config.EXIT_FLAG_FILE}`"
  await util.write_file config.EXIT_FLAG_FILE, ''  # create null flag file

# if download speed keeps 0, put `m3u8_dl.exit.flag` file to retry
_check_put_exit_flag = (speed) ->
  if speed > 0
    # reset count
    _etc.speed_0_count = 0
    return
  # count second
  _etc.speed_0_count += 1
  # check count
  if _etc.speed_0_count > _etc.retry_after
    _etc.speed_0_count = 0  # reset first
    log.d "retry after #{_etc.speed_0_count} s"
    await _put_flag_file()
  else if _etc.speed_0_count > _etc.retry_hide
    log.d "speed keep 0 for #{_etc.speed_0_count} s, will retry after #{_etc.retry_after - _etc.speed_0_count} s"


_show_dl_speed = (not_print_speed)->
  # check .meta file
  if ! await async_.file_exist(config.META_FILE)
    log.d "waiting for #{path.resolve config.META_FILE}"
    return
  # check .lock file exist
  if await async_.file_exist config.LOCK_FILE
    lock_exist = true
    # reset flag
    _etc.ed_print_lock_not_exist = false
  else
    lock_exist = false

  await dl_speed.load_meta_file()
  # update (scan) and print one message
  exit_flag = await dl_speed.update()
  # check speed
  speed = dl_speed.get_dl_speed()
  if (! speed?) || (speed < 1)
    speed = 0
  else
    # reset flag
    _etc.ed_print_speed_zero = false
  # print speed
  print_speed = true
  if (! lock_exist) && (speed is 0)
    if _etc.ed_print_speed_zero
      print_speed = false
    else
      _etc.ed_print_speed_zero = true
  # do print speed before exit
  if exit_flag
    not_print_speed = false
  if print_speed && (! not_print_speed)
    console.log dl_speed.print_speed()
  # print lock warning
  if (! lock_exist) && (! exit_flag) && (! not_print_speed)  # not print warning when exit
    # print warning after speed is zero
    if ((speed is 0) || _etc.ed_print_speed_zero) && (! _etc.ed_print_lock_not_exist)
      _etc.ed_print_lock_not_exist = true
      log.w "lock file `#{path.resolve config.LOCK_FILE}` not exist. m3u8_dl-js NOT running ?"
  # check put exit flag file
  if lock_exist
    await _check_put_exit_flag speed
  else
    _etc.speed_0_count = 0  # reset count
  exit_flag

_normal = (a) ->
  # save options
  if a.retry_after?
    _etc.retry_after = a.retry_after
  if a.retry_hide?
    _etc.retry_hide = a.retry_hide
  if a.put_exit_flag
    _etc.put_exit_flag = true
  # change cwd
  await util.check_change_cwd()
  log.d "working directory #{process.cwd()}"
  # init scan, but do not print speed
  if await _show_dl_speed true
    return  # if start at done, not enter main loop
  # main loop
  while true
    # sleep before scan again
    await async_.sleep dl_speed.UPDATE_TIME
    if await _show_dl_speed()
      break  # exit

main = (argv) ->
  a = _p_arg argv
  # check start type
  switch a.type
    when '--help'
      _p_help()
    when '--version'
      util.p_version()
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
