# async.coffee, m3u8_dl-js/src/
# TODO use node v8.0 util.promisify ?

fs = require 'fs'


read_file = (file_path) ->
  new Promise (resolve, reject) ->
    fs.readFile file_path, 'utf8', (err, data) ->
      if err
        reject err
      else
        resolve data

read_file_byte = (filename) ->
  new Promise (resolve, reject) ->
    fs.readFile filename, (err, data) ->
      if err
        reject err
      else
        resolve data

write_file = (file_path, text) ->
  new Promise (resolve, reject) ->
    fs.writeFile file_path, text, 'utf8', (err) ->
      if err
        reject err
      else
        resolve()

# move file
mv = (from, to) ->
  new Promise (resolve, reject) ->
    fs.rename from, to, (err) ->
      if err
        reject err
      else
        resolve()

# check if file exist
file_exist = (file_path) ->
  new Promise (resolve, reject) ->
    fs.access file_path, fs.constants.R_OK, (err) ->
      if err
        resolve false
      else
        resolve true

# if file not exist, return null
get_file_size = (file_path) ->
  new Promise (resolve, reject) ->
    fs.stat file_path, (err, stats) ->
      if err  # never reject
        resolve null
      else
        resolve stats.size

list_dir = (file_path) ->
  new Promise (resolve, reject) ->
    fs.readdir file_path, (err, file_list) ->
      if err
        reject err
      else
        resolve file_list

mkdir = (file_path) ->
  new Promise (resolve, reject) ->
    fs.mkdir file_path, (err) ->
      if err
        reject err
      else
        resolve()

# for file-lock
fs_open = (file_path, flags) ->
  new Promise (resolve, reject) ->
    fs.open file_path, flags, (err, fd) ->
      if err
        reject err
      else
        resolve fd

# remove file
rm = (file_path) ->
  new Promise (resolve, reject) ->
    fs.unlink file_path, (err) ->
      if err
        reject err
      else
        resolve()

# sleep: setTimeout
sleep = (time_ms) ->
  new Promise (resolve, reject) ->
    _callback = ->
      resolve()  # never reject
    setTimeout _callback, time_ms


module.exports = {
  read_file  # async
  read_file_byte  # async
  write_file  # async

  mv  # async
  rm  # async
  file_exist  # async
  get_file_size  # async
  list_dir  # async

  mkdir  # async
  fs_open  # async

  sleep  # async
}
