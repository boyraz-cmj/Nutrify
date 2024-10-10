const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors({origin: '*'}));
app.use(express.json());

let logs = [];

function addLog(message) {
  const log = `${new Date().toISOString()} - ${message}`;
  console.log(log);
  logs.push(log);
  if (logs.length > 100) logs.shift(); // Son 100 logu tut
}

app.get('/', (req, res) => {
  res.send('Backend is running');
});

app.get('/product-name/:barcode', async (req, res) => {
  try {
    const { barcode } = req.params;
    addLog(`Received request for barcode: ${barcode}`);
    
    const url = 'https://platform.fatsecret.com/api-demo#barcode-api';
    addLog(`Sending request to: ${url}`);
    
    // İlk isteği gönder ve sayfayı al
    const response = await axios.get(url);
    addLog('Received initial response');
    
    let $ = cheerio.load(response.data);
    
    // Market dropdown'unu seç ve Turkey'i seç
    $('select[name="market"]').val('Turkey');
    addLog('Selected Turkey from market dropdown');
    
    // Barkod numarasını gir
    $('input[name="barcode"]').val(barcode);
    addLog(`Entered barcode: ${barcode}`);
    
    // Form gönderme işlemini simüle et
    const formData = new URLSearchParams();
    formData.append('market', 'Turkey');
    formData.append('barcode', barcode);
    
    addLog('Sending POST request to simulate form submission');
    const searchResponse = await axios.post(url, formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    addLog('Received search response');
    
    $ = cheerio.load(searchResponse.data);
    const productName = $('.food_title').first().text().trim();
    
    addLog(`Product name found: ${productName}`);
    res.json({ productName });
  } catch (error) {
    addLog(`Error: ${error.message}`);
    res.status(500).json({ error: 'An error occurred while fetching the product name', details: error.message });
  }
});

app.get('/logs', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Backend Logs</title>
        <script>
          setInterval(() => {
            fetch('/api/logs')
              .then(response => response.json())
              .then(data => {
                document.getElementById('logs').innerHTML = data.join('<br>');
              });
          }, 1000);
        </script>
      </head>
      <body>
        <h1>Backend Logs</h1>
        <div id="logs"></div>
      </body>
    </html>
  `);
});

app.get('/api/logs', (req, res) => {
  res.json(logs);
});

app.listen(port, '0.0.0.0', () => {
  addLog(`Server running at http://0.0.0.0:${port}`);
});