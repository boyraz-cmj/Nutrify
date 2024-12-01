const express = require('express');
const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const RecaptchaPlugin = require('puppeteer-extra-plugin-recaptcha');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');
const Tesseract = require('tesseract.js');
const cheerio = require('cheerio');

puppeteer.use(StealthPlugin());

puppeteer.use(
  RecaptchaPlugin({
    provider: {
      id: '2captcha',
      token: 'YOUR_2CAPTCHA_API_KEY'
    },
    visualFeedback: true
  })
);

const app = express();
const port = 3000;

app.use(cors({origin: '*'}));
app.use(express.json());
app.use('/screenshots', express.static(path.join(__dirname, 'screenshots')));

let logs = [];
let browser = null;
let page = null;
let isCaptchaSolved = false;

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

// Screenshot'ları temizleme fonksiyonu
async function clearScreenshots() {
  try {
    const files = await fs.readdir(screenshotsDir);
    for (const file of files) {
      if (file.startsWith('screenshot_')) {
        await fs.unlink(path.join(screenshotsDir, file));
      }
    }
    logs = logs.filter(log => !log.includes('<img src="/screenshots/'));
    await addLog('CLEANUP', 'Cleared previous screenshots');
  } catch (error) {
    console.error('Error clearing screenshots:', error);
  }
}

app.get('/', (req, res) => {
  res.send('Backend is running');
});

function extractNutritionClaims(html) {
  const $ = cheerio.load(html);
  const nutritionClaims = {
    allergens: {},
    dietaryInfo: {}
  };

  // Free from allergens
  $('.border.border-info.p-2 ul li i.bi-check-square.text-success').each((_, el) => {
    const allergen = $(el).parent().text().trim();
    if (allergen) {
      nutritionClaims.allergens[allergen] = 'free';
    }
  });

  // May contain allergens
  $('.border.border-info.p-2 ul li i.bi-question-square.text-warning').each((_, el) => {
    const allergen = $(el).parent().text().trim();
    if (allergen) {
      nutritionClaims.allergens[allergen] = 'may';
    }
  });

  // Dietary information
  const dietText = $('.border.border-info.p-2 .row:last-child .col').text().trim();
  
  // Vegan kontrolü
  if (dietText.includes('Vegan') && dietText.includes('not suitable')) {
    nutritionClaims.dietaryInfo['Vegan'] = false;
  } else {
    nutritionClaims.dietaryInfo['Vegan'] = true;
  }
  
  // Vegetarian kontrolü
  if (dietText.includes('Vegetarian') && dietText.includes('not suitable')) {
    nutritionClaims.dietaryInfo['Vegetarian'] = false;
  } else {
    nutritionClaims.dietaryInfo['Vegetarian'] = true;
  }

  // Debug için log ekleyelim
  console.log('Extracted Nutrition Claims:', JSON.stringify(nutritionClaims, null, 2));

  return nutritionClaims;
}

