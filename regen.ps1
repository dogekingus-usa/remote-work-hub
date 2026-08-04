$ErrorActionPreference = 'Stop'
$wt = 'C:\Users\SAMPC\remoteworkhub-us-astro'
$bodiesDir = "$wt\src\bodies"
$pagesDir = "$wt\src\pages"
$utf8 = New-Object System.Text.UTF8Encoding($false)

New-Item -ItemType Directory -Force -Path $bodiesDir | Out-Null
New-Item -ItemType Directory -Force -Path $pagesDir | Out-Null

# ---------------------------------------------------------------
# 0. Stage public assets: crown css + assets + og-images + JS loaders into public/
# ---------------------------------------------------------------
$publicDir = "$wt\public"
New-Item -ItemType Directory -Force -Path $publicDir | Out-Null
foreach ($src in @("$wt\crown-design-system.css", "$wt\assets", "$wt\og-images", "$wt\articles-data.js", "$wt\dynamic-loader.js")) {
  if (Test-Path $src) {
    Copy-Item $src $publicDir -Recurse -Force
    Write-Host "staged: $src -> public/"
  }
}
if (Test-Path "$wt\CNAME") { Copy-Item "$wt\CNAME" $publicDir -Force; Write-Host "staged: CNAME" }

# ---------------------------------------------------------------
# 1. Extract body content from each clone HTML file
# ---------------------------------------------------------------
$htmlFiles = Get-ChildItem $wt -Filter *.html -File
$meta = @{}
$cleaned = @()
foreach ($f in $htmlFiles) {
  $slug = $f.BaseName
  $c = [System.IO.File]::ReadAllText($f.FullName)

  # title + description from head
  $title = ''
  $tm = [regex]::Match($c, '<title>([\s\S]*?)</title>')
  if ($tm.Success) { $title = $tm.Groups[1].Value.Trim() }
  $desc = ''
  $dm = [regex]::Match($c, '<meta name="description" content="([^"]*)"')
  if ($dm.Success) { $desc = $dm.Groups[1].Value.Trim() }
  $canon = ''
  $cm = [regex]::Match($c, '<link rel="canonical" href="([^"]*)"')
  if ($cm.Success) { $canon = $cm.Groups[1].Value.Trim() }

  # body inner
  $bStart = $c.IndexOf('<body')
  $bEnd = $c.IndexOf('</body>')
  if ($bStart -lt 0 -or $bEnd -lt 0) { Write-Host "SKIP (no body): $slug"; continue }
  $body = $c.Substring($bStart, $bEnd - $bStart)
  # drop the <body ...> tag itself
  $gtIdx = $body.IndexOf('>')
  if ($gtIdx -ge 0) { $body = $body.Substring($gtIdx + 1) }

  # strip old site nav blocks (Home | All Articles + breadcrumb)
  $body = [regex]::Replace($body, '<nav[^>]*>[\s\S]*?</nav>', '', 'IgnoreCase')
  # strip old footer block (contains duplicate copyright; keep nothing — related links + kit form are inside, but they use inline styles and duplicate BaseLayout footer)
  $body = [regex]::Replace($body, '<footer>[\s\S]*?</footer>', '', 'IgnoreCase')
  # strip gtag + related-articles scripts (BaseLayout handles GA; related links rebuilt by Astro)
  $body = [regex]::Replace($body, '<script[\s\S]*?</script>', '', 'IgnoreCase')
  # strip hidden Amazon pixel div
  $body = [regex]::Replace($body, '<div style="display:none;">[\s\S]*?</div>', '', 'IgnoreCase')
  # clean mojibake artifacts dY>' / dY`` / �+' etc
  $body = $body -replace [char]0xFFFD, '' -replace 'dY' + [char]0x203A, '' -replace [char]0x203A, ' &raquo; ' -replace '�\+', ''
  $body = $body.Trim()

  if ($body.Length -lt 50) { Write-Host "WARN short body: $slug ($($body.Length))" }

  [System.IO.File]::WriteAllBytes("$bodiesDir\$slug.html", $utf8.GetBytes($body))
  $meta[$slug] = @{ title = $title; desc = $desc; canonical = $canon }
  $cleaned += $slug
}

# inject client-side loader scripts into homepage body (article grid + search/pagination)
$indexBody = "$bodiesDir\index.html"
if (Test-Path $indexBody) {
  $ic = [System.IO.File]::ReadAllText($indexBody)
  if (-not $ic.Contains('dynamic-loader.js')) {
    $inject = '<script src="/articles-data.js"></script>' + [char]10 + '<script src="/dynamic-loader.js"></script>' + [char]10 + '</main>'
    $ic = $ic.Replace('</main>', $inject)
    [System.IO.File]::WriteAllBytes($indexBody, $utf8.GetBytes($ic))
    Write-Host "injected loader scripts into index body"
  }
}

