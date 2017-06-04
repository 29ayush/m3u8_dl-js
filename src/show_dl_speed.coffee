# show_dl_speed.coffee, m3u8_dl-js/src/
path = require 'path'

async_ = require './async'
util = require './util'
log = require './log'
config = require './config'
dl_speed = require './dl_speed'

# TODO support put_exit_flag file ? check speed 0 ?

_etc = {
  lock_file_not_exist: false
  show_speed_zero_once: false
}

_show_dl_speed = (not_print_speed)->
  # check .meta file
  if ! await async_.file_exist(config.META_FILE)
    log.d "waiting for #{path.resolve config.META_FILE}"
    return
  # check .lock file exist
  not_show_speed_zero = false
  if ! await async_.file_exist(config.LOCK_FILE)
    not_show_speed_zero = true
    # only output once
    if ! _etc.lock_file_not_exist
      _etc.lock_file_not_exist = true
      # FIXME TODO move this WARNING down
      log.w "lock file `#{path.resolve config.LOCK_FILE}` not exist. m3u8_dl-js NOT running ?"
  else
    _etc.lock_file_not_exist = false

  await dl_speed.load_meta_file()
  # update (scan) and print one message
  exit_flag = await dl_speed.update()
  # check speed
  speed = dl_speed.get_dl_speed()
  print_speed = true
  if ((! speed?) || (speed < 1)) && not_show_speed_zero
    if _etc.show_speed_zero_once
      print_speed = false
    else
      _etc.show_speed_zero_once = true
  else
    _etc.show_speed_zero_once = false
  if print_speed && (! not_print_speed)
    console.log dl_speed.print_speed()
  # FIXME TODO move no LOCK warning here ?
  exit_flag

main = (argv) ->
  # check output directory
  if argv[0]?
    config.output_dir argv[0]
  # change cwd
  await util.check_change_cwd()
  log.d "working directory #{process.cwd()}"

  # init scan, but do not print speed
  await _show_dl_speed true
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
