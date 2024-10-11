const express = require('express');
const puppeteer = require('puppeteer');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');
const Tesseract = require('tesseract.js');

const app = express();
const port = 3000;

app.use(cors({origin: '*'}));
app.use(express.json());
app.use('/screenshots', express.static(path.join(__dirname, 'screenshots')));

let logs = [];

async function addLog(step, message, details = null, screenshot = null) {
  const log = `[${step}] ${message}`;
  console.log(log);
  logs.push(log);
  if (details) {
    const detailLog = JSON.stringify(details, null, 2);
    console.log(detailLog);
    logs.push(detailLog);
  }
  if (screenshot) {
    try {
      const filename = `screenshot_${Date.now()}.png`;
      const filePath = path.join(__dirname, 'screenshots', filename);
      await fs.writeFile(filePath, screenshot);
      logs.push(`<img src="/screenshots/${filename}" style="max-width: 100%; height: auto; margin-top: 10px; border: 1px solid #ddd;">`);
    } catch (error) {
      console.error('Error saving screenshot:', error);
      logs.push(`Error saving screenshot: ${error.message}`);
    }
  }
  if (logs.length > 100) logs.shift(); // Son 100 logu tut
}

app.get('/', (req, res) => {
  res.send('Backend is running');
});

app.get('/product-name/:barcode', async (req, res) => {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
    defaultViewport: null,
    timeout: 60000 // 60 saniye
  });
  const page = await browser.newPage();
  
  try {
    const { barcode } = req.params;
    await addLog('START', `Received request for barcode: ${barcode}`);
    
    const url = 'https://platform.fatsecret.com/api-demo#barcode-api';
    await addLog('NAVIGATION', `Navigating to: ${url}`);
    
    await page.goto(url, { waitUntil: 'networkidle0', timeout: 60000 });
    try {
      let screenshot = await page.screenshot();
      await addLog('PAGE_LOADED', 'Barcode API page loaded', null, screenshot);
    } catch (error) {
      console.error('Error taking screenshot:', error);
      await addLog('SCREENSHOT_ERROR', 'Error taking screenshot', { error: error.message });
    }
    
    // JavaScript'in çalışmasını bekleyelim
    await page.waitForSelector('#barcode_market', { visible: true, timeout: 10000 });
    
    // Market seçimi
    try {
      await page.select('#barcode_market', 'TR');
      const selectedMarket = await page.$eval('#barcode_market', el => el.value);
      screenshot = await page.screenshot();
      await addLog('MARKET_SELECTED', `Selected market: ${selectedMarket}`, null, screenshot);
    } catch (error) {
      console.error('Error selecting market:', error);
      await addLog('MARKET_SELECTION_ERROR', 'Error selecting market', { error: error.message });
    }

    // Barkod girişi
    await page.type('input[name="Barcode"]', barcode);
    screenshot = await page.screenshot();
    await addLog('BARCODE_ENTERED', 'Entered barcode', null, screenshot);

    // Formu gönderelim
    const submitButton = await page.$('#barcode_search_button');
    if (submitButton) {
      await addLog('SUBMIT_BUTTON_FOUND', 'Submit button found');
      await submitButton.click();
      
      // Yükleme göstergesini bekleyelim
      await addLog('WAITING_FOR_RESULTS', 'Waiting for results to load');
      await page.waitForSelector('.loading-indicator', { visible: true, timeout: 10000 }).catch(() => {});
      await page.waitForSelector('.loading-indicator', { hidden: true, timeout: 60000 }).catch(() => {});
      
      // Sonuç sayfasının yüklenmesini bekleyelim
      await page.waitForSelector('.brand-name, .food-name, .no-results-message, .content', { timeout: 60000 });
      
      screenshot = await page.screenshot();
      await addLog('RESULTS_PAGE_LOADED', 'Results page loaded', null, screenshot);
    } else {
      await addLog('SUBMIT_BUTTON_NOT_FOUND', 'Submit button not found');
    }

    // "Unknown barcode" kontrolü ekleyelim
    const unknownBarcodeElement = await page.$('.content');
    if (unknownBarcodeElement) {
      const content = await page.evaluate(el => el.textContent, unknownBarcodeElement);
      if (content.trim().toLowerCase() === 'unknown barcode') {
        await addLog('UNKNOWN_BARCODE', 'Unknown barcode error detected');
        return res.status(404).json({ error: 'Unknown barcode' });
      }
    }

    // Sonucu alalım
    const noResults = await page.$('.no-results-message');
    if (noResults) {
      await addLog('NO_RESULTS', 'No results found for this barcode');
      res.status(404).json({ error: 'Product not found' });
    } else {
      const brandName = await page.$eval('.brand-name', el => el.textContent.trim()).catch(() => null);
      let foodName = await page.$eval('.food-name', el => el.textContent.trim()).catch(() => null);

      // Eğer foodName, brandName'i içeriyorsa, brandName'i çıkar
      if (foodName && brandName && foodName.includes(brandName)) {
        foodName = foodName.replace(brandName, '').trim();
      }

      if (brandName || foodName) {
        const result = {
          brandName: brandName || 'Marka bulunamadı',
          productName: foodName || 'Ürün adı bulunamadı'
        };
        await addLog('SUCCESS', `Product found: ${JSON.stringify(result)}`, null, await page.screenshot());
        res.json(result);
      } else {
        await addLog('NOT_FOUND', 'Product information not found in the response', null, await page.screenshot());
        res.status(404).json({ error: 'Product not found' });
      }
    }
  } catch (error) {
    await addLog('ERROR', `Error: ${error.message}`, { stack: error.stack }, await page.screenshot());
    res.status(500).json({ error: 'An error occurred while fetching the product information', details: error.message });
  } finally {
    await browser.close();
  }
});

app.get('/logs', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Backend Logs</title>
        <style>
          body { font-family: Arial, sans-serif; }
          #logs { margin-top: 20px; }
          img { max-width: 100%; height: auto; margin-top: 10px; border: 1px solid #ddd; }
        </style>
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

const screenshotsDir = path.join(__dirname, 'screenshots');
fs.mkdir(screenshotsDir, { recursive: true }, (err) => {
  if (err) {
    console.error('Error creating screenshots directory:', err);
  } else {
    console.log('Screenshots directory is ready');
  }
});

app.listen(port, '0.0.0.0', () => {
  addLog('SERVER', `Server running at http://0.0.0.0:${port}`);
});

app.post('/scan', async (req, res) => {
  const { image } = req.body;

  if (!image) {
    return res.status(400).json({ error: 'Image data is required' });
  }

  try {
    const result = await Tesseract.recognize(Buffer.from(image, 'base64'), 'eng');
    const text = result.data.text.trim();

    // "Unknown barcode" kontrolü ekleyelim
    if (text.toLowerCase().includes('unknown barcode')) {
      return res.status(404).json({ error: 'Unknown barcode' });
    }

    // Diğer işlemler...
    // Örneğin, barkod numarasını çıkarma ve veritabanında arama

    // Eğer ürün bulunamazsa
    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ product });
  } catch (error) {
    console.error('Error processing image:', error);
    res.status(500).json({ error: 'Error processing image' });
  }
});