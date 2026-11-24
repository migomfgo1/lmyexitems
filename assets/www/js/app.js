/* L my ex items — single-page app for the iOS WebView (iPhone + iPad). No network, all assets local. */
(function () {
  'use strict';

  // ---------- assets ----------
  var IMG = { soccer: 'img/soccer.png', basket: 'img/basket.png', tennis: 'img/tennis.png', volley: 'img/volley.png', coin: 'img/coin.png' };
  var SPORT_IMG = { '5-a-side soccer': IMG.soccer, 'Volleyball': IMG.volley, 'Beach tennis': IMG.tennis, 'Streetball': IMG.basket };
  var SPORTS = ['5-a-side soccer', 'Volleyball', 'Beach tennis', 'Streetball'];

  var ICON = {
    match: '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2"/><circle cx="12" cy="12" r="3.5"/>',
    items: '<path d="M3.5 7.5L12 3l8.5 4.5v9L12 21l-8.5-4.5z"/><path d="M3.5 7.5L12 12l8.5-4.5M12 12v9"/>',
    game: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5l4 2.9-1.5 4.7h-5L8 10.4z"/><path d="M12 3.5v4M16 10.4l4-1.2M14.5 15.1l2.4 3.4M9.5 15.1l-2.4 3.4M8 10.4L4 9.2"/>',
    analytics: '<path d="M4 20h16M7 16v-5M12 16V6M17 16v-8"/>',
    profile: '<circle cx="12" cy="8.5" r="4"/><path d="M4.5 20c1.3-3.6 4.2-5.5 7.5-5.5s6.2 1.9 7.5 5.5"/>',
    camera: '<path d="M3 8.5A2.5 2.5 0 0 1 5.5 6h1.6l1.4-2h7l1.4 2h1.6A2.5 2.5 0 0 1 21 8.5v9a2.5 2.5 0 0 1-2.5 2.5h-13A2.5 2.5 0 0 1 3 17.5z"/><circle cx="12" cy="13" r="3.6"/>',
    clip: '<path d="M20.5 11.5l-8.2 8.2a5 5 0 0 1-7-7l8.5-8.5a3.3 3.3 0 0 1 4.7 4.7l-8.4 8.4a1.7 1.7 0 0 1-2.4-2.4l7.7-7.7"/>',
    x: '<path d="M6 6l12 12M18 6L6 18"/>',
    check: '<path d="M5 12.5l4.5 4.5L19 7"/>'
  };
  function svg(name, size, stroke, width) {
    return '<svg width="' + (size || 26) + '" height="' + (size || 26) + '" viewBox="0 0 24 24" fill="none" stroke="' + (stroke || 'currentColor') + '" stroke-width="' + (width || 1.8) + '" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + ICON[name] + '</svg>';
  }
  function esc(s) { return String(s).replace(/[&<>"']/g, function (c) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]; }); }

  var TABS = [
    { id: 'match', label: 'Find a game', short: 'Match' },
    { id: 'items', label: 'Gear & players', short: 'Gear' },
    { id: 'game', label: 'Your game', short: 'Game' },
    { id: 'analytics', label: 'Analytics', short: 'Analytics' },
    { id: 'profile', label: 'Profile', short: 'Profile' }
  ];

  // ---------- state (persisted locally) ----------
  var KEY = 'lmyexitems.v1';
  var DEFAULT = {
    tab: 'match', stage: 'input',
    picked: { soccer: true, tennis: true, basket: false, coin: false },
    tags: { Outdoors: true, Team: true },
    itemsView: 'item', draftName: 'Volleyball', draftDesc: 'Almost new, size 5, inflated', draftSport: 'Volleyball',
    saved: [
      { name: 'Soccer ball', sport: '5-a-side soccer' },
      { name: 'Tennis balls ×3', sport: 'Beach tennis' },
      { name: 'Basketball', sport: 'Streetball' }
    ],
    filter: '5-a-side soccer', showForm: false, personName: '',
    people: [
      { name: 'Ethan Walker', sport: '5-a-side soccer', dist: '0.7 mi', invited: true },
      { name: 'Dina Shah', sport: '5-a-side soccer', dist: '0.5 mi', invited: false },
      { name: 'Liam Moore', sport: '5-a-side soccer', dist: '1.6 mi', invited: false },
      { name: 'Grace Kim', sport: '5-a-side soccer', dist: '2.1 mi', invited: false },
      { name: 'Vera Lane', sport: 'Volleyball', dist: '1.2 mi', invited: false },
      { name: 'Owen Price', sport: 'Volleyball', dist: '1.9 mi', invited: false },
      { name: 'Sasha Bell', sport: 'Beach tennis', dist: '0.3 mi', invited: true },
      { name: 'Ryan Ortiz', sport: 'Streetball', dist: '0.9 mi', invited: false }
    ],
    game: {
      cover: 'basket', players: 6, name: 'Golden Bounce', draft: '',
      idea: 'Two teams of 3 pass a basketball and score by landing it in a hoop lying on the ground. Every 5 minutes a “golden” tennis ball comes into play — a goal with it is worth 3 points.',
      rules: [
        'Field is 20×10 m (65×33 ft); each team has a hoop lying on the ground instead of a goal.',
        'You can’t hold the ball longer than 3 seconds or take more than 2 steps with it.',
        'Every 5 minutes a “golden” tennis ball is thrown in: a goal with it is worth 3 points.',
        'A match is 3 periods of 7 minutes. Ties go to a shoot-out from 5 m (16 ft).'
      ]
    },
    period: 'week', metric: 'signups', sel: 5,
    profile: { name: 'Alex Carter', date: '1998-05-14', about: 'I love team games outdoors. My closet is full of balls that have been waiting for their game.', notif: true },
    editing: false
  };
  function clone(o) { return JSON.parse(JSON.stringify(o)); }
  var S = clone(DEFAULT);
  try { var raw = localStorage.getItem(KEY); if (raw) { var saved = JSON.parse(raw); for (var k in saved) S[k] = saved[k]; } } catch (e) { /* storage unavailable: keep defaults */ }
  S.stage = S.stage === 'loading' ? 'result' : S.stage;
  function persist() { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) { /* ignore */ } }

  // ---------- data for analytics (sample) ----------
  var DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  var DATA = {
    week: { signups: [3, 5, 4, 6, 9, 14, 7], success: [50, 60, 40, 70, 85, 95, 80], rating: [3.6, 4.0, 3.2, 4.1, 4.5, 4.8, 4.4],
      kpis: [['Signed up', '48', '+12% vs last week'], ['Games played', '9', '+2 games'], ['Successful', '78%', '7 of 9'], ['Avg rating', '4.2', '+0.3']] },
    month: { signups: [12, 18, 15, 22, 31, 47, 29], success: [55, 62, 48, 66, 81, 92, 77], rating: [3.8, 3.9, 3.4, 4.0, 4.4, 4.7, 4.3],
      kpis: [['Signed up', '174', '+31% vs last month'], ['Games played', '34', '+8 games'], ['Successful', '74%', '25 of 34'], ['Avg rating', '4.1', '+0.2']] }
  };

  // ---------- helpers ----------
  function initials(name) { return (name || '').trim().split(/\s+/).map(function (w) { return w[0] || ''; }).join('').slice(0, 2).toUpperCase() || 'L'; }
  function seg(name, opts, current, lg) {
    var i = opts.map(function (o) { return o[0]; }).indexOf(current);
    return '<div class="seg' + (lg ? ' lg' : '') + '" role="tablist" style="--n:' + opts.length + '">' +
      '<span class="thumb" aria-hidden="true" style="width:calc((100% - 6px) / ' + opts.length + ');transform:translateX(' + (i * 100) + '%)"></span>' +
      opts.map(function (o) { return '<button role="tab" aria-selected="' + (o[0] === current) + '" data-action="set" data-key="' + name + '" data-val="' + o[0] + '">' + o[1] + '</button>'; }).join('') + '</div>';
  }
  function head(eyebrow, title, right) {
    return '<header class="page-head rise"><div class="stack">' + (eyebrow ? '<span class="eyebrow">' + eyebrow + '</span>' : '') + '<h1 class="h1">' + title + '</h1></div>' + (right || '') + '</header>';
  }

  // ---------- views ----------
  function viewMatch() {
    var gear = [['soccer', 'Soccer ball'], ['tennis', 'Tennis balls'], ['basket', 'Basketball'], ['coin', 'Token']];
    var selected = gear.filter(function (g) { return S.picked[g[0]]; }).length;
    var tags = ['Outdoors', 'Indoors', 'Team', 'One-on-one', 'Chill', 'Competitive'];
    var left =
      '<section class="card rise d1"><div class="between"><h2 class="h2">Photos of your gear</h2><span class="muted small">' + selected + ' selected</span></div>' +
      '<div class="gear-grid">' + gear.map(function (g) {
        return '<button class="gear press" data-action="pick" data-id="' + g[0] + '" aria-pressed="' + !!S.picked[g[0]] + '" aria-label="' + g[1] + '"><img src="' + IMG[g[0]] + '" alt=""><span>' + g[1] + '</span><span class="check">' + svg('check', 10, '#1A1309', 3.5) + '</span></button>';
      }).join('') + '</div>' +
      '<button class="btn-dashed press" data-action="toast" data-msg="Camera opens here in the full app">' + svg('camera', 20) + 'Take a photo of an item</button></section>' +
      '<section class="card rise d2"><label class="h2" for="mDesc">What kind of sport do you enjoy?</label>' +
      '<textarea id="mDesc" class="textarea" rows="3" placeholder="e.g. I want to play outdoors with friends on weekends, I like running, I’m not into rough contact"></textarea>' +
      '<div class="chips">' + tags.map(function (t) { return '<button class="chip press" data-action="tag" data-id="' + t + '" aria-pressed="' + !!S.tags[t] + '">' + t + '</button>'; }).join('') + '</div></section>' +
      '<button class="btn-gold rise d3" data-action="run"><span class="sheen" aria-hidden="true"></span><span>Match me with a game</span></button>';

    var right;
    if (S.stage === 'loading') {
      right = '<div class="analyzing"><div class="orbit"><div class="spin"></div><img src="video/loader.gif" alt=""></div>' +
        '<div class="stack" style="align-items:center;gap:4px"><span class="h2">Analyzing your gear…</span><span class="muted small">Comparing your items with 40+ sports</span></div></div>';
    } else if (S.stage === 'result') {
      var res = [
        ['5-a-side soccer', 92, IMG.soccer, 'You have a ball and picked outdoors + team. You need 7 more players.'],
        ['Beach tennis', 78, IMG.tennis, 'You already have balls; rackets can be rented.'],
        ['3×3 streetball', 61, IMG.basket, 'A fit once you add a basketball to your gear.']
      ];
      right = '<div class="between"><h2 class="h2 big">Your matches</h2><button class="btn-ghost press" data-action="reset">Reset</button></div>' +
        res.map(function (r, i) {
          return '<article class="match rise' + (i === 0 ? ' best' : '') + '" style="animation-delay:' + (0.08 * (i + 1)) + 's"><div class="ring" style="background:conic-gradient(var(--gold) ' + Math.round(r[1] * 3.6) + 'deg, rgba(255,255,255,.08) 0)"><div>' + r[1] + '%</div></div>' +
            '<div class="grow" style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px"><div class="row" style="gap:8px"><img src="' + r[2] + '" alt="" width="22" height="22"><h3 class="h2" style="font-size:17px">' + r[0] + '</h3></div><p class="muted small" style="margin:0;color:#B9B1A2">' + r[3] + '</p></div></article>';
        }).join('') +
        '<button class="btn-soft press rise d4" data-nav="items" data-people="1">Find players for 5-a-side</button>';
    } else {
      right = '<div class="empty"><div class="row" style="gap:6px"><img src="' + IMG.soccer + '" alt="" width="44" height="44"><img src="' + IMG.tennis + '" alt="" width="36" height="36"><img src="' + IMG.basket + '" alt="" width="44" height="44"></div>' +
        '<span class="h2" style="font-size:17px">Pick your gear, then tap Match</span><span class="muted small" style="max-width:260px">We compare your items and wishes with 40+ sports and show the best fits here.</span></div>';
    }
    return head('L my ex items', 'Find a game') +
      '<div class="cols wide-left"><div class="col">' + left + '</div><aside class="col card gold rise d2 sticky">' + right + '</aside></div>';
  }

  function viewItems() {
    var chip = function (key, val) { return '<button class="chip press" data-action="set" data-key="' + key + '" data-val="' + esc(val) + '" aria-pressed="' + (S[key] === val) + '">' + esc(val) + '</button>'; };
    var item =
      '<section class="card rise d1"><h2 class="h2">Describe an item</h2>' +
      '<div class="row" style="gap:14px"><div style="flex:none;width:72px;height:72px;border-radius:18px;display:flex;align-items:center;justify-content:center;background:radial-gradient(circle at 40% 35%,rgba(230,194,122,.25),rgba(255,255,255,.03));border:1px solid rgba(230,194,122,.3)"><img src="' + (SPORT_IMG[S.draftSport] || IMG.volley) + '" alt="Item photo" width="54" height="54"></div>' +
      '<div class="field" style="flex:1;min-width:0"><label for="iName">Name</label><input id="iName" class="input" data-model="draftName" value="' + esc(S.draftName) + '" placeholder="Volleyball"></div></div>' +
      '<div class="field"><label for="iDesc">Description</label><textarea id="iDesc" class="textarea" rows="2" data-model="draftDesc" placeholder="Condition, size, where it’s kept">' + esc(S.draftDesc) + '</textarea></div>' +
      '<div class="field"><span class="label">Good for</span><div class="chips">' + SPORTS.map(function (s) { return chip('draftSport', s); }).join('') + '</div></div>' +
      '<button class="btn-gold sm" data-action="saveItem"><span>Save to collection</span></button></section>' +
      '<section class="stack rise d2"><div class="between"><h2 class="h2 big">My gear</h2><span class="muted small">' + S.saved.length + ' items</span></div>' +
      S.saved.map(function (s, i) { return '<article class="list-row' + (i === 0 && S.justAdded === 'item' ? ' pop' : '') + '"><img src="' + (SPORT_IMG[s.sport] || IMG.coin) + '" alt="" width="40" height="40"><div class="grow"><span class="title">' + esc(s.name) + '</span><span class="muted small">' + esc(s.sport) + '</span></div></article>'; }).join('') + '</section>';

    var grads = ['#F1D48E,#A8752F', '#E3A189,#9C4E37', '#D9C7A5,#7E6A4B', '#C9785A,#7A3326'];
    var people =
      '<section class="card rise d1"><div class="between"><h2 class="h2">Players to invite</h2><button class="btn-ghost press" data-action="toggleForm">' + (S.showForm ? 'Cancel' : '+ Add person') + '</button></div>' +
      '<div class="chips">' + SPORTS.map(function (s) { return chip('filter', s); }).join('') + '</div>' +
      (S.showForm ? '<div class="add-row pop" style="align-items:flex-end"><div class="field" style="flex:1;min-width:0"><label for="pName">Full name</label><input id="pName" class="input" data-model="personName" value="' + esc(S.personName) + '" placeholder="e.g. Maya Brooks"></div><button class="btn-gold sm" style="width:auto;padding:0 20px;height:46px" data-action="addPerson"><span>Add</span></button></div>' : '') +
      '</section>' +
      S.people.filter(function (p) { return p.sport === S.filter; }).map(function (p, i) {
        return '<article class="list-row rise" style="animation-delay:' + (0.04 * i) + 's"><span class="avatar" style="background:linear-gradient(145deg,' + grads[i % 4] + ')">' + esc(initials(p.name)) + '</span>' +
          '<div class="grow"><span class="title">' + esc(p.name) + '</span><span class="muted small">' + esc(p.sport) + ' · ' + esc(p.dist) + '</span></div>' +
          '<button class="invite press" data-action="invite" data-id="' + esc(p.name) + '" aria-pressed="' + p.invited + '">' + (p.invited ? 'Invited ✓' : 'Invite') + '</button></article>';
      }).join('');

    var isPhone = !window.matchMedia('(min-width:768px)').matches;
    if (isPhone) {
      return head('Collection', 'Gear &amp; players') + '<div class="rise d1">' + seg('itemsView', [['item', 'Describe an item'], ['people', 'Players']], S.itemsView, true) + '</div>' +
        (S.itemsView === 'item' ? item : people);
    }
    return head('Collection', 'Gear &amp; players') + '<div class="cols"><div class="col">' + item + '</div><div class="col">' + people + '</div></div>';
  }

  function viewGame() {
    var g = S.game;
    var covers = ['basket', 'tennis', 'soccer', 'volley'];
    var left =
      '<section class="cover rise d1"><span class="halo" style="width:280px;height:280px"></span><span class="halo" style="width:210px;height:210px;opacity:.7"></span>' +
      '<img class="main float" src="' + IMG[g.cover] + '" alt="Game cover"><img class="c1 float" src="' + IMG.coin + '" alt=""><img class="c2 float" src="' + IMG.coin + '" alt=""><span class="tag">Cover photo</span></section>' +
      '<div class="cover-pick rise d2">' + covers.map(function (c) { return '<button class="press" data-action="cover" data-id="' + c + '" aria-pressed="' + (g.cover === c) + '" aria-label="Choose cover"><img src="' + IMG[c] + '" alt=""></button>'; }).join('') +
      '<button class="press" style="border-style:dashed;border-color:rgba(230,194,122,.45);background:transparent;color:var(--gold)" data-action="toast" data-msg="Photo picker opens here in the full app" aria-label="Attach your own photo">' + svg('clip', 22) + '</button></div>' +
      '<section class="card rise d3"><div class="field"><label for="gName">Game name</label><input id="gName" class="input title" data-model="game.name" value="' + esc(g.name) + '"></div>' +
      '<div class="field"><label for="gIdea">The idea</label><textarea id="gIdea" class="textarea" rows="4" data-model="game.idea">' + esc(g.idea) + '</textarea></div>' +
      '<div class="between"><span style="font-size:15px;font-weight:500">Players</span><div class="stepper"><button class="press" data-action="players" data-d="-1" aria-label="Fewer players">−</button><span>' + g.players + '</span><button class="press" data-action="players" data-d="1" aria-label="More players">+</button></div></div></section>';
    var right =
      '<div class="between rise d2"><h2 class="h2 big">Rules</h2><span class="muted small">' + g.rules.length + ' rules</span></div>' +
      '<ol class="rules rise d3">' + g.rules.map(function (r, i) {
        return '<li' + (i === g.rules.length - 1 && S.justAdded === 'rule' ? ' class="pop"' : '') + '><span class="n">' + (i + 1) + '</span><span class="t">' + esc(r) + '</span><button class="x press" data-action="delRule" data-i="' + i + '" aria-label="Delete rule">' + svg('x', 16, 'currentColor', 2) + '</button></li>';
      }).join('') + '</ol>' +
      '<div class="add-row rise d4"><label class="sr" for="gRule">New rule</label><input id="gRule" class="input" data-model="game.draft" value="' + esc(g.draft) + '" placeholder="Add a rule…"><button class="sq press" data-action="addRule" aria-label="Add rule">+</button></div>' +
      '<button class="btn-gold rise d5" data-action="publish"><span class="sheen" aria-hidden="true"></span><span>Publish &amp; invite players</span></button>';
    return head('Game builder', 'Your game') + '<div class="cols"><div class="col">' + left + '</div><div class="col">' + right + '</div></div>';
  }

  function viewAnalytics() {
    var D = DATA[S.period];
    var vals = D[S.metric];
    var max = S.metric === 'signups' ? Math.max.apply(null, vals) : 100;
    var best = vals.indexOf(Math.max.apply(null, vals));
    var bars = vals.map(function (v, i) {
      var h = Math.max(6, Math.round(v / max * 160));
      var label = S.metric === 'signups' ? v + ' people' : v + '%';
      return '<button data-action="bar" data-i="' + i + '" aria-label="' + DAYS[i] + ': ' + label + '">' + (S.sel === i ? '<span class="bar-tip">' + label + '</span>' : '') +
        '<span class="bar' + (S.sel === i ? ' on' : (i === best ? ' best' : '')) + '" style="height:' + h + 'px;animation-delay:' + (0.05 * i) + 's"></span></button>';
    }).join('');
    // line chart in % coordinates so it scales with the card
    var pts = D.rating.map(function (r, i) { return [(i + 0.5) / 7 * 100, 100 - ((r - 2.5) / 2.5) * 86 - 7]; });
    var poly = pts.map(function (p) { return p[0].toFixed(2) + ',' + p[1].toFixed(2); }).join(' ');
    var line = '<div class="linechart"><svg viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true"><defs><linearGradient id="lg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E6C27A" stop-opacity=".28"/><stop offset="1" stop-color="#E6C27A" stop-opacity="0"/></linearGradient></defs>' +
      '<polygon points="' + poly + ' ' + pts[6][0].toFixed(2) + ',100 ' + pts[0][0].toFixed(2) + ',100" fill="url(#lg)"/>' +
      '<polyline class="line" points="' + poly + '" fill="none" stroke="#E6C27A" stroke-width="2" vector-effect="non-scaling-stroke" stroke-linejoin="round" stroke-linecap="round"/></svg>' +
      pts.map(function (p, i) { return '<span class="dot" title="' + DAYS[i] + ': ' + D.rating[i] + ' ★" style="left:' + p[0] + '%;top:' + p[1] + '%;animation-delay:' + (0.6 + 0.08 * i) + 's' + (i === 5 ? ';background:var(--gold-hi)' : '') + '"></span>'; }).join('') + '</div>';
    var games = [
      ['5-a-side soccer', 'Sat · 10 players · 4.8 ★', true, IMG.soccer], ['Golden Bounce', 'Fri · 6 players · 4.5 ★', true, IMG.basket],
      ['3×3 streetball', 'Wed · 3 of 6 showed up', false, IMG.basket], ['Beach tennis', 'Sun · 4 players · 4.4 ★', true, IMG.tennis]
    ];
    return head('Sample data', 'Analytics', seg('period', [['week', 'Week'], ['month', 'Month']], S.period)) +
      '<div class="kpis rise d1">' + D.kpis.map(function (k, i) { return '<div class="kpi' + (i === 3 ? ' kpi-x' : '') + '"><span class="muted small">' + k[0] + '</span><b>' + k[1] + '</b><em>' + k[2] + '</em></div>'; }).join('') + '</div>' +
      '<div class="cols">' +
      '<section class="card rise d2"><div class="between"><h2 class="h2">By day of week</h2>' + seg('metric', [['signups', 'Sign-ups'], ['success', 'Success']], S.metric) + '</div>' +
      '<p class="small" style="margin:0;color:#B9B1A2">' + (S.metric === 'signups' ? 'How many people signed up for games. Tap a bar.' : 'Share of games that happened and were rated 4+.') + '</p>' +
      '<div class="bars"><span class="gl" style="top:24px"></span><span class="gl" style="top:107px"></span>' + bars + '</div><div class="days">' + DAYS.map(function (d) { return '<span>' + d + '</span>'; }).join('') + '</div></section>' +
      '<section class="card rise d3"><div class="between"><h2 class="h2">Average game rating</h2><span class="muted small">out of 5</span></div>' +
      '<p class="small" style="margin:0;color:#B9B1A2">Saturday is the best day: ' + D.rating[5] + ' ★. Wednesday dips — fewer people on weekdays.</p>' + line +
      '<div class="days">' + DAYS.map(function (d) { return '<span>' + d + '</span>'; }).join('') + '</div></section></div>' +
      '<section class="stack rise d4"><h2 class="h2 big">Recent games</h2><div class="stack grid-2-tab">' + games.map(function (g) {
        return '<article class="list-row"><img src="' + g[3] + '" alt="" width="38" height="38"><div class="grow"><span class="title">' + g[0] + '</span><span class="muted small">' + g[1] + '</span></div><span class="badge ' + (g[2] ? 'ok">✓ Success' : 'bad">✕ Not enough players') + '</span></article>';
      }).join('') + '</div></section>';
  }

  function viewProfile() {
    var p = S.profile;
    var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    var parts = (p.date || '').split('-');
    var dateText = parts.length === 3 ? months[+parts[1] - 1] + ' ' + (+parts[2]) + ', ' + parts[0] : 'not set';
    var invited = S.people.filter(function (x) { return x.invited; }).length;
    var stats = [[S.saved.length, 'items saved', 'items'], [9, 'games played', 'analytics'], [2, 'games created', 'game'], [invited, 'people invited', 'items']];
    var card = '<section class="card gold rise d1 hero-profile"><div class="halo-avatar"><span class="r"></span><span class="g"></span><span class="a">' + esc(initials(p.name)) + '</span><img src="' + IMG.coin + '" alt="Gold level"></div>' +
      (S.editing
        ? '<div class="stack pop" style="align-self:stretch;text-align:left">' +
          '<div class="field"><label for="pfName">Name</label><input id="pfName" class="input" data-model="profile.name" value="' + esc(p.name) + '"></div>' +
          '<div class="field"><label for="pfDate">Date of birth</label><input id="pfDate" class="input" type="date" data-model="profile.date" value="' + esc(p.date) + '"></div>' +
          '<div class="field"><label for="pfAbout">About me</label><textarea id="pfAbout" class="textarea" rows="3" data-model="profile.about">' + esc(p.about) + '</textarea></div>' +
          '<button class="btn-gold sm" data-action="saveProfile"><span>Save</span></button></div>'
        : '<div class="stack" style="align-items:center;gap:4px"><span style="font-size:26px;font-weight:700;letter-spacing:-.02em">' + esc(p.name) + '</span><span class="muted" style="font-size:14px">Born ' + esc(dateText) + ' · Gold level</span>' +
          '<p style="margin:8px 0 0;max-width:340px;font-size:15px;line-height:1.5;color:var(--text-2)">' + esc(p.about) + '</p></div>') + '</section>';
    var right = '<section class="stats rise d2">' + stats.map(function (s, i) { return '<button class="stat press" data-nav="' + s[2] + '"><b class="gold-text" style="animation-delay:' + (0.15 + i * 0.07) + 's">' + s[0] + '</b><span>' + s[1] + '</span></button>'; }).join('') + '</section>' +
      '<section class="stack rise d3"><h2 class="h2">Favorite sports</h2><div class="chips">' +
      '<span class="chip img" aria-pressed="true"><img src="' + IMG.soccer + '" alt="">5-a-side soccer</span><span class="chip img"><img src="' + IMG.tennis + '" alt="">Beach tennis</span><span class="chip img"><img src="' + IMG.basket + '" alt="">Streetball</span></div></section>' +
      '<section class="settings rise d4"><div><span id="nl">Game invitations</span><button class="switch" role="switch" aria-labelledby="nl" aria-checked="' + p.notif + '" data-action="notif"></button></div>' +
      '<button data-action="signout" style="color:var(--coral)">Reset demo data</button></section>';
    return head('', 'Profile', '<button class="btn-ghost press" data-action="edit">' + (S.editing ? 'Cancel' : 'Edit') + '</button>') +
      '<div class="cols wide-right"><div class="col">' + card + '</div><div class="col">' + right + '</div></div>';
  }

  var VIEWS = { match: viewMatch, items: viewItems, game: viewGame, analytics: viewAnalytics, profile: viewProfile };

  // ---------- rendering ----------
  var view = document.getElementById('view');
  var lastTab = null;
  function renderNav() {
    document.getElementById('tabbar').innerHTML = TABS.map(function (t) {
      return '<button class="tab" data-nav="' + t.id + '"' + (S.tab === t.id ? ' aria-current="page"' : '') + '>' + svg(t.id, 26) + '<span>' + t.short + '</span></button>';
    }).join('');
    document.getElementById('sideLinks').innerHTML = TABS.map(function (t) {
      return '<button class="side-link" data-nav="' + t.id + '"' + (S.tab === t.id ? ' aria-current="page"' : '') + '>' + svg(t.id, 22) + '<span>' + t.label + '</span></button>';
    }).join('');
    document.getElementById('sideName').textContent = S.profile.name;
    document.getElementById('sideAvatar').textContent = initials(S.profile.name);
  }
  function render() {
    var changed = lastTab !== S.tab;
    var top = changed ? 0 : view.scrollTop;
    view.innerHTML = '<div class="page' + (changed ? ' enter' : ' settled') + '">' + VIEWS[S.tab]() + '</div>';
    if (!changed) { // keep entrance animations from replaying on every tap
      Array.prototype.forEach.call(view.querySelectorAll('.rise'), function (el) { el.style.animation = 'none'; });
    }
    view.scrollTop = top;
    lastTab = S.tab;
    S.justAdded = null;
    renderNav();
    persist();
  }

  var toastTimer;
  function toast(msg) {
    var t = document.getElementById('toast');
    t.innerHTML = '<span class="ok">' + svg('check', 16, '#1A1309', 3) + '</span><span>' + esc(msg) + '</span>';
    t.hidden = false; t.style.animation = 'none'; void t.offsetWidth; t.style.animation = '';
    clearTimeout(toastTimer); toastTimer = setTimeout(function () { t.hidden = true; }, 2600);
  }
  function haptic() { try { if (navigator.vibrate) navigator.vibrate(8); } catch (e) { /* no-op */ } }

  // ---------- events ----------
  var runTimer;
  var actions = {
    start: function () { enterApp('match'); },
    'start-profile': function () { enterApp('profile'); },
    set: function (el) { S[el.dataset.key] = el.dataset.val; if (el.dataset.key === 'metric' || el.dataset.key === 'period') S.sel = 5; },
    pick: function (el) { S.picked[el.dataset.id] = !S.picked[el.dataset.id]; },
    tag: function (el) { S.tags[el.dataset.id] = !S.tags[el.dataset.id]; },
    run: function () { S.stage = 'loading'; clearTimeout(runTimer); runTimer = setTimeout(function () { S.stage = 'result'; render(); haptic(); }, 1900);
      if (!window.matchMedia('(min-width:768px)').matches) setTimeout(function () { var a = view.querySelector('aside'); if (a) a.scrollIntoView({ behavior: 'smooth', block: 'start' }); }, 30); },
    reset: function () { S.stage = 'input'; },
    saveItem: function () { S.saved.unshift({ name: (S.draftName || 'New item').trim(), sport: S.draftSport }); S.draftName = ''; S.justAdded = 'item'; toast('Saved to your collection'); },
    toggleForm: function () { S.showForm = !S.showForm; },
    addPerson: function () { var n = (S.personName || '').trim(); if (!n) return false; S.people.unshift({ name: n, sport: S.filter, dist: 'new', invited: false }); S.personName = ''; S.showForm = false; toast(n + ' added to players'); },
    invite: function (el) { S.people.forEach(function (p) { if (p.name === el.dataset.id) p.invited = !p.invited; }); haptic(); },
    cover: function (el) { S.game.cover = el.dataset.id; },
    players: function (el) { S.game.players = Math.max(2, Math.min(22, S.game.players + (+el.dataset.d))); },
    delRule: function (el) { S.game.rules.splice(+el.dataset.i, 1); },
    addRule: function () { var r = (S.game.draft || '').trim(); if (!r) return false; S.game.rules.push(r); S.game.draft = ''; S.justAdded = 'rule'; },
    publish: function () { toast('“' + S.game.name + '” is live — invites sent to ' + S.game.players + ' players'); haptic(); return false; },
    bar: function (el) { var i = +el.dataset.i; S.sel = S.sel === i ? -1 : i; },
    edit: function () { S.editing = !S.editing; },
    saveProfile: function () { S.editing = false; toast('Profile saved'); },
    notif: function () { S.profile.notif = !S.profile.notif; },
    signout: function () { var keepTab = S.tab; S = clone(DEFAULT); S.tab = keepTab; toast('Demo data reset'); },
    toast: function (el) { toast(el.dataset.msg); return false; }
  };

  document.addEventListener('click', function (e) {
    var nav = e.target.closest('[data-nav]');
    if (nav) {
      S.tab = nav.dataset.nav;
      if (nav.dataset.people) { S.itemsView = 'people'; S.filter = '5-a-side soccer'; }
      render(); view.focus({ preventScroll: true }); return;
    }
    var el = e.target.closest('[data-action]');
    if (!el) return;
    var fn = actions[el.dataset.action];
    if (fn && fn(el) !== false) render();
  });

  // live inputs update state without re-rendering (keeps focus and caret)
  document.addEventListener('input', function (e) {
    var key = e.target.dataset && e.target.dataset.model;
    if (!key) return;
    var path = key.split('.'), obj = S;
    for (var i = 0; i < path.length - 1; i++) obj = obj[path[i]];
    obj[path[path.length - 1]] = e.target.value;
    if (key === 'profile.name') { document.getElementById('sideName').textContent = e.target.value; }
    persist();
  });
  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Enter' || !e.target.dataset) return;
    if (e.target.id === 'gRule') { e.preventDefault(); if (actions.addRule() !== false) render(); }
    if (e.target.id === 'pName') { e.preventDefault(); if (actions.addPerson() !== false) render(); }
  });

  var mq = window.matchMedia('(min-width:768px)');
  (mq.addEventListener ? mq.addEventListener.bind(mq, 'change') : mq.addListener.bind(mq))(function () { lastTab = S.tab; render(); });

  // ---------- splash → app ----------
  var splash = document.getElementById('splash');
  var app = document.getElementById('app');
  var entered = false;
  function enterApp(tab) {
    if (entered) return; entered = true;
    if (tab) S.tab = tab;
    app.hidden = false; render();
    splash.classList.add('out');
    setTimeout(function () { splash.hidden = true; }, 560);
  }
})();
