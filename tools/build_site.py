#!/usr/bin/env python3
"""cebindeneve.com statik sayfalarını üretir.

site/pages/*.html dosyalarının başındaki yorum bloğu meta veridir:

    <!--
    title: Sayfa başlığı
    description: Arama sonuçlarında görünen açıklama
    path: rehber/ornek          (URL yolu; ana sayfa için boş)
    type: article | page        (article → rehber listesine girer)
    category: masraflar | kredi | surec   (rehber sayfasındaki grup)
    date: 2026-10-26
    updated: 2026-11-06         (isteğe bağlı)
    order: 1                    (rehber listesindeki sıra)
    sitemap: no                 (isteğe bağlı; site haritasına girmez)
    -->

Gövdedeki yer tutucular:
    <!-- ad -->                 makale içi reklam birimi
    <!-- calc:tapu -->          etkileşimli hesaplama aracı (calc.js)
    <!-- rehber-listesi -->     kategorilere göre tüm rehberler
    <!-- rehber-one-cikan -->   ilk 6 rehber
    <!-- son-rehberler -->      ilk 3 rehber (kompakt)

Çıktı: public/ (Flutter uygulaması ayrıca public/hesapla altına kopyalanır).
"""

import html
import json
import re
import shutil
import sys
from datetime import date, datetime, timezone
from email.utils import format_datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "site"
OUT = ROOT / "public"
SITE = "https://cebindeneve.com"
SITE_NAME = "Cebinden Eve"
AD_CLIENT = "ca-pub-8974319907510791"
AD_SLOT_IN_ARTICLE = "9925564196"

# Rehberlerin yazarı. Hakkımızda sayfasındaki kısa biyografiyle uyumlu tutun.
AUTHOR_NAME = "Fatih Anılır"
AUTHOR_URL = f"{SITE}/hakkimizda#yazar"

CATEGORIES = [
    ("masraflar", "Masraflar, vergiler ve tapu"),
    ("kredi", "Konut kredisi"),
    ("surec", "Süreç, karar ve planlama"),
]

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
    meta["file"] = path.name
    if meta["type"] == "article" and "category" not in meta:
        sys.exit(f"{path.name}: article için category gerekli")
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
    ("araclar", "Araçlar"),
    ("hakkimizda", "Hakkımızda"),
    ("iletisim", "İletişim"),
]

# Diğer Firebase alan adlarından ana alan adına yönlendirme (çift içerik önlenir).
HOST_REDIRECT = """<script>(function(){var h=location.hostname;if(h.indexOf('web.app')>-1||h.indexOf('firebaseapp.com')>-1||h==='www.cebindeneve.com'){location.replace('https://cebindeneve.com'+location.pathname+location.search+location.hash);}})();</script>"""


# ---------------------------------------------------------------------------
# Hesaplama araçları (sunucu tarafında form, mantık calc.js'te)
# ---------------------------------------------------------------------------

def _field(id_: str, label: str, inp: str, wide: bool = False) -> str:
    cls = ' class="wide"' if wide else ""
    return f'<label for="{id_}"{cls}><span>{label}</span>{inp}</label>'


def _num(id_: str, value, step="1", min_="0", money: bool = False):
    if money:
        shown = f"{int(round(float(value))):,}".replace(",", ".")
        return (f'<input type="text" inputmode="decimal" id="{id_}" name="{id_}" '
                f'value="{shown}" data-fmt="money" autocomplete="off">')
    return (f'<input type="number" id="{id_}" name="{id_}" value="{value}" '
            f'step="{step}" min="{min_}" inputmode="decimal">')


def _select(id_: str, options: list) -> str:
    opts = "".join(
        f'<option value="{v}"{" selected" if i == 0 else ""}>{html.escape(t)}</option>'
        for i, (v, t) in enumerate(options)
    )
    return f'<select id="{id_}" name="{id_}">{opts}</select>'


KATSAYI_OPTS = [
    ("2.5", "2,50 büyükşehir"),
    ("2", "2,00 il merkezi"),
    ("1.5", "1,50 ilçe"),
    ("1", "1,00 küçük ilçe"),
    ("0.5", "0,50 en düşük"),
]

