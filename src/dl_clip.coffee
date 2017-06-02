# dl_clip.coffee, m3u8_dl-js/src/

fs = require 'fs'

async_ = require './async'
log = require './log'
config = require './config'
decrypt = require './decrypt'
dl_with_proxy = require './dl_with_proxy'


_decrypt_clip = (clip) ->
  _do_decrypt = (c, name) ->
    new Promise (resolve, reject) ->
      r = fs.createReadStream name.encrypted
      w = fs.createWriteStream name.ts_tmp
      r.pipe(c).pipe(w)
      r.on 'error', (err) ->
        reject err
      c.on 'error', (err) ->
        reject err
      w.on 'error', (err) ->
        reject err
      w.on 'finish', () ->
        resolve()
  before_size = await async_.get_file_size clip.name.encrypted

  iv = config.m3u8_iv()
  if ! iv?
    iv = clip.media_sequence
  c = decrypt.create_decrypt_stream(config.m3u8_key(), iv)
  await _do_decrypt c, clip.name

  after_size = await async_.get_file_size clip.name.ts_tmp
  # check decrypt success (by file_size)
  if ! (after_size < before_size)  # after remove padding
    log.w "#{clip.name.ts}: decrypt MAY fail !  (before_size = #{before_size}, after_size = #{after_size}) "
  else  # check auto remove
    if config.auto_remove()
      log.d "auto remove #{clip.name.encrypted}"
      await async_.rm clip.name.encrypted

dl_clip = (m3u8_info, index) ->
  clip = m3u8_info.clip[index]
  # check already exist and skip it
  if await async_.file_exist(clip.name.ts)
    log.d "dl_clip: skip exist file #{clip.name.ts}"
    return
  # download file (support proxy)
  try
    clip_url = clip.clip_url
    # DEBUG
    log.d "dl_clip: #{clip.name.ts}: #{clip_url}"
    await dl_with_proxy clip_url, clip.name.part
  catch e
    log.e "dl_clip: #{clip.name.ts}: download error ! "
    throw e
  # check need decrypt clip
  if config.m3u8_key()?
    # download one file done, rename it
    await async_.mv clip.name.part, clip.name.encrypted
    await _decrypt_clip clip
    await async_.mv clip.name.ts_tmp, clip.name.ts
  else  # no need to decrypt
    await async_.mv clip.name.part, clip.name.ts
  # download one clip done


module.exports = dl_clip  # async
