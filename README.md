# m3u8_dl-js
A simple `m3u8` downloader in `node.js`.


## Build from source

+ **1**. Install `node.js` (<https://nodejs.org/en/download/current/>)

+ **2**.

  ```
  $ npm install
  $ node ./node_modules/.bin/coffee -o dist/ src/
  ```

**Run**

```
$ node dist/m3u8_dl.js --version
```


## Usage

```
$ node dist/m3u8_dl.js --help
m3u8_dl-js [OPTIONS] M3U8
Usage:
  -o, --output DIR  Download files to this Directory

      --proxy-http IP:PORT    Set http proxy
      --proxy-socks5 IP:PORT  Set socks5 proxy

      --thread NUM   Set number of download thread (default: 1)
      --auto-remove  Remove raw file after decrypt success

      --header NAME:VALUE  Set http header (can use more than once)

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
$
```


## LICENSE

`GNU GPL v3+`
