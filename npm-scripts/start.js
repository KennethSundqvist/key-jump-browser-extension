const fs = require('fs')
const http = require('http')

const PORT = process.env.PORT || 1337

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url.split('?')[0] === '/') {
    const html = fs.readFileSync('./test/test.html', {encoding: 'utf8'})
    res.writeHead(200, {'Content-Type': 'text/html'})
    res.end(html)
  } else {
    res.writeHead(404)
    res.end()
  }
})

server.listen(PORT)

console.log(`Server is listening: http://localhost:${PORT}`)
