"""Builds a Wreadom HTML5 story ad (320x480) into <dir>/index.html + a zip for Google Ads.

Run (from the ads/ folder):  python -I build_story_ad.py <story-key>
Add a story by adding an entry to STORIES and putting its cover at <dir>/cover_src.jpg.
"""
import base64
import io
import json
import sys
import zipfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
PLAY_URL = "https://play.google.com/store/apps/details?id=in.wreadom.app"
CTA_BUTTON = "ऐप इंस्टॉल करें"

STORIES = {
    "talaash": {
        "dir": "talaash_html5",
        "zip": "talaash_320x480.zip",
        "title": "तलाश - द हिडन सर्च",
        "title_display": "तलाश – द हिडन सर्च",
        "byline": "लेखिका: Nida R Nida",
        "tag": "एक रहस्य-कथा",
        # camera focus per slide: the burning house / the man in the ICU corridor / her face
        "origins": ["14% 24%", "86% 64%", "42% 30%"],
        "slides": [
            "काली घनी रात। एक घर के सामने हथियारबंद लोग खड़े थे। गोलियों की आवाज़ से मुहल्ला दहल गया, पर किसी ने पुलिस नहीं बुलाई। अंदर चार लाशें पड़ी थीं… या शायद तीन। क्योंकि इक्कीस साल की एक लड़की की धड़कनें अभी रुकी नहीं थीं। वह अब हॉस्पिटल में थी, और आई.सी.यू. के बाहर एक लड़का बेचैन बैठा था…",
            "उस लड़के की आँखें सुर्ख़ थीं, जबड़े भिंचे हुए।\n\u201cअब वो कैसी है डॉक्टर?\u201d\n\u201cअभी कुछ कहा नहीं जा सकता। ख़ून काफ़ी बह गया है। हमें डर है कि वो कहीं कोमा में न चली जाए।\u201d\nडॉक्टर जल्दी में कमरे में चले गए। और फिर, पूरे छत्तीस घंटों के बाद, उसे होश आया…",
            "दवाइयों की महक, काँपती पलकें। सामने डॉक्टर थे, और उनके साथ वही लड़का।\n\u201cम..मैं… यहाँ… आप…\u201d\n\u201cआप ज़ख़्मी थीं, मिस्टर ओम आपको यहाँ लाये।\u201d\n\u201cमैं कौन हूँ?… और ओम… ये कौन हैं?\u201d\nओम की आँखों में हैरत थी, मगर वह कुछ नहीं बोला…",
        ],
    },
    "nisargpishachini": {
        "dir": "nisarg_html5",
        "zip": "nisargpishachini_320x480.zip",
        "title": "निसर्गपिशाचिनी (उस रात की बात)",
        "title_display": "निसर्गपिशाचिनी",
        "byline": "उस रात की बात · लेखिका: मनस्वी",
        "tag": "एक डरावनी कथा",
        # camera focus per slide: the twins / the well / the figure in the moon
        "origins": ["38% 78%", "52% 72%", "50% 12%"],
        "slides": [
            "\u201cदादाजी! ये निसर्गपिशाचिनी क्या होती है?\u201d\n\u201cश्श् बेटा! वो नाम लेने पर आ जाती है। छोटे बच्चों को ले जाती है… वे कभी नहीं लौटते।\u201d\nरात को सत्यम ने शिवम को जगाया: \u201cचल, उसे देखने चलते हैं!\u201d\n\u201cपागल है क्या? वो बच्चों को उठा ले जाती है!\u201d\n\u201cफट्टू! मैं अकेला जाता हूँ।\u201d\nशिवम को साथ आना ही पड़ा…",
            "सन्नाटे में सिर्फ़ झींगुरों की आवाज़ थी। तभी शिवम की उँगली काँपी:\n\u201cवो… वो क्या है?\u201d\nपुराने कुएँ के पास कोई छोटा साया गठरी की तरह बैठा था। पास गए तो एक बच्ची थी, बहुत कमज़ोर। उसके शरीर पर सूखे पत्ते चिपके थे, और चेहरे पर जलने का ताज़ा निशान…",
            "\u201cरुक, मैं पानी लेकर आता हूँ!\u201d सत्यम दादाजी को बुलाने दौड़ा। शिवम अँधेरे में उस बच्ची के पास अकेला रह गया।\nदादाजी और गाँववालों के साथ लौटा तो कुएँ के पास कोई नहीं था। न बच्ची, न शिवम।\nटॉर्च की रौशनी में ज़मीन पर पैरों के निशान थे… और वे सारे उल्टे थे…",
        ],
    },
    "eeha": {
        "dir": "eeha_html5",
        "zip": "eeha_320x480.zip",
        "title": "ईहा",
        "title_display": "ईहा",
        "byline": "लेखक: सुमित मेनारिया",
        "tag": "एक अधूरी कहानी",
        # camera focus per slide: her / the two of them / the title and petals
        "origins": ["44% 52%", "62% 38%", "30% 14%"],
        "slides": [
            "जॉब छूटे दो महीने हो चुके थे। उस दिन एक और इंटरव्यू था। वापस लौटते हुए मैं स्कूटी चला रही थी कि ईयरपीस में कॉल आई।\nकबीर।\nतीन दिन से ढंग से बात नहीं हुई थी। चेहरे पर मुस्कान आ गई।\n\u201cहैलो!\u201d\n\u201cकहाँ हो?\u201d उसकी आवाज़ सामान्य से ज़्यादा गंभीर थी।",
            "\u201cबस इंटरव्यू देकर निकल रही हूँ। क्यों?\u201d\n\u201cईहा… मुझे तुमसे कुछ बात करनी थी।\u201d\nकुछ पल की ख़ामोशी।\n\u201cमुझे लगता है हमें थोड़ा ब्रेक लेना चाहिए।\u201d\nमेरे हाथ हैंडल पर कस गए।\n\u201cक्या मतलब ब्रेक?\u201d\n\u201cवही जो तुम समझ रही हो।\u201d\nसामने सिग्नल पीला हुआ। मैंने ब्रेक लगाया, पर दिमाग़ सड़क पर था ही नहीं…",
            "\u201cअचानक क्या हो गया, कबीर?\u201d\n\u201cअचानक नहीं हुआ है, ईहा। काफ़ी टाइम से चल रहा है।\u201d\nसिग्नल के बीच मेरी स्कूटी लगभग रुक चुकी थी।\n\u201cकबीर!\u201d मैंने तेज़ आवाज़ में कहा।\nतभी सामने वाली लेन से एक कार अचानक मेरी तरफ़ मुड़ी। मैंने हैंडल मोड़ा, स्कूटी का पिछला पहिया फिसल गया। फिर तेज़ हॉर्न… फिर ज़मीन… और फिर, कुछ नहीं…",
        ],
    },
}

