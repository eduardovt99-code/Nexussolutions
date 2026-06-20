const puppeteer = require('puppeteer');
const handler = require('serve-handler');
const http = require('http');

const server = http.createServer((request, response) => {
  return handler(request, response, { public: 'build/web' });
});

server.listen(3000, async () => {
  console.log('Server running on http://localhost:3000');
  const browser = await puppeteer.launch({ headless: "new" });
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', err => console.log('PAGE ERROR:', err.toString()));
  
  await page.goto('http://localhost:3000/index.html', { waitUntil: 'networkidle2' });
  
  setTimeout(async () => {
    await browser.close();
    server.close();
  }, 5000);
});
