const fs = require('fs');
const path = require('path');
const dist = 'dist';

const results = {};
function check(name, cond, extra = '') {
  results[name] = cond ? 'PASS' : 'FAIL';
  if (extra) console.log(`  [${cond ? 'PASS' : 'FAIL'}] ${name} — ${extra}`);
  else console.log(`  [${cond ? 'PASS' : 'FAIL'}] ${name}`);
}

console.log('=== HOMEPAGE ===');
const home = fs.readFileSync(path.join(dist, 'index.html'), 'utf8');
check('title has Remote Work Hub', home.includes('<title>') && /<title>[^<]*Remote Work Hub/i.test(home), (home.match(/<title>([^<]*)<\/title>/) || [])[1] || 'NO TITLE');
check('no [object Object]', !home.includes('[object Object]'));
check('no mojibake FFFD', !home.includes('\uFFFD'));
check('has crown css', home.includes('/crown-design-system.css'));
check('has CTA buttons', home.includes('cta-button') || home.includes('Explore Products') || home.includes('kit-subscribe'), `${(home.match(/cta-button/g) || []).length} cta-buttons`);
check('canonical', /rel="canonical" href="https:\/\/remoteworkhub\.net"?/.test(home), (home.match(/rel="canonical" href="([^"]+)"/) || [])[1]);

console.log('=== ARTICLE PAGE ===');
const art = fs.readFileSync(path.join(dist, '10-best-remote-jobs-beginners.html'), 'utf8');
check('article title', /<title>[^<]*10 Best Remote Jobs/i.test(art), (art.match(/<title>([^<]*)<\/title>/) || [])[1]);
check('article h1 present', art.includes('<h1>10 Best Remote Jobs for Beginners'));
check('no [object Object]', !art.includes('[object Object]'));
check('no FFFD mojibake', !art.includes('\uFFFD'));
check('canonical no .html', art.includes('rel="canonical" href="https://remoteworkhub.net/10-best-remote-jobs-beginners"'));
check('crown css', art.includes('/crown-design-system.css'));
check('theme class', art.includes('theme-') && art.includes('bg-[#0f172a]') || art.includes('class="theme-remoteworkhub"'));
check('ld+json Article', art.includes('"@type":"Article"'));
check('content body present', art.includes('Virtual Assistant') || art.includes('virtual assistant'));
check('related CTA link', art.includes('/all-articles'));

console.log('=== SPECIAL PAGES ===');
for (const p of ['about', 'all-articles', 'contact', 'privacy', 'disclaimer', 'checklist', 'store', 'thank-you', '404']) {
  const f = path.join(dist, p + '.html');
  if (!fs.existsSync(f)) { check(p, false, 'MISSING'); continue; }
  const c = fs.readFileSync(f, 'utf8');
  check(p, !c.includes('[object Object]') && !c.includes('\uFFFD') && c.includes('</html>'), `${c.length} bytes`);
}

console.log('=== ALL-ARTICLES CONTENT (old dynamic loader check) ===');
const aa = fs.readFileSync(path.join(dist, 'all-articles.html'), 'utf8');
check('all-articles has article links', (aa.match(/href="\//g) || []).length > 5, `${(aa.match(/href="\//g) || []).length} internal links`);
check('all-articles no dynamic-loader dependency', !aa.includes('dynamic-loader.js'));

console.log('=== ASSETS ===');
check('crown css in dist', fs.existsSync(path.join(dist, 'crown-design-system.css')));
check('favicon in dist', fs.existsSync(path.join(dist, 'assets', 'favicon.svg')));
check('og-image in dist', fs.existsSync(path.join(dist, 'assets', 'og-image.svg')));
check('CNAME in dist', fs.existsSync(path.join(dist, 'CNAME')), fs.readFileSync(path.join(dist, 'CNAME'), 'utf8').trim());

console.log('=== META TITLE ENCODING SPOT CHECK ===');
const meta = JSON.parse(fs.readFileSync('src/bodies/meta.json', 'utf8'));
const keys = Object.keys(meta);
console.log(`  meta.json entries: ${keys.length}`);
const sample = keys.slice(0, 5);
for (const k of sample) console.log(`  ${k}: title="${(meta[k].title || '').slice(0, 60)}"`);

let fails = Object.values(results).filter(v => v === 'FAIL').length;
console.log(`\n=== QA RESULT: ${Object.keys(results).length - fails}/${Object.keys(results).length} PASS ===`);
process.exit(fails ? 1 : 0);
