#!/usr/bin/env python3
import re, os
with open('articles-data.js', encoding='utf-8', errors='replace') as f:
    content = f.read()

slugs = re.findall(r'slug:\s*"([^"]+)"', content)
titles = re.findall(r'title:\s*"([^"]+)"', content)
cats = re.findall(r'category:\s*"([^"]+)"', content)
unique_cats = sorted(set(cats))

html_files = []
for f in os.listdir('.'):
    if f.endswith('.html') and os.path.isfile(f):
        html_files.append(f)

print(f"Articles in data file: {len(slugs)}")
print(f"HTML files: {len(html_files)}")
print(f"Categories: {unique_cats}")

data_slugs = set(slugs)
html_slugs = {f.replace('.html', '') for f in html_files}
print(f"Matching data+HTML: {len(data_slugs & html_slugs)}")

if slugs:
    print(f"\nFirst article:")
    print(f"  title: {titles[0]}")
    print(f"  slug: {slugs[0]}")
    print(f"  cat: {cats[0]}")
