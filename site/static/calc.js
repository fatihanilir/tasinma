/* cebindeneve.com – sayfa içi hesaplama araçları. Bağımlılık yok. */
(function () {
  'use strict';

  var TL = new Intl.NumberFormat('tr-TR', { maximumFractionDigits: 0 });
  var TL2 = new Intl.NumberFormat('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  var PCT = new Intl.NumberFormat('tr-TR', { maximumFractionDigits: 2 });

  var DONER_GOSTERGE = 2227;        // TKGM 2026 gösterge (TL)
  var DASK_MAX = 2605100;           // DASK azami teminat, Kasım 2026 (TL)
  var KDV = 0.20;

  function tl(v) { return isFinite(v) ? TL.format(Math.round(v)) + ' TL' : '–'; }
  function tl2(v) { return isFinite(v) ? TL2.format(v) + ' TL' : '–'; }
  function pct(v) { return isFinite(v) ? '%' + PCT.format(v) : '–'; }

  function val(root, id) {
    var el = root.querySelector('#' + id);
    if (!el) return 0;
    var v = parseFloat(String(el.value).replace(',', '.'));
    return isFinite(v) ? v : 0;
  }
  function set(root, id, text) {
    var el = root.querySelector('#' + id);
    if (el) el.textContent = text;
  }

  /** Eşit taksitli kredi: aylık taksit. r aylık oran (0.0279 gibi), n ay. */
  function annuity(P, r, n) {
    if (P <= 0 || n <= 0) return 0;
    if (r === 0) return P / n;
    var f = Math.pow(1 + r, n);
    return P * r * f / (f - 1);
  }

  function roundDoner(v) {
    // Tarife: küsuratlar yuvarlanır (en yakın 0,50 TL'ye yuvarlıyoruz; nihai tahakkuk TKGM'ye aittir).
    return Math.round(v * 2) / 2;
  }

  var calcs = {
    toplam: function (root) {
      var fiyat = val(root, 't-fiyat');
      var nakit = val(root, 't-nakit');
      var harcOran = val(root, 't-harc');
      var komOran = val(root, 't-komisyon');
      var katsayi = val(root, 't-katsayi');
      var ek = val(root, 't-ek');
      var r = val(root, 't-faiz') / 100;
      var n = Math.round(val(root, 't-vade'));

      var harc = fiyat * harcOran;
      var kom = fiyat * komOran;
      var islem = roundDoner(DONER_GOSTERGE * katsayi);
      var araToplam = fiyat + harc + kom + islem + ek;
      var kredi = Math.max(0, araToplam - nakit);
      var doner = kredi > 0 ? islem * 2 : islem;
      var toplam = fiyat + harc + kom + doner + ek;
      kredi = Math.max(0, toplam - nakit);
      var taksit = annuity(kredi, r, n);

      set(root, 't-r-harc', tl(harc));
      set(root, 't-r-komisyon', tl(kom));
      set(root, 't-r-doner', tl2(doner) + (kredi > 0 ? ' (satış + ipotek)' : ' (satış)'));
      set(root, 't-r-toplam', tl(toplam));
      set(root, 't-r-kredi', kredi > 0 ? tl(kredi) : 'Kredi gerekmiyor');
      set(root, 't-r-taksit', kredi > 0 ? tl(taksit) + ' × ' + n + ' ay' : '–');
      set(root, 't-r-geri', kredi > 0 ? tl(taksit * n) : '–');
    },

    tapu: function (root) {
      var bedel = val(root, 'h-bedel');
      var katsayi = val(root, 'h-katsayi');
      var pay = bedel * 0.02;
      var doner = roundDoner(DONER_GOSTERGE * katsayi);
      set(root, 'h-r-alici', tl(pay));
      set(root, 'h-r-satici', tl(pay));
      set(root, 'h-r-toplam', tl(pay * 2));
      set(root, 'h-r-doner', tl2(doner));
      set(root, 'h-r-alici-toplam', tl2(pay * 2 + doner));
    },

    komisyon: function (root) {
      var bedel = val(root, 'k-bedel');
      var oran = Math.min(val(root, 'k-oran'), 100) / 100;
      var net = bedel * oran;
      var kdv = net * KDV;
      set(root, 'k-r-net', tl(net));
      set(root, 'k-r-kdv', tl(kdv));
      set(root, 'k-r-toplam', tl(net + kdv));
    },

    kredi: function (root) {
      var P = val(root, 'c-tutar');
      var r = val(root, 'c-faiz') / 100;
      var n = Math.round(val(root, 'c-vade'));
      var t = annuity(P, r, n);
      set(root, 'c-r-taksit', tl(t));
      set(root, 'c-r-geri', tl(t * n));
      set(root, 'c-r-faiz', tl(t * n - P));
      set(root, 'c-r-ilk', P > 0 ? tl(P * r) + ' faiz / ' + tl(t - P * r) + ' anapara' : '–');
      set(root, 'c-r-yillik', pct((Math.pow(1 + r, 12) - 1) * 100));
    },

    doner: function (root) {
      var katsayi = val(root, 'd-katsayi');
      var ipotek = val(root, 'd-ipotek') === 1;
      var islem = roundDoner(DONER_GOSTERGE * katsayi);
      set(root, 'd-r-islem', tl2(islem));
      set(root, 'd-r-toplam', tl2(ipotek ? islem * 2 : islem) + (ipotek ? ' (2 işlem)' : ' (1 işlem)'));
    },

    erken: function (root) {
      var anapara = val(root, 'e-anapara');
      var vade = Math.round(val(root, 'e-vade'));
      var oran = vade > 36 ? 0.02 : 0.01;
      set(root, 'e-r-oran', pct(oran * 100) + (vade > 36 ? ' (kalan vade 36 ayı aşıyor)' : ' (kalan vade 36 ay veya daha az)'));
      set(root, 'e-r-tutar', tl(anapara * oran));
    },

    dask: function (root) {
      var m2 = val(root, 's-m2');
      var birim = val(root, 's-yapi');
      var bedel = m2 * birim;
      var capped = bedel > DASK_MAX;
      set(root, 's-r-bedel', tl(Math.min(bedel, DASK_MAX)));
      set(root, 's-r-not', capped ? 'Evet – hesaplanan ' + tl(bedel) + ' azami teminatla sınırlandı' : 'Hayır');
    },

    kdv: function (root) {
      var bedel = val(root, 'v-bedel');
      var m2 = val(root, 'v-m2');
      var oran = val(root, 'v-tur');
      var kdv;
      if (m2 <= 150 || m2 === 0) {
        kdv = bedel * oran;
      } else {
        var alt = bedel * (150 / m2);
        kdv = alt * oran + (bedel - alt) * 0.20;
      }
      set(root, 'v-r-kdv', tl(kdv));
      set(root, 'v-r-toplam', tl(bedel + kdv));
      set(root, 'v-r-oran', bedel > 0 ? pct(kdv / bedel * 100) : '–');
    },

    ltv: function (root) {
      var deger = val(root, 'l-deger');
      var enerji = root.querySelector('#l-enerji').value;
      var carpan = val(root, 'l-ilk'); // 1 veya 0.25
      var table = [
        [5000000, { ab: 0.90, c: 0.80, d: 0.70 }],
        [7000000, { ab: 0.80, c: 0.70, d: 0.60 }],
        [10000000, { ab: 0.70, c: 0.60, d: 0.50 }],
        [20000000, { ab: 0.50, c: 0.40, d: 0.30 }],
        [Infinity, { ab: 0.40, c: 0.30, d: 0.20 }]
      ];
      var oran = 0;
      for (var i = 0; i < table.length; i++) {
        if (deger <= table[i][0]) { oran = table[i][1][enerji]; break; }
      }
      oran = oran * carpan;
      set(root, 'l-r-oran', pct(oran * 100));
      set(root, 'l-r-kredi', tl(deger * oran));
      set(root, 'l-r-pesinat', tl(deger * (1 - oran)));
    }
  };

  function init(root) {
    var kind = root.getAttribute('data-calc');
    var fn = calcs[kind];
    if (!fn) return;
    var run = function () { try { fn(root); } catch (e) { /* sessiz */ } };
    root.querySelectorAll('input, select').forEach(function (el) {
      el.addEventListener('input', run);
      el.addEventListener('change', run);
    });
    root.querySelector('form').addEventListener('submit', function (e) { e.preventDefault(); run(); });
    run();
  }

  document.querySelectorAll('.calc[data-calc]').forEach(init);
})();
