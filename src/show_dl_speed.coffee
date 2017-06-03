# show_dl_speed.coffee, m3u8_dl-js/src/
path = require 'path'

async_ = require './async'
log = require './log'
config = require './config'
dl_speed = require './dl_speed'


_show_dl_speed = ->
  # check .meta file
  if ! await async_.file_exist(config.META_FILE)
    log.d "waiting for #{path.resolve config.META_FILE}"
    return
  # check .lock file exist
  # TODO improve output (only output once)
  if ! await async_.file_exist(config.LOCK_FILE)
    log.w "lock file `#{path.resolve config.LOCK_FILE}` not exist. m3u8_dl-js NOT running ?"

  await dl_speed.load_meta_file()
  # update (scan) and print one message
  exit_flag = await dl_speed.update()
  console.log dl_speed.print_speed()
  exit_flag

main = (argv) ->
  # check output directory
  if argv[0]?
    config.output_dir argv[0]

    process.chdir config.output_dir()
  # default: show current directory
  log.d "working directory #{process.cwd()}"

  # main loop
  while true
    if await _show_dl_speed()
      break  # exit
    await async_.sleep dl_speed.UPDATE_TIME

_start = ->
  try
    await main(process.argv[2..])
  catch e
    # DEBUG
    console.log "ERROR: #{e.stack}"
    #throw e
    process.exit 1
_start()
