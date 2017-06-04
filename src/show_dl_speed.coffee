# show_dl_speed.coffee, m3u8_dl-js/src/
path = require 'path'

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'
dl_speed = require './dl_speed'

# TODO support put_exit_flag file ? check speed 0 ?

_etc = {
  ed_print_lock_not_exist: false
  ed_print_speed_zero: false
}

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

  exit_flag

main = (argv) ->
  # check output directory
  if argv[0]?
    config.output_dir argv[0]
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

_start = ->
  try
    await main(process.argv[2..])
  catch e
    # DEBUG
    console.log "ERROR: #{e.stack}"
    #throw e
    process.exit 1
_start()