# decode HTML entities in titles/descs (&#x1F30D; &mdash; &amp; etc) so Astro re-escapes once
$web = [System.Net.WebUtility]
foreach ($k in @($meta.Keys)) {
  $m = $meta[$k]
  # WebUtility::HtmlDecode does NOT decode hex numeric entities (&#x1F30D;) — handle manually first
  $m.title = [regex]::Replace($m.title, '&#x([0-9A-Fa-f]+);', { param($mm) [char]::ConvertFromUtf32([Convert]::ToInt32($mm.Groups[1].Value, 16)) })
  $m.desc = [regex]::Replace($m.desc, '&#x([0-9A-Fa-f]+);', { param($mm) [char]::ConvertFromUtf32([Convert]::ToInt32($mm.Groups[1].Value, 16)) })
  $m.title = $web::HtmlDecode($m.title)
  $m.desc = $web::HtmlDecode($m.desc)
  $meta[$k] = $m
}
Write-Host "`nExtracted bodies: $($cleaned.Count)"

# ---------------------------------------------------------------
# 2. Write meta.json (proper JSON serialization)
# ---------------------------------------------------------------
$obj = [ordered]@{}
foreach ($k in ($meta.Keys | Sort-Object)) { $obj[$k] = $meta[$k] }
$json = ConvertTo-Json $obj -Depth 4
[System.IO.File]::WriteAllBytes("$bodiesDir\meta.json", $utf8.GetBytes($json))
Write-Host "meta.json written: $($obj.Count) entries"

# ---------------------------------------------------------------
# 3. Generate per-slug article .astro pages
# ---------------------------------------------------------------
$skipPages = @('index', '404', 'about', 'all-articles', 'contact', 'privacy', 'disclaimer', 'checklist', 'store', 'thank-you')
$tpl = @'
---
import BaseLayout from '../layouts/BaseLayout.astro';
import CTA from '../components/CTA.astro';
import body from '../bodies/{SLUG}.html?raw';

const title = {TITLE_JSON};
const description = {DESC_JSON};
const canonical = {CANON_JSON};
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'Article',
  headline: title,
  description: description,
  url: canonical,
  mainEntityOfPage: { '@type': 'WebPage', '@id': canonical },
  publisher: { '@type': 'Organization', name: 'RemoteWorkHub' },
};
---

<BaseLayout title={title} description={description} canonical={canonical}>
  <script type="application/ld+json" set:html={JSON.stringify(jsonLd)} />
  <article class="mx-auto max-w-4xl px-4 py-8">
    <Fragment set:html={body} />
    <div class="mt-12 text-center">
      <CTA href="/all-articles" text="Browse More Articles" variant="secondary" />
    </div>
  </article>
</BaseLayout>
'@

$pageCount = 0
foreach ($slug in $cleaned) {
  if ($skipPages -contains $slug) { continue }
  $m = $meta[$slug]
  $content = $tpl.Replace('{SLUG}', $slug).Replace('{TITLE_JSON}', (ConvertTo-Json $m.title)).Replace('{DESC_JSON}', (ConvertTo-Json $m.desc)).Replace('{CANON_JSON}', (ConvertTo-Json ($m.canonical)))
  [System.IO.File]::WriteAllBytes("$pagesDir\$slug.astro", $utf8.GetBytes($content))
  $pageCount++
}
Write-Host "Generated article pages: $pageCount"

# ---------------------------------------------------------------
# 4. Generate special pages (use body set:html, no CTA wrapper)
# ---------------------------------------------------------------
$specialTpl = @'
---
import BaseLayout from '../layouts/BaseLayout.astro';
import body from '../bodies/{SLUG}.html?raw';

const title = {TITLE_JSON};
const description = {DESC_JSON};
const canonical = {CANON_JSON};
---

<BaseLayout title={title} description={description} canonical={canonical}>
  <div class="mx-auto max-w-4xl px-4 py-8">
    <Fragment set:html={body} />
  </div>
</BaseLayout>
'@

foreach ($slug in $skipPages) {
  $bfile = "$bodiesDir\$slug.html"
  if (-not (Test-Path $bfile)) { Write-Host "WARN no body for special page: $slug"; continue }
  $m = $meta[$slug]
  if (-not $m) { $m = @{ title = $slug; desc = ''; canonical = "https://remoteworkhub.net/$slug" } }
  $content = $specialTpl.Replace('{SLUG}', $slug).Replace('{TITLE_JSON}', (ConvertTo-Json $m.title)).Replace('{DESC_JSON}', (ConvertTo-Json $m.desc)).Replace('{CANON_JSON}', (ConvertTo-Json ($m.canonical)))
  [System.IO.File]::WriteAllBytes("$pagesDir\$slug.astro", $utf8.GetBytes($content))
  Write-Host "special page: $slug.astro"
}

Write-Host "`nDONE. bodies=$($cleaned.Count) pages=$($pageCount + $skipPages.Count)"
