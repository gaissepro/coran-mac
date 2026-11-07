const D = {"fatiha": [{"ar": "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "fr": "Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux."}, {"ar": "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ", "fr": "Louange à Allah, Seigneur de l'univers."}, {"ar": "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", "fr": "Le Tout Miséricordieux, le Très Miséricordieux,"}, {"ar": "مَٰلِكِ يَوْمِ ٱلدِّينِ", "fr": "Maître du Jour de la rétribution."}], "a23": {"ar": "ٱلَّذِينَ يُؤْمِنُونَ بِٱلْغَيْبِ وَيُقِيمُونَ ٱلصَّلَوٰةَ وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ", "fr": "qui croient à l'invisible et accomplissent la Salât et dépensent (dans l'obéissance à Allah), de ce que Nous leur avons attribué,"}, "kahf_ar": "الكَهۡفِ", "kahf_ctx": "Révélée à La Mecque. D'après les récits, elle répond à des questions posées au Prophète : les Gens de la Caverne, Dhul-Qarnayn et l'esprit. Elle contient aussi Moïse et Khidr et la parabole des deux jardins. Sa lecture est recommandée le vendredi.", "rows1": [[1, "Al-Faatiha", "ٱلْفَاتِحَةِ"], [2, "Al-Baqara", "البَقَرَةِ"], [3, "Aal-i-Imraan", "آلِ عِمۡرَانَ"], [4, "An-Nisaa", "النِّسَاءِ"], [5, "Al-Maaida", "المَائـِدَةِ"], [6, "Al-An'aam", "الأَنۡعَامِ"], [7, "Al-A'raaf", "الأَعۡرَافِ"], [8, "Al-Anfaal", "الأَنفَالِ"]], "rows18": [[16, "An-Nahl", "النَّحۡلِ"], [17, "Al-Israa", "الإِسۡرَاءِ"], [18, "Al-Kahf", "الكَهۡفِ"], [19, "Maryam", "مَرۡيَمَ"], [20, "Taa-Haa", "طه"], [21, "Al-Anbiyaa", "الأَنبِيَاءِ"], [22, "Al-Hajj", "الحَجِّ"], [23, "Al-Muminoon", "المُؤۡمِنُونَ"]]};
(() => {
  const stage = document.getElementById('stage');
  const demo = document.getElementById('demo');
  if (!stage || !demo) return;
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ---------- Décor de l'app ----------
  stage.innerHTML = `
  <div class="sb">
    <div class="brand2"><span class="ar">القرآن</span><small>Coran</small></div>
    <div class="srch">🔍 <span>Rechercher</span><b>⌘K</b></div>
    <div class="chips"><span class="on">Coran</span><span>Hadiths</span><span>Arabe</span><span>★ 0</span></div>
    <div class="rows" id="rows"></div>
    <div class="prof"><div class="av">Y</div>
      <div><div class="nm">Yassine</div><div class="st"><span class="fl">🔥 <i id="strk">4</i></span><span class="bo">⚡ <i id="xpv">145</i></span></div></div>
      <div class="ring" id="ring" style="--p:66%"></div></div>
  </div>
  <div class="main">
    <div class="layer on" id="L-reader"><div class="vwrap"><div class="vlist" id="vlist"></div></div>
      <div class="player"><div class="t"><b>Al-Faatiha</b><small id="psub">Verset 1/7 · Mishary Alafasy</small></div>
        <div class="ctl"><span>⏮</span><span class="pp" id="pp">❚❚</span><span>⏭</span><span style="opacity:.6">↻</span><span style="font:600 12px var(--sans)">1x</span></div>
        <div class="pbar2"><i id="pbar"></i></div></div></div>
    <div class="layer" id="L-head"><div class="shead">
      <div class="big ar">سُورَةُ ${D.kahf_ar}</div><h4>La caverne</h4>
      <div class="pills"><span>110 versets</span><span>Mecquoise</span><span>69ᵉ révélée</span><span>Sourate 18/114</span></div>
      <div class="ctx"><label>📜 Contexte de révélation</label><p>${D.kahf_ctx}</p><small>Résumé général fondé sur les repères traditionnels. Pour le détail, consulte un tafsir.</small></div></div></div>
    <div class="layer" id="L-aya"><div class="vwrap"><div class="vlist" style="padding-top:60px">
      <div class="vc act"><div class="top"><div class="btns"><span>▶</span><span>🎙</span><span style="color:var(--acc)">ⓘ</span><span class="lu">J'ai lu · +5</span></div><span>2:3</span></div>
        <div class="line">${D.a23.ar} <span class="n">﴿٣﴾</span></div>
        <div class="gl"><em>Mots expliqués</em><span id="g1">إيمان <u>?</u></span><span id="g2">غيب <u>?</u></span><span id="g3">صلاة <u>?</u></span></div>
        <div class="tr">${D.a23.fr}</div></div></div></div></div>
    <div class="layer quiz" id="L-quiz">
      <div class="top"><span>✕</span><div class="pb"><i id="qpb"></i></div></div>
      <h5>Comment s'appelle cette lettre ?</h5>
      <div class="letter"><span class="ar">ص</span><div class="spk">🔊</div></div>
      <div class="opts" id="opts"></div>
      <div class="xp" id="xp">⚡ +15 XP</div>
      <div class="fb" id="fb"><div class="msg"><div class="ic">✓</div><div><b>Mashallah !</b><small>ص = Saad : S emphatique, plus profond.</small></div></div><div class="go">Vérifier</div></div>
    </div>
    <div class="layer stats" id="L-stats"><h5>Mes stats</h5>
      <div class="tiles">
        <div class="tile">⏱<div><b id="s1">0 min</b><small>aujourd'hui</small></div></div>
        <div class="tile">📅<div><b id="s2">0 h</b><small>7 derniers jours</small></div></div>
        <div class="tile">🔥<div><b id="s3">0</b><small>jours de suite</small></div></div></div>
      <div class="chart" id="chart"></div>
      <div class="legend"><span style="--c:#8fd9b6">Lecture</span><span style="--c:#f6b47b">Écoute</span><span style="--c:#b7a7f0">Apprentissage</span></div>
      <div class="heat" id="heat"></div></div>
    <div class="scrim" id="scrim"></div>
    <div class="pal" id="pal"><div class="in">🔍 <span id="ptxt" class="ph">Sourate, 2:255, ou un mot…</span><span class="caret"></span></div>
      <div class="res"><div class="hit" id="hit"><div><b>18. Al-Kahf</b><small>110 versets · Mecquoise</small></div><span class="ar">${D.kahf_ar}</span></div></div></div>
    <div class="info" id="info"><div class="h">La vache · 2:3</div>
      <div class="card"><b>salât · صلاة</b><p>« Prière » traduit bien la prière rituelle, mais la racine évoque aussi le lien et l'invocation. Le Coran parle d'« établir » la salat, c'est-à-dire l'accomplir régulièrement et correctement.</p></div>
      <div class="aya">${D.a23.ar}</div><div class="tr">${D.a23.fr}</div></div>
    <div class="cursor" id="cur"><svg width="22" height="22" viewBox="0 0 24 24"><path d="M5 3l14 8-6 2-3 6z" fill="#fff" stroke="#000" stroke-width="1.5" stroke-linejoin="round"/></svg></div>
  </div>`;

  const $ = s => stage.querySelector(s);
  const layers = ['reader', 'head', 'aya', 'quiz', 'stats'];
  const show = (...names) => layers.forEach(n => $('#L-' + n).classList.toggle('on', names.includes(n)));

  // ---------- Mise à l'échelle ----------
  const fit = stage.parentElement;
  const rescale = () => { const compact = fit.clientWidth < 720; stage.classList.toggle('compact', compact); const s = fit.clientWidth / (compact ? 690 : 940); stage.style.transform = `scale(${s})`; fit.style.height = (620 * s) + 'px'; };
  new ResizeObserver(rescale).observe(fit); rescale();

  // ---------- Pilotage du temps (pause au survol / hors écran) ----------
  let token = 0, paused = false, visible = true, current = 0;
  const wait = (ms, my) => new Promise((res, rej) => {
    let left = reduce ? 0 : ms;
    const tick = () => {
      if (my !== token) return rej('cancel');
      if (left <= 0) return res();
      if (!paused && visible) left -= 40;
      setTimeout(tick, 40);
    };
    tick();
  });

  // ---------- Données ----------
  const setRows = (list, sel) => {
    $('#rows').innerHTML = list.map(([n, en, ar]) => `<div class="row2${n === sel ? ' sel' : ''}"><span>${n}. ${en}</span><span class="ar">${ar}</span></div>`).join('');
  };
  const renderVerses = () => {
    $('#vlist').innerHTML = D.fatiha.map((v, i) => {
      const words = v.ar.split(' ');
      return `<div class="vc" id="v${i}"><div class="top"><div class="btns"><span>▶</span><span>🎙</span><span>ⓘ</span><span class="lu">J'ai lu · +5</span></div><span>1:${i + 1}</span></div>
        <div class="line">${words.map(w => `<span>${w}</span>`).join(' ')} <span class="n">﴿${'١٢٣٤'[i]}﴾</span></div>
        <div class="tr">${v.fr}</div></div>`;
    }).join('');
    $('#vlist').style.transform = 'translateY(0)';
  };
  const colors = ['#8fd9b6', '#f6b47b', '#b7a7f0', '#f4a6c0', '#8ec9f2', '#f2dc7e'];
  const setAccent = c => stage.style.setProperty('--acc', c);
  const resetLook = () => { setAccent(colors[0]); stage.classList.remove('t-sepia', 't-light'); };
  const clearOverlays = () => { $('#scrim').classList.remove('on'); $('#pal').classList.remove('on'); $('#info').classList.remove('on'); $('#cur').classList.remove('on'); };
  const moveCursor = (x, y) => { $('#cur').style.transform = `translate(${x}px,${y}px)`; };
  const setVal = (id, v) => { $(id).textContent = v; };

  // ---------- Scènes ----------
  const scenes = [
    { label: 'Écouter', dur: 11, cap: 'La récitation suit le texte : le verset est surligné et les mots se colorent au rythme de la voix.',
      async run(my) {
        resetLook(); clearOverlays(); renderVerses(); setRows(D.rows1, 1); show('reader');
        $('#pp').textContent = '❚❚'; $('#pbar').style.width = '0%';
        let done = 0; const total = D.fatiha.length;
        for (let i = 0; i < total; i++) {
          const card = $('#v' + i); card.classList.add('act');
          $('#psub').textContent = `Verset ${i + 1}/7 · Mishary Alafasy`;
          if (i >= 2) $('#vlist').style.transform = `translateY(${-(i - 1) * 160}px)`;
          const spans = [...card.querySelectorAll('.line span:not(.n)')];
          const weights = spans.map(s => s.textContent.length + 1), sum = weights.reduce((a, b) => a + b, 0);
          for (let k = 0; k < spans.length; k++) { spans[k].classList.add('on'); await wait(2400 * weights[k] / sum, my); }
          card.querySelector('.n').classList.add('on');
          card.querySelector('.lu').classList.add('ok'); card.querySelector('.lu').textContent = '✓ Lu';
          done++; $('#pbar').style.width = (done / total * 100) + '%';
          await wait(250, my); card.classList.remove('act');
        }
        await wait(500, my);
      } },
    { label: 'Chercher', dur: 6.7, cap: 'Tape quelques lettres, ⌘K trouve la sourate. Chacune s\'ouvre avec son nom français et son contexte de révélation.',
      async run(my) {
        resetLook(); clearOverlays(); renderVerses(); setRows(D.rows1, 1); show('reader');
        D.fatiha.forEach((_, i) => $('#v' + i).querySelectorAll('.line span').forEach(s => s.classList.add('on')));
        $('#scrim').classList.add('on'); $('#pal').classList.add('on'); $('#ptxt').className = 'ph'; $('#ptxt').textContent = 'Sourate, 2:255, ou un mot…'; $('#hit').className = 'hit';
        await wait(700, my);
        $('#ptxt').className = ''; let t = '';
        for (const ch of 'kahf') { t += ch; $('#ptxt').textContent = t; if (t.length === 2) $('#hit').classList.add('on'); await wait(230, my); }
        await wait(800, my); $('#hit').classList.add('flash'); await wait(450, my);
        clearOverlays(); setRows(D.rows18, 18); show('head'); await wait(3800, my);
      } },
    { label: 'Comprendre', dur: 7.7, cap: 'Les mots difficiles à traduire sont expliqués. Un clic ouvre le sens, la racine et le contexte du verset.',
      async run(my) {
        resetLook(); clearOverlays(); setRows(D.rows1.map(r => r).slice(0, 8), 2); show('aya');
        ['g1', 'g2', 'g3'].forEach(i => $('#' + i).classList.remove('hot'));
        moveCursor(700, 420); await wait(900, my);
        const g = $('#g3'), gr = g.getBoundingClientRect(), sr = stage.getBoundingClientRect(), mr = $('.main').getBoundingClientRect(), k = sr.width / stage.offsetWidth;
        $('#cur').classList.add('on');
        moveCursor((gr.left - mr.left) / k + 24, (gr.top - mr.top) / k + 6); await wait(1100, my);
        g.classList.add('hot'); $('#cur').classList.add('click'); await wait(350, my); $('#cur').classList.remove('click');
        $('#info').classList.add('on'); await wait(4800, my);
        $('#info').classList.remove('on'); $('#cur').classList.remove('on'); await wait(500, my);
      } },
    { label: 'Apprendre', dur: 7.9, cap: 'Des leçons courtes façon jeu : alphabet, voyelles, mots du Coran. L\'XP, la série et la révision te font revenir.',
      async run(my) {
        resetLook(); clearOverlays(); setRows(D.rows1, 1); show('quiz');
        $('#opts').innerHTML = ['Taa', 'Saad', 'Jiim', 'Zaay'].map((n, i) => `<div class="opt"><i>${i + 1}</i><span>${n}</span></div>`).join('');
        $('#fb').className = 'fb'; $('#fb .go').textContent = 'Vérifier'; $('#qpb').style.width = '8%'; $('#xp').classList.remove('on');
        setVal('#xpv', 145); setVal('#strk', 4);
        await wait(1500, my);
        const opts = [...stage.querySelectorAll('.opt')]; opts[0].classList.add('pick'); await wait(450, my); opts[0].classList.remove('pick');
        opts[1].classList.add('pick'); await wait(900, my);
        $('#fb').classList.add('ready'); await wait(700, my);
        opts[1].classList.remove('pick'); opts[1].classList.add('good'); $('#fb').classList.add('ok'); $('#fb .go').textContent = 'Continuer';
        $('#qpb').style.width = '34%'; await wait(500, my);
        $('#xp').classList.add('on'); setVal('#xpv', 160); setVal('#strk', 5); await wait(3800, my);
      } },
    { label: 'Progresser', dur: 6.1, cap: 'Temps de lecture, d\'écoute et d\'apprentissage, régularité sur 12 semaines : tu vois ce que tu construis.',
      async run(my) {
        resetLook(); clearOverlays(); setRows(D.rows1, 1); show('stats');
        const data = [[90, 0, 60], [0, 0, 0], [62, 40, 34], [48, 18, 52], [0, 0, 0], [34, 10, 26], [26, 0, 20]], days = ['dim.', 'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.'];
        const cs = ['#8fd9b6', '#f6b47b', '#b7a7f0'];
        $('#chart').innerHTML = data.map((d, i) => `<div class="col"><div class="stack">${d.map((v, k) => `<i style="background:${cs[k]};--h:${v}px"></i>`).join('')}</div><small>${days[i]}</small></div>`).join('');
        $('#heat').innerHTML = Array.from({ length: 84 }, (_, i) => { const on = i > 40 && (i * 7) % 5 !== 0; return `<i data-on="${on ? 1 : 0}" style="${on ? `background:var(--acc);--o:${(0.3 + ((i * 13) % 7) / 10).toFixed(2)}` : ''}"></i>`; }).join('');
        setVal('#s1', '0 min'); setVal('#s2', '0 h'); setVal('#s3', '0');
        await wait(700, my);
        stage.querySelectorAll('.stack i').forEach(el => el.style.height = el.style.getPropertyValue('--h'));
        stage.querySelectorAll('.heat i').forEach((el, i) => setTimeout(() => { el.style.opacity = el.dataset.on === '1' ? el.style.getPropertyValue('--o') : 1; }, 12 * i));
        const t0 = performance.now();
        await new Promise((res, rej) => { const f = () => { if (my !== token) return rej('cancel'); const p = Math.min(1, (performance.now() - t0) / 1200); setVal('#s1', Math.round(p * 9) + ' min'); const m = Math.round(p * 94); setVal('#s2', Math.floor(m / 60) + ' h ' + String(m % 60).padStart(2, '0')); setVal('#s3', Math.round(p * 5)); p < 1 ? requestAnimationFrame(f) : res(); }; reduce ? res() : f(); });
        setVal('#s2', '1 h 34'); await wait(4200, my);
      } },
    { label: 'Personnaliser', dur: 7.2, cap: 'Six couleurs pastel, trois thèmes (sombre, sépia, clair) et une taille d\'arabe réglable. L\'app se met à ta façon.',
      async run(my) {
        clearOverlays(); renderVerses(); setRows(D.rows1, 1); show('reader');
        D.fatiha.forEach((_, i) => $('#v' + i).querySelectorAll('.line span').forEach(s => s.classList.add('on')));
        $('#v1').classList.add('act'); $('#vlist').style.transform = 'translateY(-10px)';
        for (let i = 0; i < colors.length; i++) { setAccent(colors[i]); await wait(620, my); }
        setAccent('#2f9e72'); stage.classList.add('t-sepia'); await wait(1300, my);
        stage.classList.remove('t-sepia'); stage.classList.add('t-light'); setAccent('#2f9e72'); await wait(1300, my);
        stage.classList.remove('t-light'); setAccent(colors[0]); await wait(900, my);
      } },
  ];

  // ---------- Onglets + boucle ----------
  const tabs = demo.querySelector('.demo-tabs');
  tabs.innerHTML = scenes.map((s, i) => `<button role="tab" aria-selected="false" data-i="${i}">${s.label}<i></i></button>`).join('');
  const cap = document.getElementById('demoCap');
  const select = i => {
    tabs.querySelectorAll('button').forEach((b, k) => { b.setAttribute('aria-selected', k === i); b.style.setProperty('--dur', scenes[i].dur + 's'); const bar = b.querySelector('i'); bar.style.animation = 'none'; void bar.offsetWidth; bar.style.animation = ''; });
    cap.style.opacity = 0; setTimeout(() => { cap.textContent = scenes[i].cap; cap.style.opacity = 1; }, 160);
  };
  async function play(i) {
    const my = ++token; current = i; select(i);
    try { await scenes[i].run(my); } catch (e) { if (e !== 'cancel') console.error(e); return; }
    if (my === token && !reduce) play((i + 1) % scenes.length);
  }
  tabs.addEventListener('click', e => { const b = e.target.closest('button'); if (b) play(+b.dataset.i); });
  demo.addEventListener('mouseenter', () => { paused = true; demo.classList.add('paused'); });
  demo.addEventListener('mouseleave', () => { paused = false; demo.classList.remove('paused'); });
  new IntersectionObserver(es => { visible = es[0].isIntersecting; demo.classList.toggle('paused', !visible || paused); }, { threshold: 0.25 }).observe(demo);

  setRows(D.rows1, 1); renderVerses();
  play(0);
})();
