#!/usr/bin/env python3
"""cebindeneve.com statik sayfalarını üretir.

site/pages/*.html dosyalarının başındaki yorum bloğu meta veridir:

    <!--
    title: Sayfa başlığı
    description: Arama sonuçlarında görünen açıklama
    path: rehber/ornek          (URL yolu; ana sayfa için boş)
    type: article | page        (article → rehber listesine girer)
    date: 2026-10-26
    order: 1                    (rehber listesindeki sıra)
    -->

Gövdede `<!-- ad -->` geçen yere makale içi reklam birimi yerleşir.
Çıktı: public/ (Flutter uygulaması ayrıca public/hesapla altına kopyalanır).
"""

import html
import json
import re
import shutil
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "site"
OUT = ROOT / "public"
SITE = "https://cebindeneve.com"
AD_CLIENT = "ca-pub-8974319907510791"
AD_SLOT_IN_ARTICLE = "9925564196"

MONTHS = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
]


def tr_date(iso: str) -> str:
    d = date.fromisoformat(iso)
    return f"{d.day} {MONTHS[d.month - 1]} {d.year}"


def parse(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    m = re.match(r"\s*<!--(.*?)-->\s*", text, re.S)
    if not m:
        sys.exit(f"{path.name}: meta blok yok")
    meta = {}
    for line in m.group(1).strip().splitlines():
        key, _, value = line.partition(":")
        meta[key.strip()] = value.strip()
    meta["body"] = text[m.end():]
    meta["path"] = meta.get("path", "")
    meta["type"] = meta.get("type", "page")
    return meta


def url(path: str) -> str:
    return f"{SITE}/{path}" if path else f"{SITE}/"


AD_UNIT = f"""
<div class="ad-slot" aria-label="Reklam">
  <ins class="adsbygoogle" style="display:block; text-align:center;"
       data-ad-layout="in-article" data-ad-format="fluid"
       data-ad-client="{AD_CLIENT}" data-ad-slot="{AD_SLOT_IN_ARTICLE}"></ins>
  <script>(adsbygoogle = window.adsbygoogle || []).push({{}});</script>
</div>
"""

NAV = [
    ("", "Ana sayfa"),
    ("rehber", "Rehberler"),
    ("hakkimizda", "Hakkımızda"),
    ("iletisim", "İletişim"),
]


def layout(page: dict, articles: list) -> str:
    title = page["title"]
    full_title = title if page["path"] == "" else f"{title} | Cebinden Eve"
    desc = page.get("description", "")
    canonical = url(page["path"])
    is_article = page["type"] == "article"
    main_class = "home" if page["path"] == "" else ("article" if is_article else "page")

    body = page["body"]
    body = body.replace("<!-- ad -->", AD_UNIT)
    body = body.replace("<!-- rehber-listesi -->", article_cards(articles))
    body = body.replace(
        "<!-- son-rehberler -->", article_cards(articles[:3], compact=True)
    )

    def nav_link(p: str, label: str) -> str:
        current = p == page["path"] or (p and page["path"].startswith(p + "/"))
        attr = ' aria-current="page"' if current else ""
        return f'<a href="/{p}"{attr}>{label}</a>'

    nav = "\n".join(nav_link(p, label) for p, label in NAV)

    jsonld = {
        "@context": "https://schema.org",
        "@type": "Article" if is_article else "WebPage",
        "headline" if is_article else "name": title,
        "description": desc,
        "url": canonical,
        "inLanguage": "tr-TR",
        "publisher": {
            "@type": "Organization",
            "name": "Cebinden Eve",
            "url": SITE,
            "logo": f"{SITE}/img/logo.png",
        },
    }
    if is_article:
        jsonld["datePublished"] = page["date"]
        jsonld["dateModified"] = page.get("updated", page["date"])
        jsonld["author"] = {"@type": "Organization", "name": "Cebinden Eve"}

    article_head = ""
    article_foot = ""
    if is_article:
        words = len(re.sub(r"<[^>]+>", " ", body).split())
        minutes = max(1, round(words / 200))
        updated = page.get("updated", page["date"])
        article_head = f"""
<p class="crumbs"><a href="/">Ana sayfa</a> › <a href="/rehber">Rehberler</a></p>
<h1>{html.escape(title)}</h1>
<p class="meta">Güncelleme: {tr_date(updated)} · {minutes} dk okuma · Cebinden Eve Editör Ekibi</p>
"""
        others = [a for a in articles if a["path"] != page["path"]][:3]
        article_foot = f"""
<aside class="cta">
  <h2>Kendi rakamlarınla hesapla</h2>
  <p>İlan fiyatını ve birikimini gir; tapu harcı, komisyon, kredi taksitleri ve tüm ek masraflarla evin
  sana gerçek maliyetini saniyeler içinde gör. Ücretsiz, kayıt gerekmez.</p>
  <a class="button" href="/hesapla/">Hesaplayıcıyı aç</a>
</aside>
<p class="disclaimer">Bu yazı genel bilgilendirme amaçlıdır; yatırım, hukuk veya vergi danışmanlığı değildir.
Oranlar ve ücretler değişebilir. Karar vermeden önce bankanızdan, tapu müdürlüğünden ve ilgili kurumlardan
güncel bilgi alın.</p>
<section class="related">
  <h2>Diğer rehberler</h2>
  {article_cards(others, compact=True)}
</section>
"""

    return f"""<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{html.escape(full_title)}</title>
  <meta name="description" content="{html.escape(desc)}">
  <link rel="canonical" href="{canonical}">
  <meta property="og:type" content="{'article' if is_article else 'website'}">
  <meta property="og:title" content="{html.escape(title)}">
  <meta property="og:description" content="{html.escape(desc)}">
  <meta property="og:url" content="{canonical}">
  <meta property="og:image" content="{SITE}/img/logo.png">
  <meta property="og:locale" content="tr_TR">
  <meta name="google-adsense-account" content="{AD_CLIENT}">
  <link rel="icon" type="image/png" href="/favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600&family=Outfit:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/site.css">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={AD_CLIENT}" crossorigin="anonymous"></script>
  <script type="application/ld+json">{json.dumps(jsonld, ensure_ascii=False)}</script>
</head>
<body>
<header class="site-header">
  <div class="wrap">
    <a class="brand" href="/"><img src="/img/logo.png" alt="" width="40" height="40"><span>Cebinden Eve</span></a>
    <nav class="site-nav">{nav}</nav>
    <a class="button small" href="/hesapla/">Hesapla</a>
  </div>
</header>
<main class="wrap {main_class}">
{article_head}
{body}
{article_foot}
</main>
<footer class="site-footer">
  <div class="wrap">
    <div>
      <strong>Cebinden Eve</strong>
      <p>İlandaki fiyatı değil, evin gerçek maliyetini hesaplayın.</p>
    </div>
    <nav>
      <a href="/hesapla/">Hesaplayıcı</a>
      <a href="/rehber">Rehberler</a>
      <a href="/hakkimizda">Hakkımızda</a>
      <a href="/iletisim">İletişim</a>
      <a href="/destek">Destek</a>
      <a href="/gizlilik">Gizlilik Politikası</a>
      <a href="/kosullar">Kullanım Koşulları</a>
    </nav>
    <p class="copy">© {date.today().year} Cebinden Eve · <a href="mailto:info@cebindeneve.com">info@cebindeneve.com</a></p>
  </div>
</footer>
</body>
</html>
"""


def article_cards(articles: list, compact: bool = False) -> str:
    items = []
    for a in articles:
        items.append(
            f"""<a class="card-link" href="/{a['path']}">
  <h3>{html.escape(a['title'])}</h3>
  {'' if compact else f"<p>{html.escape(a.get('description', ''))}</p>"}
  <span class="more">Okumaya devam et →</span>
</a>"""
        )
    return f'<div class="cards">{"".join(items)}</div>'


def main() -> None:
    pages = [parse(p) for p in sorted((SRC / "pages").glob("*.html"))]
    articles = sorted(
        (p for p in pages if p["type"] == "article"),
        key=lambda p: int(p.get("order", 99)),
    )

    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC / "static", OUT)

    for page in pages:
        target = OUT / (page["path"] + ".html" if page["path"] else "index.html")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(layout(page, articles), encoding="utf-8")

    today = date.today().isoformat()
    entries = []
    for page in pages:
        if page.get("sitemap") == "no":
            continue
        lastmod = page.get("updated", page.get("date", today))
        entries.append(
            f"  <url><loc>{url(page['path'])}</loc><lastmod>{lastmod}</lastmod></url>"
        )
    entries.append(f"  <url><loc>{SITE}/hesapla/</loc><lastmod>{today}</lastmod></url>")
    (OUT / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "\n".join(entries)
        + "\n</urlset>\n",
        encoding="utf-8",
    )
    print(f"{len(pages)} sayfa, {len(articles)} rehber → {OUT.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
