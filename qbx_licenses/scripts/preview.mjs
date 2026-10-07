import { chromium } from 'playwright';
import { createServer } from 'node:http';
import { readFileSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = fileURLToPath(new URL('.', import.meta.url));
const htmlDir = join(__dirname, '../html');
const artifactsDir = '/opt/cursor/artifacts';

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
};

function startServer() {
  return new Promise((resolve) => {
    const server = createServer((req, res) => {
      const path = join(htmlDir, req.url === '/' ? 'index.html' : req.url.split('?')[0]);
      if (!path.startsWith(htmlDir) || !existsSync(path)) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': mime[extname(path)] || 'application/octet-stream' });
      res.end(readFileSync(path));
    });
    server.listen(0, '127.0.0.1', () => {
      resolve({ server, url: `http://127.0.0.1:${server.address().port}/index.html` });
    });
  });
}

const mockCard = {
  firstname: 'Alex',
  lastname: 'Moreau',
  birthdate: '1994-06-12',
  sex: 'H',
  nationality: 'USA',
  citizenid: 'SER12345',
  licenses: [
    { name: 'driver', label: 'Permis voiture', short: 'Voiture', color: '#ff8c42', owned: true, points: 9, maxPoints: 12, valid: true, status: 'Valide' },
    { name: 'motorcycle', label: 'Permis moto', short: 'Moto', color: '#5ec8ff', owned: true, points: 12, maxPoints: 12, valid: true, status: 'Valide' },
    { name: 'boat', label: 'Permis bateau', short: 'Bateau', color: '#4ecdc4', owned: false, points: 0, maxPoints: 12, valid: false, status: 'Non détenu' },
    { name: 'aircraft', label: 'Permis avion', short: 'Avion', color: '#a78bfa', owned: true, points: 3, maxPoints: 12, valid: true, status: 'Valide' },
  ],
};

async function main() {
  const { server, url } = await startServer();
  const browser = await chromium.launch({ headless: true });

  try {
    const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    await page.goto(url, { waitUntil: 'networkidle' });

    // Mock FiveM NUI helper
    await page.addInitScript(() => {
      window.GetParentResourceName = () => 'qbx_licenses';
    });
    await page.goto(url, { waitUntil: 'networkidle' });

    await page.evaluate((card) => {
      window.postMessage({ action: 'open', card, closeKey: 'Backspace', autoCloseMs: 0 }, '*');
    }, mockCard);

    await page.waitForTimeout(500);
    await page.screenshot({
      path: join(artifactsDir, 'qbx_licenses_card_preview.png'),
      omitBackground: false,
    });

    // Simulate police removing points
    const updated = structuredClone(mockCard);
    updated.licenses[0].points = 6;
    updated.licenses[0].status = 'Valide';
    await page.evaluate((card) => {
      window.postMessage({ action: 'update', card }, '*');
    }, updated);
    await page.waitForTimeout(700);

    await page.screenshot({
      path: join(artifactsDir, 'qbx_licenses_card_points_removed.png'),
      omitBackground: false,
    });
  } finally {
    await browser.close();
    server.close();
  }
}

await main();
