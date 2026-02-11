# burl - HTTP/HTTPS Client in Bash

Minimal HTTP/HTTPS client in pure Bash.

## Syntax

```bash
burl URL [HEADERS] [METHOD] [DATA]
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| URL | - | Complete URL (http:// or https://) |
| HEADERS | "" | Custom headers (separated by newline) |
| METHOD | GET | GET, POST, PUT, DELETE, etc. |
| DATA | "" | Request body |

**Output:** headers → stderr, body → stdout

## Basic Examples

### GET
```bash
burl "https://httpbin.org/get" ""
```

### POST with JSON
```bash
burl "https://httpbin.org/post" "Content-Type: application/json" "POST" '{"key":"value"}'
```
Sends JSON to endpoint. `Content-Type` specifies format, `POST` is the method, last parameter is the body.

### Multiple Headers
```bash
burl "https://api.example.com/data" "Authorization: Bearer xyz123
Accept: application/json
X-Custom: header" "GET"
```
Headers separated by newline (`\n`). Used for auth, content negotiation, custom headers.

### PUT
```bash
burl "https://api.example.com/resource/123" "Content-Type: application/json" "PUT" '{"status":"updated"}'
```
Updates existing resource with new status.

### DELETE
```bash
burl "https://api.example.com/resource/123" "Authorization: Bearer xyz123" "DELETE"
```
Requires auth, deletes resource.

## Advanced Examples

### Automatic Redirects
```bash
burl "http://httpbin.org/redirect/3" ""
```
Automatically follows up to 5 redirects. Output shows all steps on stderr.

### Chunked Transfer Encoding
```bash
burl "https://httpbin.org/stream/5" "" | jq -r '.id'
```
Automatically decodes chunked encoding. Uses `dd` for byte-accurate chunk reading.

### Pipe to jq
```bash
burl "https://httpbin.org/get" "" | jq '.headers["User-Agent"]'
```
JSON body goes to stdout, jq parses directly.

### Body Only
```bash
burl "https://httpbin.org/image/png" "" > image.png 2>/dev/null
```
`2>/dev/null` suppresses headers (stderr), saves only body.

### Headers Only
```bash
burl "https://httpbin.org/get" "" >/dev/null
```
`>/dev/null` eliminates body, shows only headers.

### Separate Headers and Body
```bash
burl "https://httpbin.org/get" "" > body.json 2> headers.txt
```
Separate redirects: body to file, headers to another.

### Count Redirects
```bash
burl "http://httpbin.org/redirect/3" "" 2>&1 | grep -c "HTTP/1.1"
```
`2>&1` merges stderr into stdout, counts total HTTP responses (redirects + final).

### Extract Specific Header
```bash
burl "https://httpbin.org/get" "" 2>&1 | grep -i "^content-type:"
```
Searches for case-insensitive header in response.

### Loop Over Endpoints
```bash
for i in {1..3}; do 
    burl "https://httpbin.org/get?id=$i" "" | jq -r ".args.id"
done
```
Iterates over query params, extracts value from each JSON response.

### Measure Time
```bash
time burl "https://httpbin.org/delay/2" "" >/dev/null
```
Endpoint with 2-second delay, `time` measures total duration.

### Bearer Token Auth
```bash
burl "https://httpbin.org/bearer" "Authorization: Bearer test_token" ""
```
Auth with token, endpoint verifies header presence.

### Full Debug
```bash
burl "https://httpbin.org/post" "Content-Type: application/json" "POST" '{"test":"data"}' 2>&1 | less
```
`2>&1` shows everything (headers + body), `less` for navigating output.

## How It Works

### URL Parsing
```bash
scheme="${u%%://*}"      # http or https
host="${hostport%%:*}"   # hostname
port="${hostport#*:}"    # port (80/443 default)
path="/${u#*/}"          # /path/to/resource
```
Bash parameter expansion for efficient splitting.

### HTTP Format
```
GET /path HTTP/1.1\r\n
Host: example.com\r\n
User-Agent: burl/1.0\r\n
Connection: close\r\n
\r\n
```
CRLF (`\r\n`) required by RFC 7230. Uses `printf`, not `echo`.

### TLS
```bash
openssl s_client -quiet -connect "$host:$port" -servername "$host"
```
`-servername` enables SNI for HTTPS virtual hosting.

### Chunked Decoding
```
size_hex\r\n
data[size]\r\n
0\r\n
```
Reads hex size, converts to decimal (`$((16#$size))`), uses `dd bs=1 count=$size` to read exactly N bytes (preserves internal newlines).

### Redirects
Detects 3xx status code, extracts Location header, converts relative paths to absolute (`$scheme://$host$location`), max 5 iterations.

## Limitations

**Not Supported:**
- HTTP/2, HTTP/3
- Compression (gzip, deflate, brotli)
- Keep-alive / connection reuse
- Cookie storage
- Auth schemes (Basic, Digest, OAuth)
- Certificate validation
- Proxy
- Multipart/form-data
- WebSocket

**Production:** use `curl` or `wget`.

## References

- [RFC 9110 - HTTP Semantics](https://datatracker.ietf.org/doc/html/rfc9110)
- [RFC 7230 - HTTP/1.1 Syntax](https://datatracker.ietf.org/doc/html/rfc7230)
- [RFC 7230 §4.1 - Chunked Transfer](https://datatracker.ietf.org/doc/html/rfc7230#section-4.1)