CALCS = {
    "toplam": {
        "title": "Ev alım maliyeti hesaplayıcı",
        "intro": "İlan fiyatını ve birikiminizi girin; tapu harcı, komisyon, döner sermaye ve kredi taksitiyle gerçek maliyeti görün.",
        "fields": [
            _field("t-fiyat", "Ev fiyatı", _num("t-fiyat", 5000000, money=True)),
            _field("t-nakit", "Nakit", _num("t-nakit", 2500000, money=True)),
            _field("t-harc", "Tapu harcı", _select("t-harc", [("0.04", "%4 alıcı öder"), ("0.02", "%2 alıcı payı")])),
            _field("t-komisyon", "Komisyon", _select("t-komisyon", [("0.024", "%2 + KDV"), ("0", "Yok")])),
            _field("t-katsayi", "Yöresel katsayı", _select("t-katsayi", KATSAYI_OPTS), wide=True),
            _field("t-ek", "Diğer masraflar", _num("t-ek", 25000, money=True), wide=True),
            _field("t-faiz", "Aylık faiz (%)", _num("t-faiz", 2.79, step="0.01")),
            _field("t-vade", "Vade (ay)", _num("t-vade", 120, step="1", min_="1")),
        ],
        "results": [
            ("t-r-harc", "Tapu harcı"), ("t-r-komisyon", "Emlakçı komisyonu"),
            ("t-r-doner", "Döner sermaye"), ("t-r-toplam", "Gerçek maliyet"),
            ("t-r-kredi", "Kredi ihtiyacı"), ("t-r-taksit", "Aylık taksit"),
            ("t-r-geri", "Toplam geri ödeme"),
        ],
        "note": "Döner sermaye 2026 TKGM tarifesine göre (2.227 TL × katsayı) hesaplanır; kredi gerekiyorsa ipotek için ikinci kez eklenir. Taksit, eşit taksitli kredi formülüyle bulunur.",
        "primary": ("t-r-toplam", "t-r-taksit"),
    },
    "tapu": {
        "title": "Tapu harcı hesaplama",
        "intro": "Satış bedelini girin; alıcı ve satıcı paylarını ve toplam harcı görün.",
        "fields": [
            _field("h-bedel", "Satış bedeli", _num("h-bedel", 5000000, money=True)),
            _field("h-katsayi", "Yöresel katsayı", _select("h-katsayi", KATSAYI_OPTS)),
        ],
        "results": [
            ("h-r-alici", "Alıcı payı (%2)"), ("h-r-satici", "Satıcı payı (%2)"),
            ("h-r-toplam", "Toplam harç (%4)"), ("h-r-doner", "Döner sermaye (satış)"),
            ("h-r-alici-toplam", "Tamamını alıcı öderse tapuda ödenecek"),
        ],
        "note": "Oranlar 492 sayılı Harçlar Kanunu (4) sayılı tarifeye göre binde 20 + binde 20'dir. Döner sermaye 2026 göstergesi 2.227 TL'dir.",
        "primary": ("h-r-toplam",),
    },
    "komisyon": {
        "title": "Emlakçı komisyonu hesaplama",
        "intro": "Satış bedeli ve anlaştığınız oranı girin; KDV dahil komisyonu görün.",
        "fields": [
            _field("k-bedel", "Satış bedeli", _num("k-bedel", 5000000, money=True)),
            _field("k-oran", "Hizmet bedeli oranı (%) – yasal üst sınır 2", _num("k-oran", 2, step="0.1")),
        ],
        "results": [
            ("k-r-net", "Hizmet bedeli"), ("k-r-kdv", "KDV (%20)"), ("k-r-toplam", "Ödenecek toplam"),
        ],
        "note": "Taşınmaz Ticareti Hakkında Yönetmelik'e göre alıcı ve satıcıdan ayrı ayrı en fazla %2 alınabilir; KDV ayrıca eklenir.",
        "primary": ("k-r-toplam",),
    },
    "kredi": {
        "title": "Konut kredisi taksit hesaplama",
        "intro": "Kredi tutarı, aylık faiz ve vadeyi girin; taksit, toplam geri ödeme ve toplam faizi görün.",
        "fields": [
            _field("c-tutar", "Kredi tutarı", _num("c-tutar", 2500000, money=True)),
            _field("c-faiz", "Aylık faiz oranı (%)", _num("c-faiz", 2.79, step="0.01")),
            _field("c-vade", "Vade (ay)", _num("c-vade", 120, step="1", min_="1")),
        ],
        "results": [
            ("c-r-taksit", "Aylık taksit"), ("c-r-geri", "Toplam geri ödeme"),
            ("c-r-faiz", "Toplam faiz"), ("c-r-ilk", "İlk taksitteki faiz payı"),
            ("c-r-yillik", "Yıllık maliyet (bileşik)"),
        ],
        "note": "Konut kredilerinde KKDF ve BSMV alınmaz; hesap bankaların eşit taksitli ödeme planıyla aynı formülü kullanır. Tahsis ücreti ve sigortalar dahil değildir.",
        "primary": ("c-r-taksit",),
    },
    "doner": {
        "title": "Tapu döner sermaye ücreti hesaplama",
        "intro": "İlçenizin yöresel katsayısını seçin; satış ve ipotek işlemleri için ödenecek döner sermaye ücretini görün.",
        "fields": [
            _field("d-katsayi", "Yöresel katsayı", _select("d-katsayi", KATSAYI_OPTS)),
            _field("d-ipotek", "Konut kredisi (ipotek) var mı?", _select("d-ipotek", [("1", "Evet – satış + ipotek"), ("0", "Hayır – yalnızca satış")])),
        ],
        "results": [
            ("d-r-islem", "Bir işlem ücreti"), ("d-r-toplam", "Toplam döner sermaye"),
        ],
        "note": "2026 tarifesi: işlem ücreti = 2.227 TL × yöresel katsayı (KDV dahil). Satış ve ipotek tek talepte yapıldığında iki işlem ücreti alınır. Kesin katsayı için TKGM listesine bakın.",
        "primary": ("d-r-toplam",),
    },
    "erken": {
        "title": "Erken kapama tazminatı hesaplama",
        "intro": "Erken ödeyeceğiniz anaparayı ve kalan vadeyi girin; bankanın isteyebileceği en yüksek tazminatı görün.",
        "fields": [
            _field("e-anapara", "Erken ödenecek anapara", _num("e-anapara", 1000000, money=True)),
            _field("e-vade", "Kalan vade (ay)", _num("e-vade", 60, step="1", min_="1")),
        ],
        "results": [
            ("e-r-oran", "Uygulanacak üst sınır"), ("e-r-tutar", "Azami tazminat"),
        ],
        "note": "6502 sayılı Kanun m.37: sabit faizli kredide kalan vade 36 ayı aşmıyorsa %1, aşıyorsa %2 üst sınır; tutar faiz indirimini aşamaz. Değişken faizli kredide tazminat alınmaz.",
        "primary": ("e-r-tutar",),
    },
    "dask": {
        "title": "DASK sigorta bedeli hesaplama",
        "intro": "Evin brüt alanını ve yapı tarzını girin; zorunlu deprem sigortası teminat tutarını görün.",
        "fields": [
            _field("s-m2", "Brüt alan (m²)", _num("s-m2", 120, step="1", min_="1")),
            _field("s-yapi", "Yapı tarzı", _select("s-yapi", [("12288", "Betonarme"), ("8192", "Diğer (yığma, ahşap vb.)")])),
        ],
        "results": [
            ("s-r-bedel", "Sigorta bedeli (teminat)"), ("s-r-not", "Azami teminat uygulandı mı?"),
        ],
        "note": "Kasım 2026 DASK tarifesi: betonarme 12.288 TL/m², diğer 8.192 TL/m², azami teminat 2.605.100 TL. Prim; risk bölgesi, bina yaşı ve kat sayısına göre ayrıca hesaplanır.",
        "primary": ("s-r-bedel",),
    },
    "kdv": {
        "title": "Sıfır konut KDV hesaplama",
        "intro": "Müteahhitten alınan konutun net alanı ve bedeline göre KDV'yi hesaplayın (ruhsatı 1 Nisan 2022 sonrası projeler).",
        "fields": [
            _field("v-bedel", "KDV hariç bedel", _num("v-bedel", 6000000, money=True)),
            _field("v-m2", "Net alan (m²)", _num("v-m2", 120, step="1", min_="1")),
            _field("v-tur", "Proje türü", _select("v-tur", [("0.10", "Normal proje – 150 m²'ye kadar %10"), ("0.01", "6306 sayılı Kanun kapsamında dönüşüm – %1")])),
        ],
        "results": [
            ("v-r-kdv", "KDV"), ("v-r-toplam", "KDV dahil bedel"), ("v-r-oran", "Efektif oran"),
        ],
        "note": "Net alanın 150 m²'yi aşan kısmına isabet eden bedel %20 KDV'ye tabidir. Ruhsatı 1 Nisan 2022 öncesi projelerde oran farklı olabilir; satıcıdan yazılı bilgi isteyin.",
        "primary": ("v-r-toplam",),
    },
    "ltv": {
        "title": "Azami konut kredisi tutarı hesaplama",
        "intro": "Ekspertiz değeri ve enerji sınıfını girin; BDDK kurallarına göre bankanın verebileceği en yüksek krediyi görün.",
        "fields": [
            _field("l-deger", "Ekspertiz değeri", _num("l-deger", 5000000, money=True)),
            _field("l-enerji", "Enerji kimlik belgesi sınıfı", _select("l-enerji", [("ab", "A veya B"), ("c", "C"), ("d", "D ve altı / belgesiz")])),
            _field("l-ilk", "Üzerinize kayıtlı başka konut var mı?", _select("l-ilk", [("1", "Hayır – ilk konutum"), ("0.25", "Evet – oran %75 azaltılır")])),
        ],
        "results": [
            ("l-r-oran", "Azami kredi/değer oranı"), ("l-r-kredi", "Azami kredi"), ("l-r-pesinat", "En az peşinat"),
        ],
        "note": "BDDK'nın 29.01.2026 tarihli 11364 sayılı kararına göre. Banka; gelir, kredi notu ve kendi politikası nedeniyle daha düşük tutar verebilir.",
        "primary": ("l-r-kredi",),
    },
}