if len(sys.argv) != 2 or sys.argv[1] not in STORIES:
    sys.exit("usage: python -I build_story_ad.py <%s>" % "|".join(STORIES))
CFG = STORIES[sys.argv[1]]
OUT = HERE / CFG["dir"]
SLIDES = CFG["slides"]
TITLE = CFG["title"]
ORIGINS = CFG["origins"]


def b64_jpeg(path: Path, size, quality):
    im = Image.open(path).convert("RGB").resize(size, Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=quality, optimize=True, progressive=True)
    return base64.b64encode(buf.getvalue()).decode()


def b64_png(path: Path, size):
    im = Image.open(path).convert("RGBA").resize(size, Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "PNG", optimize=True)
    return base64.b64encode(buf.getvalue()).decode()


COVER = b64_jpeg(OUT / "cover_src.jpg", (480, 720), 70)
LOGO = b64_png(HERE / ".." / "assets" / "images" / "app_logo.png", (96, 96))

HTML = """<!DOCTYPE html>
<html lang="hi">
<head>
<meta charset="utf-8">
<meta name="ad.size" content="width=320,height=480">
<meta name="viewport" content="width=320,height=480,initial-scale=1">
<title>Wreadom - __TITLE__</title>
<script type="text/javascript">var clickTag = "__PLAY_URL__";</script>
<style>
*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent}
html,body{width:320px;height:480px;overflow:hidden;background:#000}
body{font-family:"Noto Sans Devanagari","Nirmala UI","Mukta","Hind",sans-serif}
#ad{position:relative;width:320px;height:480px;overflow:hidden;background:#05060a;color:#fff;cursor:pointer;user-select:none;-webkit-user-select:none}
.layer{position:absolute;left:0;top:0;width:320px;height:480px;opacity:0;transition:opacity .7s ease;pointer-events:none}
.layer.on{opacity:1}
.cover{position:absolute;left:0;top:0;width:320px;height:480px;background:url(data:image/jpeg;base64,__COVER__) 0 0/100% 100% no-repeat}
.zoom{transform:scale(1.85);animation:drift 11s ease-in-out forwards}
@keyframes drift{from{transform:scale(1.85)}to{transform:scale(2.15)}}
.shade{position:absolute;inset:0;background:linear-gradient(to bottom,rgba(0,0,0,.55) 0%,rgba(0,0,0,.22) 17%,rgba(0,0,0,.84) 33%,rgba(0,0,0,.94) 48%,rgba(0,0,0,.97) 100%)}
.brand{position:absolute;left:12px;top:10px;display:flex;align-items:center;gap:7px;z-index:5}
.brand img{width:26px;height:26px;border-radius:6px;display:block}
.brand b{font-size:13px;letter-spacing:.3px;color:#fff;text-shadow:0 1px 4px #000}
.brand span{font-size:11px;color:#f3b27a;text-shadow:0 1px 4px #000;margin-left:2px}
.dots{position:absolute;right:12px;top:18px;display:flex;gap:5px;z-index:5}
.dots i{width:18px;height:3px;border-radius:2px;background:rgba(255,255,255,.28)}
.dots i.on{background:#ff7a1a}
.txt{position:absolute;left:18px;right:18px;bottom:62px;font-size:15.5px;line-height:1.62;font-weight:500;text-shadow:0 1px 6px #000,0 0 14px rgba(0,0,0,.9)}
.txt .w{opacity:0;transition:opacity .25s}
.txt .w.v{opacity:1}
.txt .last{color:#ff9a45;font-weight:700}
.hint{position:absolute;left:0;right:0;bottom:20px;text-align:center;font-size:12px;color:#ffb27a;letter-spacing:.3px;opacity:0;transition:opacity .4s;text-shadow:0 1px 4px #000}
.hint.on{opacity:1;animation:blink 1.3s ease-in-out infinite}
@keyframes blink{50%{opacity:.35}}
.tag{position:absolute;left:0;right:0;bottom:11px;text-align:center;font-size:13px;color:#fff;text-shadow:0 1px 6px #000}
.tag em{font-style:normal;color:#ff9a45;font-weight:700}
/* CTA */
.ctabg{position:absolute;left:-40px;top:-40px;width:400px;height:560px;background:url(data:image/jpeg;base64,__COVER__) center/cover;filter:blur(14px) brightness(.38) saturate(1.2)}
.card{position:absolute;left:50%;top:58px;width:128px;height:192px;margin-left:-64px;border-radius:8px;overflow:hidden;box-shadow:0 0 0 1px rgba(255,255,255,.12),0 12px 30px rgba(0,0,0,.7),0 0 36px rgba(255,98,0,.28);transform:rotate(-3deg);background:url(data:image/jpeg;base64,__COVER__) 0 0/100% 100% no-repeat}
.ttl{position:absolute;left:12px;right:12px;top:262px;text-align:center}
.ttl h2{font-size:17px;color:#f6d9a8;font-weight:700;text-shadow:0 1px 6px #000}
.ttl p{font-size:11px;color:#c9c9d1;margin-top:1px}
.ctatext{position:absolute;left:18px;right:18px;top:316px;text-align:center;font-size:16.5px;line-height:1.5;font-weight:700;text-shadow:0 1px 6px #000}
.ctatext em{font-style:normal;color:#ff9a45}
.btn{position:absolute;left:50%;top:392px;margin-left:-100px;width:200px;height:44px;border-radius:22px;background:linear-gradient(180deg,#ff8a2b,#f05a00);color:#fff;font-size:15.5px;font-weight:700;text-align:center;line-height:44px;box-shadow:0 6px 18px rgba(240,90,0,.55);animation:pulse 1.4s ease-in-out infinite}
@keyframes pulse{50%{transform:scale(1.06)}}
.foot{position:absolute;left:0;right:0;bottom:12px;display:flex;justify-content:center;align-items:center;gap:7px}
.foot img{width:22px;height:22px;border-radius:5px}
.foot b{font-size:13px}
.foot span{font-size:11px;color:#bbb}
</style>
</head>
<body>
<div id="ad">
  <!-- Splash: the cover -->
  <div class="layer on" id="L0">
    <div class="cover" style="left:12px;top:0;width:296px;height:444px"></div>
    <div class="shade" style="background:linear-gradient(to bottom,rgba(0,0,0,.55) 0%,rgba(0,0,0,0) 18%,rgba(0,0,0,0) 76%,rgba(0,0,0,.85) 100%)"></div>
    <div class="tag">__TAG__ &nbsp;·&nbsp; <em>टैप करके पढ़ें</em></div>
  </div>
  <!-- Story slides -->
  <div class="layer" id="L1"><div class="cover zoom" style="transform-origin:__O0__"></div><div class="shade"></div><div class="txt" id="T1"></div></div>
  <div class="layer" id="L2"><div class="cover zoom" style="transform-origin:__O1__"></div><div class="shade"></div><div class="txt" id="T2"></div></div>
  <div class="layer" id="L3"><div class="cover zoom" style="transform-origin:__O2__"></div><div class="shade"></div><div class="txt" id="T3"></div></div>
  <!-- Final CTA -->
  <div class="layer" id="L4">
    <div class="ctabg"></div><div class="shade" style="background:rgba(0,0,0,.25)"></div>
    <div class="card"></div>
    <div class="ttl"><h2>__TITLE_DISPLAY__</h2><p>__BYLINE__</p></div>
    <div class="ctatext">आगे क्या हुआ?<br>पूरी कहानी <em>Wreadom</em> पर पढ़ें, मुफ़्त!</div>
    <div class="btn">__CTA_BUTTON__ &#9654;</div>
  </div>
  <!-- Always-on chrome -->
  <div class="brand"><img alt="" src="data:image/png;base64,__LOGO__"><b>Wreadom</b><span id="cap">__TITLE_DISPLAY__</span></div>
  <div class="dots" id="dots"><i></i><i></i><i></i></div>
  <div class="hint" id="hint">आगे के लिए टैप करें &#9656;</div>
</div>
<script>
(function(){
  var SLIDES = __SLIDES_JSON__;
  var WORD_MS = 105, HOLD_MS = 2600, SPLASH_MS = 2600;
  var cur = 0, timer = null, typing = false, words = [], wi = 0;
  var layers = [0,1,2,3,4].map(function(i){return document.getElementById('L'+i);});
  var hint = document.getElementById('hint'), dots = document.getElementById('dots').children;
  var dotsEl = document.getElementById('dots'), cap = document.getElementById('cap');

  function show(n){
    cur = n;
    layers.forEach(function(l,i){ l.className = 'layer' + (i===n?' on':''); });
    hint.className = 'hint';
    cap.style.display = (n===0||n===4) ? 'none' : '';
    dotsEl.style.display = (n>=1&&n<=3) ? 'flex' : 'none';
    for (var d=0; d<dots.length; d++) dots[d].className = (d===n-1)?'on':'';
    clearTimeout(timer);
    if (n===0) { timer = setTimeout(next, SPLASH_MS); }
    else if (n>=1 && n<=3) { type(n); }
  }
  function type(n){
    var el = document.getElementById('T'+n);
    var parts = SLIDES[n-1].replace(/\\n/g, ' \\n ').split(' ').filter(function(w){return w;});
    el.innerHTML = parts.map(function(w,i){
      return '<span class="w'+(i>=parts.length-3?' last':'')+'">'+(w==='\\n'?'<br>':w+' ')+'</span>';
    }).join('');
    words = el.children; wi = 0; typing = true;
    (function step(){
      if (wi < words.length) { words[wi++].className += ' v'; timer = setTimeout(step, WORD_MS); }
      else { done(); }
    })();
  }
  function done(){
    typing = false; hint.className = 'hint on';
    timer = setTimeout(next, HOLD_MS);
  }
  function revealAll(){
    clearTimeout(timer);
    for (var i=wi; i<words.length; i++) words[i].className += ' v';
    wi = words.length; done();
  }
  function next(){ if (cur < 4) show(cur+1); }
  function exitAd(){ window.open(window.clickTag, '_blank'); }

  document.getElementById('ad').addEventListener('click', function(){
    if (cur === 4) return exitAd();
    if (cur >= 1 && cur <= 3 && typing) return revealAll();
    next();
  });
  show(0);
})();
</script>
</body>
</html>
"""

html = (
    HTML.replace("__COVER__", COVER)
    .replace("__LOGO__", LOGO)
    .replace("__PLAY_URL__", PLAY_URL)
    .replace("__TITLE__", TITLE)
    .replace("__TITLE_DISPLAY__", CFG["title_display"])
    .replace("__BYLINE__", CFG["byline"])
    .replace("__TAG__", CFG["tag"])
    .replace("__CTA_BUTTON__", CTA_BUTTON)
    .replace("__O0__", ORIGINS[0])
    .replace("__O1__", ORIGINS[1])
    .replace("__O2__", ORIGINS[2])
    .replace("__SLIDES_JSON__", json.dumps(SLIDES, ensure_ascii=False))
)

(OUT / "index.html").write_text(html, encoding="utf-8")
zip_path = OUT / CFG["zip"]
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    z.write(OUT / "index.html", "index.html")

print("index.html", len(html.encode()) // 1024, "KB; zip", zip_path.stat().st_size // 1024, "KB")
for i, s in enumerate(SLIDES, 1):
    print("slide", i, "words:", len(s.split()))
