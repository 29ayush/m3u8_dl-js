# async.coffee, m3u8_dl-js/src/

fs = require 'fs'


read_file = (file_path) ->
  new Promise (resolve, reject) ->
    fs.readFile file_path, 'utf8', (err, data) ->
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


module.exports = {
  read_file  # async
  write_file  # async

  mv  # async
  rm  # async
  file_exist  # async

  fs_open  # async
}