app.get('/product-name/:barcode', async (req, res) => {
  try {
    // Her yeni istek başlangıcında eski screenshot'ları temizle
    await clearScreenshots();

    // Browser yoksa başlat
    if (!browser) {
      browser = await puppeteer.launch({
        headless: false,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--window-size=1366,768',
        ],
        defaultViewport: null,
      });
      
      page = await browser.newPage();
      await page.goto('https://platform.fatsecret.com/api-demo#barcode-api', { 
        waitUntil: 'networkidle0',
        timeout: 60000 
      });
      
      let screenshot = await page.screenshot();
      await addLog('PAGE_LOADED', 'Initial page load', null, screenshot);
    }

    const { barcode } = req.params;

    // Eğer captcha henüz çözülmediyse
    if (!isCaptchaSolved) {
      try {
        const frames = await page.frames();
        const recaptchaFrame = frames.find(frame => 
          frame.url().includes('recaptcha')
        );

        if (recaptchaFrame) {
          let screenshot = await page.screenshot();
          await addLog('CAPTCHA_DETECTED', 'Waiting for manual CAPTCHA solution...', null, screenshot);
          
          await page.waitForSelector('input[name="Barcode"]', { 
            visible: true, 
            timeout: 300000  // 5 dakika
          });
          
          screenshot = await page.screenshot();
          await addLog('CAPTCHA_SOLVED', 'Barcode input field is now visible', null, screenshot);
          isCaptchaSolved = true;
        }
      } catch (error) {
        await addLog('CAPTCHA_ERROR', 'Error with CAPTCHA', { error: error.message });
      }
    }

    // Barkod arama işlemleri
    try {
      // Market seçimini daha güvenilir hale getirelim
      await page.waitForSelector('#barcode_market', { visible: true });
      await page.evaluate(() => {
        const marketSelect = document.querySelector('#barcode_market');
        if (marketSelect) {
          marketSelect.value = 'TR';
          // Change event'ini tetikle
          const event = new Event('change', { bubbles: true });
          marketSelect.dispatchEvent(event);
          // Input event'ini de tetikle
          const inputEvent = new Event('input', { bubbles: true });
          marketSelect.dispatchEvent(inputEvent);
        }
      });
      
      // Market seçiminin uygulanmasını bekle
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      let screenshot = await page.screenshot();
      await addLog('MARKET_SELECTED', 'Selected market: TR', null, screenshot);

      // Barkod girişi
      await page.evaluate((barcodeValue) => {
        const input = document.querySelector('input[name="Barcode"]');
        if (input) {
          input.value = barcodeValue;
          input.dispatchEvent(new Event('input', { bubbles: true }));
        }
      }, barcode);
      
      screenshot = await page.screenshot();
      await addLog('BARCODE_ENTERED', `Entered barcode: ${barcode}`, null, screenshot);

      const submitButton = await page.waitForSelector('#barcode_search_button', { visible: true });
      if (submitButton) {
        await submitButton.click();
        await addLog('SUBMIT_CLICKED', 'Clicked submit button');
        
        try {
          // Yükleme göstergesinin görünmesini bekle
          await page.waitForSelector('.loading-indicator', { visible: true, timeout: 10000 })
            .catch(() => console.log('Loading indicator not found'));
          
          // Yükleme göstergesinin kaybolmasını bekle
          await page.waitForSelector('.loading-indicator', { hidden: true, timeout: 60000 })
            .catch(() => console.log('Loading indicator still visible'));
          
          // Sonuçların yüklenmesi için kısa bir bekleme
          await new Promise(resolve => setTimeout(resolve, 2000));
          
          screenshot = await page.screenshot();
          await addLog('RESULTS_LOADED', 'Results page loaded', null, screenshot);
          
          // Önce "Unknown barcode" kontrolü
          const content = await page.$('.content');
          if (content) {
            const text = await page.evaluate(el => el.textContent.trim(), content);
            if (text.includes('Unknown barcode')) {
              await addLog('UNKNOWN_BARCODE', 'Unknown barcode detected');
              return res.status(404).json({ error: 'Unknown barcode' });
            }
          }

          // Ürün bilgilerini almayı dene
          const brandName = await page.$eval('.brand-name', el => el.textContent.trim())
            .catch(() => null);
          const foodName = await page.$eval('.food-name', el => el.textContent.trim())
            .catch(() => null);

          // Besin değerlerini çek
          const nutritionFacts = await page.evaluate(() => {
            try {
              // Kalori bilgisini al
              const calories = document.querySelector('.hero_value.black.right')?.textContent.trim() || '0';
              
              // Diğer besin değerlerini al
              const nutrients = {};
              const rows = document.querySelectorAll('.nutrition_facts .nutrient');
              
              let currentLabel = '';
              rows.forEach(row => {
                const isLabel = row.classList.contains('left') && !row.classList.contains('value');
                const isValue = row.classList.contains('value');
                
                if (isLabel) {
                  currentLabel = row.textContent.trim();
                } else if (isValue && currentLabel) {
                  let value = row.textContent.trim();
                  // Eğer değer sadece "-" ise "0" olarak değiştir
                  if (value === '-') value = '0';
                  
                  switch (currentLabel) {
                    case 'Total Fat':
                      nutrients.totalFat = value || '0g';
                      break;
                    case 'Saturated Fat':
                      nutrients.saturatedFat = value || '0g';
                      break;
                    case 'Trans Fat':
                      nutrients.transFat = value || '0g';
                      break;
                    case 'Cholesterol':
                      nutrients.cholesterol = value || '0mg';
                      break;
                    case 'Sodium':
                      nutrients.sodium = value || '0mg';
                      break;
                    case 'Total Carbohydrate':
                      nutrients.totalCarbohydrate = value || '0g';
                      break;
                    case 'Dietary Fiber':
                      nutrients.dietaryFiber = value || '0g';
                      break;
                    case 'Sugars':
                      nutrients.sugars = value || '0g';
                      break;
                    case 'Protein':
                      nutrients.protein = value || '0g';
                      break;
                    case 'Vitamin D':
                      nutrients.vitaminD = value || '0mcg';
                      break;
                    case 'Calcium':
                      nutrients.calcium = value || '0mg';
                      break;
                    case 'Iron':
                      nutrients.iron = value || '0mg';
                      break;
                    case 'Potassium':
                      nutrients.potassium = value || '0mg';
                      break;
                  }
                }
              });

              return {
                servingSize: document.querySelector('.serving_size_value')?.textContent.trim() || '100g',
                calories: calories,
                ...nutrients
              };
            } catch (error) {
              console.error('Error extracting nutrition facts:', error);
              return null;
            }
          }).catch(() => null);

          // Nutrition facts çekildikten sonra nutrition claims'i de çekelim
          const nutritionClaims = await page.evaluate(() => {
            try {
              const claims = {
                allergens: {},
                dietaryInfo: {}
              };

              // Free from allergens
              document.querySelectorAll('.border.border-info.border-1 ul li i.bi-check-square.text-success').forEach(el => {
                const allergen = el.parentElement.textContent.trim().replace(/\s+/g, ' ');
                if (allergen) {
                  claims.allergens[allergen] = 'free';
                }
              });

              // May contain allergens
              document.querySelectorAll('.border.border-info.border-1 ul li i.bi-question-square.text-warning').forEach(el => {
                const allergen = el.parentElement.textContent.trim().replace(/\s+/g, ' ');
                if (allergen) {
                  claims.allergens[allergen] = 'may';
                }
              });

              // Dietary information
              const dietText = document.querySelector('.border.border-info.border-1 .row:last-child .col')?.textContent.trim() || '';
              
              // Sadece "not suitable" bilgisi varsa false değerini set et
              if (dietText.includes('not suitable')) {
                if (dietText.includes('Vegan')) {
                  claims.dietaryInfo['Vegan'] = false;
                }
                if (dietText.includes('Vegetarian')) {
                  claims.dietaryInfo['Vegetarian'] = false;
                }
              }

              console.log('Extracted claims:', claims);
              return claims;
            } catch (error) {
              console.error('Error extracting nutrition claims:', error);
              return {
                allergens: {},
                dietaryInfo: {}
              };
            }
          });

          if (brandName || foodName) {
            const result = {
              brandName: brandName || 'Marka bulunamadı',
              productName: foodName || 'Ürün adı bulunamadı',
              nutritionFacts: nutritionFacts || {},
              nutritionClaims: nutritionClaims || {
                allergens: {},
                dietaryInfo: {}
              }
            };

            console.log('Extracted Claims:', JSON.stringify(nutritionClaims, null, 2));
            await addLog('SUCCESS', `Found product with all data: ${JSON.stringify(result, null, 2)}`);
            return res.json(result);
          } else {
            await addLog('NO_PRODUCT_INFO', 'No product information found');
            return res.status(404).json({ error: 'Product not found' });
          }
        } catch (error) {
          screenshot = await page.screenshot();
          await addLog('ERROR', 'Error processing results', 
            { error: error.message }, screenshot);
          return res.status(500).json({ error: error.message });
        }
      } else {
        await addLog('ERROR', 'Submit button not found');
        return res.status(500).json({ error: 'Submit button not found' });
      }
    } catch (error) {
      console.error('Error:', error);
      res.status(500).json({ error: error.message });
    }
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
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

    if (text.toLowerCase().includes('unknown barcode')) {
      return res.status(404).json({ error: 'Unknown barcode' });
    }

    if (!product) {
      return res.status(404).json({ error: 'Product not found' });
    }

    res.json({ product });
  } catch (error) {
    console.error('Error processing image:', error);
    res.status(500).json({ error: 'Error processing image' });
  }
});

// Uygulama kapatıldığında browser'ı temizle
process.on('SIGINT', async () => {
  if (browser) {
    await browser.close();
  }
  process.exit();
});