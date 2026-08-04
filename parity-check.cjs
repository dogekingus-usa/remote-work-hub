const fs = require('fs');
const path = require('path');
const dist = 'dist';

// build dist slug set
const distSlugs = new Set();
function walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (e.name.endsWith('.html')) {
      let rel = p.replace(/\\/g, '/').replace(/^dist\//, '');
      rel = rel.replace(/\.html$/, '');
      distSlugs.add(rel);
    }
  }
}
walk(dist);
console.log('dist html (excluding og-images):', [...distSlugs].filter(s => !s.startsWith('og-images/')).length);
console.log('og-images copies in dist:', [...distSlugs].filter(s => s.startsWith('og-images/')).length);

// fetch live sitemap
const https = require('https');
https.get('https://remoteworkhub.net/sitemap.xml', res => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => {
    const live = [...data.matchAll(/<loc>https:\/\/remoteworkhub\.net(\/[^<]*)<\/loc>/g)].map(m => m[1].replace(/\/$/, ''));
    console.log('live sitemap:', live.length);
    const real = [...distSlugs].filter(s => !s.startsWith('og-images/'));
    const missing = [];
    for (const u of live) {
      const cand = u.replace(/^\//, '').replace(/\/$/, '');
      if (cand && !real.includes(cand)) missing.push(u);
    }
    console.log('MISSING:', missing.length);
    missing.slice(0, 30).forEach(m => console.log('  ', m));
    // also check .html variants in dist for those
    console.log('sample missing check:', missing.slice(0, 5).map(m => m + ' => dist' + m + '.html exists: ' + fs.existsSync('dist' + m + '.html')));
  });
}).on('error', e => { console.error('fetch fail', e.message); process.exit(1); });
