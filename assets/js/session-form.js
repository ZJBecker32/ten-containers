/* Cook-session capture, phone-side.
 *
 * Port of scripts/session-report.rb. Same arithmetic, same 5% tolerance, same
 * output shape — so a session recorded here and one recorded on a laptop
 * produce identical edits.
 *
 * Nothing is sent anywhere. Entries live in localStorage so a cook that runs
 * four hours survives the phone backgrounding the page.
 */
(function () {
  'use strict';

  var root = document.getElementById('sf');
  var dataEl = document.getElementById('sf-data');
  if (!root || !dataEl) { return; }

  var R = JSON.parse(dataEl.textContent);
  var KEY = 'tc-session-' + R.slug;
  var TOLERANCE = 0.05;

  var components = Object.keys(R.perContainer || {});
  var isDry = function (name) { return /rice|grain|oat/i.test(name); };

  // Names the row this component would update in standing-parameters.
  function yieldKey(name) {
    if (/meat|beef|turkey|chicken|pork|protein/i.test(name)) {
      return (R.proteinSource || name).replace(/-/g, '_');
    }
    if (isDry(name)) { return 'jasmine_rice'; }
    return name;
  }

  function today() {
    var d = new Date();
    return d.getFullYear() + '-' +
      String(d.getMonth() + 1).padStart(2, '0') + '-' +
      String(d.getDate()).padStart(2, '0');
  }

  function num(v) {
    if (v === null || v === undefined || String(v).trim() === '') { return null; }
    var n = parseFloat(v);
    return isFinite(n) ? n : null;
  }

  function round(n, places) {
    var f = Math.pow(10, places);
    return Math.round(n * f) / f;
  }

  // ---- build the rows --------------------------------------------------
  var tbody = document.getElementById('sf-rows');
  components.forEach(function (c) {
    var planned = R.perContainer[c] * R.containers;
    var tr = document.createElement('tr');
    tr.innerHTML =
      '<th>' + c.replace(/_/g, ' ') +
      '<span class="sf-planned">plan ' + planned + ' g</span></th>' +
      '<td><input type="number" inputmode="decimal" step="any" data-c="' + c +
      '" data-f="raw" placeholder="' + (isDry(c) ? 'cups dry' : 'raw g') + '"></td>' +
      '<td><input type="number" inputmode="decimal" step="any" data-c="' + c +
      '" data-f="cooked" placeholder="cooked g"></td>';
    tbody.appendChild(tr);
  });

  var inputs = Array.prototype.slice.call(root.querySelectorAll('input, textarea'));
  var dateEl = document.getElementById('sf-date');
  var activeEl = document.getElementById('sf-active');
  var totalEl = document.getElementById('sf-total');
  var notesEl = document.getElementById('sf-notes');
  var outEl = document.getElementById('sf-out');
  var hintEl = document.getElementById('sf-hint');

  // ---- persistence -----------------------------------------------------
  function save() {
    var s = { date: dateEl.value, active: activeEl.value, total: totalEl.value,
              notes: notesEl.value, m: {} };
    root.querySelectorAll('[data-c]').forEach(function (i) {
      s.m[i.dataset.c + '.' + i.dataset.f] = i.value;
    });
    try { localStorage.setItem(KEY, JSON.stringify(s)); } catch (e) { /* private mode */ }
  }

  function load() {
    var s;
    try { s = JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) { s = null; }
    if (!s) { dateEl.value = today(); return; }
    dateEl.value = s.date || today();
    activeEl.value = s.active || '';
    totalEl.value = s.total || '';
    notesEl.value = s.notes || '';
    root.querySelectorAll('[data-c]').forEach(function (i) {
      i.value = (s.m && s.m[i.dataset.c + '.' + i.dataset.f]) || '';
    });
  }

  // ---- the arithmetic --------------------------------------------------
  function analyse() {
    var observed = [];   // [key, value, priorOrNull]
    var lines = [];      // human-readable "against plan"
    var edits = {};      // field -> text, keyed so one component gives one edit
    var notWeighed = [];

    components.forEach(function (c) {
      var raw = num(root.querySelector('[data-c="' + c + '"][data-f="raw"]').value);
      var cooked = num(root.querySelector('[data-c="' + c + '"][data-f="cooked"]').value);
      if (cooked === null) { notWeighed.push(c); return; }

      var per = R.perContainer[c];
      var plannedTotal = per * R.containers;
      var achievable = Math.floor(cooked / R.containers);
      var label = c.replace(/_/g, ' ');

      if (raw !== null && raw > 0) {
        if (isDry(c)) {
          var perCup = Math.round(cooked / raw);
          observed.push([yieldKey(c) + '_g_per_cup_dry', perCup]);
        } else {
          observed.push([yieldKey(c), round(cooked / raw, 3)]);
        }
      }

      var delta = cooked - plannedTotal;
      var pct = Math.abs(delta) / plannedTotal;
      if (pct <= TOLERANCE) {
        lines.push('  ' + label + ': ' + cooked + ' g — on target (planned ' +
                   plannedTotal + ', ' + (delta >= 0 ? '+' : '') + delta + ')');
      } else if (delta < 0) {
        var l = '  ' + label + ': ' + cooked + ' g — SHORT ' + delta +
                ' g against ' + plannedTotal + '\n' +
                '    → ' + achievable + ' g per container is what this batch supports';
        if (raw !== null && raw > 0 && !isDry(c)) {
          var neededRaw = Math.round(plannedTotal / (cooked / raw));
          l += '\n    → or buy ' + neededRaw + ' g raw (+' + (neededRaw - raw) +
               ' g) to hit ' + per + ' g';
        }
        lines.push(l);
        edits['per_container.' + c] = 'per_container.' + c + ': ' + per + ' -> ' + achievable;
      } else {
        lines.push('  ' + label + ': ' + cooked + ' g — surplus +' + delta +
                   ' g; ' + achievable + ' g per container available');
      }
    });

    var act = num(activeEl.value);
    var tot = num(totalEl.value);
    if (act !== null && act !== R.activeTime) {
      edits.active_time_min = 'active_time_min: ' + R.activeTime + ' -> ' + act;
    }
    if (tot !== null && tot !== R.totalTime) {
      edits.total_time_min = 'total_time_min: ' + R.totalTime + ' -> ' + tot;
    }

    return { observed: observed, lines: lines, edits: edits, notWeighed: notWeighed };
  }

  function editsText() {
    var a = analyse();
    var out = [];

    if (a.observed.length) {
      out.push('OBSERVED YIELDS');
      a.observed.forEach(function (o) {
        var prior = R.priorYields ? R.priorYields[o[0]] : null;
        out.push('  ' + o[0] + ': ' + o[1] +
                 (prior != null && prior !== o[1] ? '   (recipe had ' + prior + ')' : ''));
      });
      out.push('');
      out.push('  Paste into the recipe yields: block');
      out.push('');
      a.observed.forEach(function (o) { out.push('    ' + o[0] + ': ' + o[1]); });
      out.push('');
    }

    if (a.lines.length) {
      out.push('AGAINST PLAN');
      a.lines.forEach(function (l) { out.push(l); });
      out.push('');
    }

    if (a.notWeighed.length) {
      out.push('NOT WEIGHED: ' + a.notWeighed.join(', '));
      out.push('');
    }

    // Grouped by file rather than repeating the path on every line — on a
    // phone the repeated prefix wraps every edit onto three lines.
    out.push('TO PROMOTE TO dialed-in');
    out.push('');
    out.push('recipes/' + R.slug + '.md');
    Object.keys(a.edits).forEach(function (k) { out.push('  ' + a.edits[k]); });
    if (a.observed.length) { out.push('  yields: fill from the block above'); }
    out.push('  last_cooked: ' + (dateEl.value || today()));
    out.push('  version: ' + R.version + ' -> ' + (R.version + 1));
    if (R.status !== 'dialed-in') {
      out.push('  status: ' + R.status + ' -> dialed-in');
    }

    var moved = a.observed.filter(function (o) {
      var prior = R.priorYields ? R.priorYields[o[0]] : null;
      return prior != null && prior !== o[1];
    });
    out.push('');
    out.push('docs/standing-parameters.md');
    if (moved.length) {
      out.push('  these moved — update by hand:');
      moved.forEach(function (o) {
        out.push('    ' + o[0] + ': ' + R.priorYields[o[0]] + ' -> ' + o[1]);
      });
    } else {
      out.push('  nothing observed that contradicts it');
    }
    out.push('');
    out.push('Then re-run scripts/export-crumb.rb so the Crouton file matches.');

    return out.join('\n');
  }

  // Mirrors the format scripts/new-session.rb writes, so a session captured
  // here is byte-compatible with one captured on a laptop.
  function sessionFile() {
    var out = ['---', 'recipe: ' + R.slug, 'date: ' + (dateEl.value || today()),
               'version_cooked: ' + R.version, ''];
    out.push('active_time_min:' + (activeEl.value ? ' ' + activeEl.value : ''));
    out.push('total_time_min:' + (totalEl.value ? ' ' + totalEl.value : ''));
    out.push('');
    out.push('measurements:');
    components.forEach(function (c) {
      var raw = root.querySelector('[data-c="' + c + '"][data-f="raw"]').value;
      var cooked = root.querySelector('[data-c="' + c + '"][data-f="cooked"]').value;
      out.push('  ' + c + ':');
      out.push((isDry(c) ? '    dry_cups:' : '    raw_g:') + (raw ? ' ' + raw : ''));
      out.push('    cooked_g:' + (cooked ? ' ' + cooked : ''));
      out.push('    yield_key: ' + yieldKey(c));
    });
    out.push('---', '');
    out.push('## What happened', '');
    out.push(notesEl.value.trim() || '(nothing recorded)');
    out.push('');
    return out.join('\n');
  }

  function render() {
    var anything = components.some(function (c) {
      return num(root.querySelector('[data-c="' + c + '"][data-f="cooked"]').value) !== null;
    });
    outEl.textContent = anything ? editsText()
      : 'Enter a cooked weight to see yields and the edits to make.';
    outEl.classList.toggle('sf-empty', !anything);
    save();
  }

  function copy(text, label) {
    function done(ok) {
      hintEl.textContent = ok ? label + ' copied.' : 'Copy failed — select the text above instead.';
      setTimeout(function () { hintEl.textContent = ''; }, 4000);
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(function () { done(true); },
                                               function () { done(false); });
    } else {
      done(false);
    }
  }

  load();
  render();
  inputs.forEach(function (i) { i.addEventListener('input', render); });
  root.querySelectorAll('[data-c]').forEach(function (i) { i.addEventListener('input', render); });

  document.getElementById('sf-copy-edits')
    .addEventListener('click', function () { copy(editsText(), 'Edits'); });
  document.getElementById('sf-copy-file')
    .addEventListener('click', function () { copy(sessionFile(), 'Session file'); });
  document.getElementById('sf-clear').addEventListener('click', function () {
    if (!window.confirm('Clear the weights recorded for this recipe?')) { return; }
    try { localStorage.removeItem(KEY); } catch (e) { /* ignore */ }
    root.querySelectorAll('[data-c]').forEach(function (i) { i.value = ''; });
    activeEl.value = ''; totalEl.value = ''; notesEl.value = '';
    dateEl.value = today();
    render();
  });
})();
