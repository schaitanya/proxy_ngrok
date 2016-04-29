httpProxy = require 'http-proxy'
connect   = require 'connect'
ngrok     = require 'ngrok'
config    = require './config'

proxy = httpProxy.createProxyServer target: config.proxy.target, secure: config.proxy.secure

app = connect()

# Modify write method so we won't return any data
app.use (req, res, next) ->
  res.write = ->
  next()

# Forward the request to the server
app.use (req, res) ->
  proxy.web req, res

# Create Proxy Server
server = app.listen config.proxy.port, ->
  console.log "Proxy running on port: #{config.proxy.port}"

  # Establish Ngrok connection
  ngrok.connect
    proto     : config.ngrok.proto       # http|tcp|tls
    addr      : config.proxy.port        # port or network address
    subdomain : config.ngrok.subdomain   # reserved tunnel name https://subdomain.ngrok.io,
    authtoken : config.ngrok.auth_token  # your authtoken from ngrok.com
    # auth : 'user:pwd'                  # http basic authentication for tunnel
  , (err, url) ->
    return console.log err if err
    console.log "Your ngrok URL is #{url}"

# Gracefully kill ngrok
exit = ->
  console.log 'Exiting...'
  ngrok.kill()
  server.close()
  process.exit()

# Buffer data
# process.stdin.on 'data', (data) ->
  # console.log data?.toString()

process.once 'SIGUSR2', exit  # Nodemon
process.once 'SIGINT',  exit  # Ctrl-C
