// Spyder-style Variable Explorer pane for the FOC Python Terminal.
// Talks to varexplorer.py through a call(method, params) function.
(function (global) {
  'use strict';

  const PAGE_ROWS = 100;
  const PAGE_COLS = 50;
  const HISTORY_EXPAND_MIN = 2;
  const STORAGE_KEY = 'foc.varexplorer';
  const METHOD = Object.freeze({
    LIST: 'list_vars', VALUE: 'get_value', TEXT: 'get_text', SET: 'set_value',
    DELETE: 'delete_var', CLEAR_ALL: 'clear_all', HISTORY: 'get_history',
    CELL: 'cell_source', TRACE: 'set_trace',
  });
  const VIEW_KIND = Object.freeze({ TABLE: 'table', TEXT: 'text' });
  const FILTERS = Object.freeze([
    { key: 'exclude_private', label: 'Hide _private names', initial: true },
    { key: 'exclude_uppercase', label: 'Hide ALL-CAPS constants', initial: false },
    { key: 'exclude_capitalized', label: 'Hide Capitalized names', initial: false },
    { key: 'exclude_callables_and_modules', label: 'Hide functions and modules', initial: true },
  ]);

  // Build a DOM node. Text always goes in through textContent, never innerHTML.
  function h(tag, attrs, ...children) {
    const el = document.createElement(tag);
    Object.entries(attrs || {}).forEach(([k, v]) => {
      if (k === 'class') el.className = v;
      else if (k === 'text') el.textContent = v;
      else if (k.startsWith('on')) el.addEventListener(k.slice(2), v);
      else if (v !== undefined && v !== null && v !== false) el.setAttribute(k, v === true ? '' : v);
    });
    children.flat().filter(c => c !== null && c !== undefined && c !== false)
      .forEach(c => el.append(c instanceof Node ? c : document.createTextNode(String(c))));
    return el;
  }

  function loadPrefs() {
    const defaults = {
      filters: Object.fromEntries(FILTERS.map(f => [f.key, f.initial])),
      trace: true,
    };
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
      return { filters: Object.assign(defaults.filters, saved.filters), trace: saved.trace ?? defaults.trace };
    } catch (e) {
      return defaults;
    }
  }

  class VarPane {
    /**
     * @param {HTMLElement} root   container for the pane
     * @param {object} opts
     *   call(method, params): returns the method's result or throws Error
     *   onChange():            called after the pane edits the namespace
     */
    constructor(root, opts) {
      this.root = root;
      this.call = opts.call;
      this.onChange = opts.onChange || (() => {});
      this.prefs = loadPrefs();
      this.expanded = new Set();
      this.rows = [];
      this._build();
    }

    // ---------- public API ----------

    /** Apply saved preferences to the back end. Call once Python is ready. */
    start() {
      this._safe(() => this.call(METHOD.TRACE, { enabled: this.prefs.trace }));
      this.refresh();
    }

    refresh() {
      this._safe(() => {
        this.rows = this.call(METHOD.LIST, { settings: this.prefs.filters })
          .sort((a, b) => a.name.localeCompare(b.name));
        this._renderRows();
        this._status(`${this.rows.length} variable${this.rows.length === 1 ? '' : 's'}`);
      });
    }

    // ---------- layout ----------

    _build() {
      this.countEl = h('span', { class: 'vx-status' });
      this.filterMenu = h('div', { class: 'vx-menu', hidden: true },
        FILTERS.map(f => h('label', {},
          h('input', { type: 'checkbox', checked: this.prefs.filters[f.key],
            onchange: e => { this.prefs.filters[f.key] = e.target.checked; this._savePrefs(); this.refresh(); } }),
          f.label)),
        h('hr'),
        h('label', {},
          h('input', { type: 'checkbox', checked: this.prefs.trace,
            onchange: e => { this.prefs.trace = e.target.checked; this._savePrefs();
              this._safe(() => this.call(METHOD.TRACE, { enabled: this.prefs.trace })); } }),
          'Record assignment history'));
      const header = h('div', { class: 'vx-header' },
        h('span', { class: 'vx-title', text: 'Variables' }),
        h('span', { class: 'vx-tools' },
          h('button', { title: 'Refresh', text: 'Refresh', onclick: () => this.refresh() }),
          h('button', { title: 'Remove all variables', text: 'Remove all', onclick: () => this._clearAll() }),
          h('span', { class: 'vx-menu-wrap' },
            h('button', { title: 'Filters', text: 'Filters', onclick: e => { e.stopPropagation(); this.filterMenu.hidden = !this.filterMenu.hidden; } }),
            this.filterMenu)));
      document.addEventListener('click', e => { if (!this.filterMenu.contains(e.target)) this.filterMenu.hidden = true; });

      this.tbody = h('tbody');
      const table = h('table', { class: 'vx-table' },
        h('thead', {}, h('tr', {}, ['Name', 'Type', 'Size', 'Value'].map(t => h('th', { text: t })))),
        this.tbody);
      this.root.append(header, h('div', { class: 'vx-body' }, table), h('div', { class: 'vx-footer' }, this.countEl));
      this.modal = new Modal();
    }

    _renderRows() {
      this.tbody.replaceChildren(...this.rows.flatMap(row => this._rowNodes(row)));
      if (this.rows.length === 0) {
        this.tbody.append(h('tr', {}, h('td', { colspan: 4, class: 'vx-empty', text: 'No variables yet. Assign something in the terminal.' })));
      }
    }

    _rowNodes(row) {
      const expandable = Number(row.history) >= HISTORY_EXPAND_MIN;
      const open = expandable && this.expanded.has(row.name);
      const twisty = expandable
        ? h('span', { class: 'vx-twisty', text: open ? '▾' : '▸', title: `${row.history} assignments`,
            onclick: e => { e.stopPropagation(); this._toggleHistory(row.name); } })
        : h('span', { class: 'vx-twisty' });
      const actions = h('span', { class: 'vx-actions' },
        h('button', { text: 'edit', title: 'Set value', onclick: e => { e.stopPropagation(); this._editValue(row); } }),
        h('button', { text: 'copy', title: 'Copy value', onclick: e => { e.stopPropagation(); this._copy(row.name); } }),
        h('button', { text: 'del', title: 'Delete variable', onclick: e => { e.stopPropagation(); this._delete(row.name); } }));
      const tr = h('tr', { class: 'vx-row', title: 'Click to open the value viewer', onclick: () => this._openViewer(row) },
        h('td', { class: 'vx-name' }, twisty, row.name, expandable ? h('span', { class: 'vx-count', text: `×${row.history}` }) : null),
        h('td', { class: 'vx-type', text: row.type }),
        h('td', { class: 'vx-size', text: row.size }),
        h('td', { class: 'vx-value' }, h('span', { class: 'vx-value-text', text: row.view, title: row.view }), actions));
      return open ? [tr, ...this._historyNodes(row.name)] : [tr];
    }

    _historyNodes(name) {
      const hist = this._safe(() => this.call(METHOD.HISTORY, { name }));
      if (!hist) return [];
      const dropped = hist.count - hist.entries.length;
      const nodes = hist.entries.map(entry => h('tr', { class: 'vx-hist', title: 'Show the line that assigned this value',
        onclick: () => this._revealLine(name, entry) },
        h('td', { class: 'vx-hist-line', text: entry.kind === 'explorer' ? 'set in explorer' : `line ${entry.line}` }),
        h('td', { colspan: 3, class: 'vx-hist-value', text: entry.value })));
      if (dropped > 0) nodes.unshift(h('tr', { class: 'vx-hist' }, h('td', { colspan: 4, class: 'vx-hist-line', text: `${dropped} older values not kept` })));
      return nodes;
    }

    _toggleHistory(name) {
      this.expanded.has(name) ? this.expanded.delete(name) : this.expanded.add(name);
      this._renderRows();
    }

    // ---------- actions ----------

    _openViewer(row) {
      const view = this._safe(() => this.call(METHOD.VALUE, { name: row.name, offset: 0, limit: PAGE_ROWS, col_offset: 0, col_limit: PAGE_COLS }));
      if (view) this.modal.showValue(row.name, view, page => this.call(METHOD.VALUE, Object.assign({ name: row.name, limit: PAGE_ROWS, col_limit: PAGE_COLS }, page)), () => this._copy(row.name));
    }

    _editValue(row) {
      this.modal.showPrompt(`Set value of ${row.name}`, 'Any Python expression, evaluated in your session', row.view, expr => {
        this.call(METHOD.SET, { name: row.name, expr });
        this.refresh();
        this.onChange();
      });
    }

    _delete(name) {
      this._safe(() => { this.call(METHOD.DELETE, { name }); this.expanded.delete(name); });
      this.refresh();
      this.onChange();
    }

    _clearAll() {
      this._safe(() => this.call(METHOD.CLEAR_ALL, {}));
      this.expanded.clear();
      this.refresh();
      this.onChange();
    }

    _copy(name) {
      const text = this._safe(() => this.call(METHOD.TEXT, { name }));
      if (text === undefined) return;
      if (!navigator.clipboard) { this._status('Copy needs an HTTPS page', true); return; }
      navigator.clipboard.writeText(text)
        .then(() => this._status(`Copied ${name}`))
        .catch(err => this._status(`Copy failed: ${err.message}`, true));
    }

    _revealLine(name, entry) {
      if (entry.kind === 'explorer') return;
      const src = this._safe(() => this.call(METHOD.CELL, { file: entry.file }));
      if (src) this.modal.showSource(name, src, entry);
    }

    // ---------- helpers ----------

    _safe(fn) {
      try {
        return fn();
      } catch (err) {
        this._status(err.message, true);
        return undefined;
      }
    }

    _status(text, isError) {
      this.countEl.textContent = text;
      this.countEl.classList.toggle('vx-error', !!isError);
    }

    _savePrefs() {
      try { localStorage.setItem(STORAGE_KEY, JSON.stringify(this.prefs)); } catch (e) { /* private mode */ }
    }
  }

  // Overlay for the value viewer, source viewer, and Set Value prompt.
  class Modal {
    constructor() {
      this.title = h('div', { class: 'vx-modal-title' });
      this.meta = h('div', { class: 'vx-modal-meta' });
      this.body = h('div', { class: 'vx-modal-body' });
      this.foot = h('div', { class: 'vx-modal-foot' });
      this.box = h('div', { class: 'vx-modal', role: 'dialog' },
        h('div', { class: 'vx-modal-head' }, this.title,
          h('button', { class: 'vx-close', text: 'Close', title: 'Close (Esc)', onclick: () => this.hide() })),
        this.meta, this.body, this.foot);
      this.overlay = h('div', { class: 'vx-overlay', hidden: true, onclick: e => { if (e.target === this.overlay) this.hide(); } }, this.box);
      document.body.append(this.overlay);
      document.addEventListener('keydown', e => { if (e.key === 'Escape' && !this.overlay.hidden) this.hide(); });
    }

    _open(title, meta) {
      this.title.textContent = title;
      this.meta.textContent = meta || '';
      this.body.replaceChildren();
      this.foot.replaceChildren();
      this.overlay.hidden = false;
    }

    hide() {
      this.overlay.hidden = true;
      if (this.onHide) this.onHide();
    }

    showValue(name, view, fetchPage, copy) {
      const describe = v => [v.type, v.shape && v.shape.length ? `shape (${v.shape.join(', ')})` : null, v.dtype ? `dtype ${v.dtype}` : null]
        .filter(Boolean).join('  |  ');
      const draw = v => {
        this._open(name, describe(v));
        if (v.kind === VIEW_KIND.TEXT) this.body.append(h('pre', { class: 'vx-text', text: v.text }));
        else this._drawTable(v, page => { try { draw(fetchPage(page)); } catch (err) { this.meta.textContent = err.message; } });
        this.foot.append(h('button', { text: 'Copy', onclick: copy }));
      };
      draw(view);
    }

    _drawTable(v, goTo) {
      const head = h('tr', {}, v.index ? h('th', { class: 'vx-idx', text: v.index_name || '' }) : null,
        v.columns.map(c => h('th', { text: c })));
      const rows = v.rows.map((r, i) => h('tr', {},
        v.index ? h('th', { class: 'vx-idx', text: v.index[i] }) : null,
        r.map((cell, j) => h('td', { class: v.numeric[j] ? 'vx-num' : '', text: cell }))));
      this.body.append(h('table', { class: 'vx-grid' }, h('thead', {}, head), h('tbody', {}, rows)));

      const rowEnd = v.offset + v.rows.length;
      const colEnd = v.col_offset + v.columns.length;
      const pager = (label, start, end, total, prev, next) => h('span', { class: 'vx-pager' },
        h('button', { text: 'Prev', disabled: start === 0, onclick: prev }),
        h('span', { text: `${label} ${total ? start + 1 : 0}-${end} of ${total}` }),
        h('button', { text: 'Next', disabled: end >= total, onclick: next }));
      this.foot.append(pager('Rows', v.offset, rowEnd, v.total_rows,
        () => goTo({ offset: Math.max(0, v.offset - PAGE_ROWS), col_offset: v.col_offset }),
        () => goTo({ offset: rowEnd, col_offset: v.col_offset })));
      if (v.total_cols > v.columns.length) {
        this.foot.append(pager('Columns', v.col_offset, colEnd, v.total_cols,
          () => goTo({ offset: v.offset, col_offset: Math.max(0, v.col_offset - PAGE_COLS) }),
          () => goTo({ offset: v.offset, col_offset: colEnd })));
      }
    }

    showSource(name, src, entry) {
      this._open(`${name} = ${entry.value}`, src.cell ? `Assigned in In [${src.cell}], line ${entry.line}` : `Assigned at line ${entry.line}`);
      const lines = src.lines.map((text, i) => h('div', { class: i + 1 === entry.line ? 'vx-src-line vx-src-hit' : 'vx-src-line' },
        h('span', { class: 'vx-src-no', text: String(i + 1) }), text));
      this.body.append(h('pre', { class: 'vx-text vx-src' }, lines));
      const hit = this.body.querySelector('.vx-src-hit');
      if (hit) hit.scrollIntoView({ block: 'center' });
    }

    showPrompt(title, hint, initial, apply) {
      this._open(title, hint);
      const error = h('div', { class: 'vx-error' });
      const input = h('input', { class: 'vx-input', type: 'text', spellcheck: 'false', value: initial });
      const submit = () => {
        try { apply(input.value); this.hide(); } catch (err) { error.textContent = err.message; }
      };
      input.addEventListener('keydown', e => { if (e.key === 'Enter') submit(); });
      this.body.append(input, error);
      this.foot.append(h('button', { text: 'Set', onclick: submit }));
      input.focus();
      input.select();
    }
  }

  global.VarPane = VarPane;
})(typeof window !== 'undefined' ? window : globalThis);
