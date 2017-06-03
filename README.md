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
$
```


## LICENSE

`GNU GPL v3+`