def calc_html(kind: str) -> str:
    c = CALCS[kind]
    fields = "\n".join(c["fields"])
    primary = set(c.get("primary", ()))

    def rows(items, cls=""):
        extra = f" {cls}" if cls else ""
        return "\n".join(
            f'<div class="calc-row{" primary" if rid in primary else ""}{extra}">'
            f'<span>{html.escape(label)}</span><output id="{rid}">–</output></div>'
            for rid, label in items
        )

    hi = [(r, l) for r, l in c["results"] if r in primary]
    lo = [(r, l) for r, l in c["results"] if r not in primary]
    breakdown = f'<div class="calc-breakdown">{rows(lo)}</div>' if lo else ""
    return f"""
<section class="calc" data-calc="{kind}" aria-labelledby="calc-{kind}-title">
  <div class="calc-highlight" aria-live="polite">
    <p class="calc-results-title">Sonuç</p>
    {rows(hi)}
  </div>
  <div class="calc-body">
    <h3 id="calc-{kind}-title">{html.escape(c['title'])}</h3>
    <p class="calc-intro">{html.escape(c['intro'])}</p>
    <form class="calc-form" autocomplete="off">
      {fields}
    </form>
    <p class="calc-note">{html.escape(c['note'])}</p>
    <noscript><p class="calc-note">Hesaplama aracı için JavaScript gereklidir.</p></noscript>
  </div>
  {breakdown}
</section>
"""


# ---------------------------------------------------------------------------
# Sayfa düzeni
# ---------------------------------------------------------------------------

def faq_items(body: str) -> list:
    items = []
    for m in re.finditer(r"<details>\s*<summary>(.*?)</summary>(.*?)</details>", body, re.S):
        q = re.sub(r"<[^>]+>", "", m.group(1)).strip()
        a = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", m.group(2))).strip()
        if q and a:
            items.append((html.unescape(q), html.unescape(a)))
    return items


def layout(page: dict, articles: list) -> str:
    title = page["title"]
    full_title = title if page["path"] == "" else f"{title} | {SITE_NAME}"
    desc = page.get("description", "")
    canonical = url(page["path"])
    is_article = page["type"] == "article"
    main_class = "home" if page["path"] == "" else ("article" if is_article else "page")

    body = page["body"]
    body = body.replace("<!-- ad -->", AD_UNIT)
    body = body.replace("<!-- rehber-listesi -->", article_sections(articles))
    body = body.replace("<!-- rehber-one-cikan -->", article_cards(articles[:6]))
    body = body.replace("<!-- son-rehberler -->", article_cards(articles[:3], compact=True))
    uses_calc = False
    for kind in CALCS:
        marker = f"<!-- calc:{kind} -->"
        if marker in body:
            body = body.replace(marker, calc_html(kind))
            uses_calc = True

    def nav_link(p: str, label: str) -> str:
        current = p == page["path"] or (p and page["path"].startswith(p + "/"))
        attr = ' aria-current="page"' if current else ""
        return f'<a href="/{p}"{attr}>{label}</a>'

    nav = "\n".join(nav_link(p, label) for p, label in NAV)

    publisher = {
        "@type": "Organization",
        "name": SITE_NAME,
        "url": SITE,
        "logo": {"@type": "ImageObject", "url": f"{SITE}/img/logo.png"},
    }
    main_ld = {
        "@context": "https://schema.org",
        "@type": "Article" if is_article else "WebPage",
        "headline" if is_article else "name": title,
        "description": desc,
        "url": canonical,
        "inLanguage": "tr-TR",
        "isPartOf": {"@type": "WebSite", "name": SITE_NAME, "url": SITE},
        "publisher": publisher,
    }
    if is_article:
        main_ld["mainEntityOfPage"] = canonical
        main_ld["datePublished"] = page["date"]
        main_ld["dateModified"] = page.get("updated", page["date"])
        main_ld["author"] = {"@type": "Person", "name": AUTHOR_NAME, "url": AUTHOR_URL}
        main_ld["image"] = f"{SITE}/img/logo.png"
    ld_blocks = [main_ld]

    if page["path"]:
        crumbs = [{"@type": "ListItem", "position": 1, "name": "Ana sayfa", "item": SITE + "/"}]
        if is_article:
            crumbs.append({"@type": "ListItem", "position": 2, "name": "Rehberler", "item": f"{SITE}/rehber"})
        crumbs.append({"@type": "ListItem", "position": len(crumbs) + 1, "name": title, "item": canonical})
        ld_blocks.append({"@context": "https://schema.org", "@type": "BreadcrumbList", "itemListElement": crumbs})

    faqs = faq_items(body)
    if faqs:
        ld_blocks.append({
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": [
                {"@type": "Question", "name": q,
                 "acceptedAnswer": {"@type": "Answer", "text": a}}
                for q, a in faqs
            ],
        })
    if page["path"] == "":
        ld_blocks.append({
            "@context": "https://schema.org",
            "@type": "WebSite",
            "name": SITE_NAME,
            "url": SITE,
            "inLanguage": "tr-TR",
            "publisher": publisher,
        })
    jsonld = "\n".join(
        f'<script type="application/ld+json">{json.dumps(b, ensure_ascii=False)}</script>'
        for b in ld_blocks
    )

    article_head = ""
    article_foot = ""
    if is_article:
        words = len(re.sub(r"<[^>]+>", " ", body).split())
        minutes = max(1, round(words / 200))
        updated = page.get("updated", page["date"])
        cat_label = dict(CATEGORIES).get(page["category"], "")
        article_head = f"""
<p class="crumbs"><a href="/">Ana sayfa</a> › <a href="/rehber">Rehberler</a> › <a href="/rehber#{page['category']}">{html.escape(cat_label)}</a></p>
<h1>{html.escape(title)}</h1>
<p class="meta">Yazar: <a href="/hakkimizda#yazar">{AUTHOR_NAME}</a> · Yayın: {tr_date(page['date'])} · Güncelleme: {tr_date(updated)} · {minutes} dk okuma</p>
"""
        same_cat = [a for a in articles if a["path"] != page["path"] and a["category"] == page["category"]]
        other_cat = [a for a in articles if a["path"] != page["path"] and a["category"] != page["category"]]
        others = (same_cat + other_cat)[:3]
        article_foot = f"""
<aside class="cta">
  <h2>Kendi rakamlarınla hesapla</h2>
  <p>İlan fiyatını ve birikimini gir; tapu harcı, komisyon, kredi taksitleri ve tüm ek masraflarla evin
  sana gerçek maliyetini saniyeler içinde gör. Ücretsiz, kayıt gerekmez.</p>
  <a class="button" href="/hesapla/">Hesaplayıcıyı aç</a>
</aside>
<p class="disclaimer">Bu yazı genel bilgilendirme amaçlıdır; yatırım, hukuk veya vergi danışmanlığı değildir.
Oranlar ve ücretler değişebilir. Karar vermeden önce bankanızdan, tapu müdürlüğünden ve ilgili kurumlardan
güncel bilgi alın. Bir hata fark ederseniz <a href="/iletisim">bize yazın</a>.</p>
<section class="related">
  <h2>Diğer rehberler</h2>
  {article_cards(others, compact=True)}
</section>
"""

    calc_script = '<script defer src="/calc.js"></script>' if uses_calc else ""
    og_type = "article" if is_article else "website"

    return f"""<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  {HOST_REDIRECT}
  <title>{html.escape(full_title)}</title>
  <meta name="description" content="{html.escape(desc)}">
  <meta name="author" content="{AUTHOR_NAME}">
  <link rel="canonical" href="{canonical}">
  <link rel="alternate" type="application/rss+xml" title="{SITE_NAME} rehberleri" href="{SITE}/feed.xml">
  <meta property="og:site_name" content="{SITE_NAME}">
  <meta property="og:type" content="{og_type}">
  <meta property="og:title" content="{html.escape(title)}">
  <meta property="og:description" content="{html.escape(desc)}">
  <meta property="og:url" content="{canonical}">
  <meta property="og:image" content="{SITE}/img/logo.png">
  <meta property="og:locale" content="tr_TR">
  <meta name="twitter:card" content="summary">
  <meta name="google-adsense-account" content="{AD_CLIENT}">
  <link rel="icon" type="image/png" href="/favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600&family=Outfit:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/site.css">
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={AD_CLIENT}" crossorigin="anonymous"></script>
  {calc_script}
  {jsonld}
</head>
<body>
<header class="site-header">
  <div class="wrap">
    <a class="brand" href="/"><img src="/img/logo.png" alt="" width="40" height="40"><span>{SITE_NAME}</span></a>
    <nav class="site-nav" aria-label="Site">{nav}</nav>
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
      <strong>{SITE_NAME}</strong>
      <p>İlandaki fiyatı değil, evin gerçek maliyetini hesaplayın.</p>
    </div>
    <nav aria-label="Alt bilgi">
      <a href="/hesapla/">Hesaplayıcı</a>
      <a href="/rehber">Rehberler</a>
      <a href="/araclar">Araçlar</a>
      <a href="/hakkimizda">Hakkımızda</a>
      <a href="/iletisim">İletişim</a>
      <a href="/destek">Destek</a>
      <a href="/gizlilik">Gizlilik Politikası</a>
      <a href="/kosullar">Kullanım Koşulları</a>
      <a href="/feed.xml">RSS</a>
    </nav>
    <p class="copy">© {date.today().year} {SITE_NAME} · <a href="mailto:info@cebindeneve.com">info@cebindeneve.com</a></p>
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


def article_sections(articles: list) -> str:
    out = []
    for key, label in CATEGORIES:
        group = [a for a in articles if a["category"] == key]
        if not group:
            continue
        out.append(f'<h2 id="{key}">{html.escape(label)}</h2>')
        out.append(article_cards(group))
    return "\n".join(out)


def rss(articles: list) -> str:
    items = []
    for a in sorted(articles, key=lambda p: p.get("updated", p["date"]), reverse=True):
        d = datetime.fromisoformat(a.get("updated", a["date"])).replace(tzinfo=timezone.utc)
        items.append(f"""  <item>
    <title>{html.escape(a['title'])}</title>
    <link>{url(a['path'])}</link>
    <guid>{url(a['path'])}</guid>
    <pubDate>{format_datetime(d)}</pubDate>
    <description>{html.escape(a.get('description', ''))}</description>
  </item>""")
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
  <title>{SITE_NAME} – Ev alım rehberleri</title>
  <link>{SITE}/rehber</link>
  <description>Tapu harcı, konut kredisi ve ev alım masrafları üzerine rehberler.</description>
  <language>tr</language>
{chr(10).join(items)}
</channel>
</rss>
"""


def main() -> None:
    pages = [parse(p) for p in sorted((SRC / "pages").glob("*.html"))]
    articles = sorted(
        (p for p in pages if p["type"] == "article"),
        key=lambda p: int(p.get("order", 99)),
    )
    seen = set()
    for p in pages:
        if p["path"] in seen:
            sys.exit(f"{p['file']}: aynı path birden fazla sayfada: {p['path']}")
        seen.add(p["path"])

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
    (OUT / "sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "\n".join(entries)
        + "\n</urlset>\n",
        encoding="utf-8",
    )
    (OUT / "feed.xml").write_text(rss(articles), encoding="utf-8")
    words = sum(len(re.sub(r"<[^>]+>", " ", a["body"]).split()) for a in articles)
    print(f"{len(pages)} sayfa, {len(articles)} rehber ({words} kelime) → {OUT.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
