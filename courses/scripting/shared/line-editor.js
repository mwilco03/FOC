// Readline-style line editor for the FOC xterm.js terminals.
// Owns the input buffer, cursor, history, completion, and redraw.
(function (global) {
  'use strict';

  const ESC = '\x1b';
  const CSI = ESC + '[';
  const PASTE_START = CSI + '200~';
  const PASTE_END = CSI + '201~';
  const ANSI_PATTERN = /\x1b\[[0-9;?]*[A-Za-z]/g;
  const WORD_CHAR = /[A-Za-z0-9_]/;
  const WHITESPACE = /\s/;
  const COMPLETION_LIST_LIMIT = 200;
  const COMPLETION_COLUMN_GAP = 2;

  const ACTION = Object.freeze({
    SUBMIT: 'submit',
    NEWLINE: 'newline',
    BACKSPACE: 'backspace',
    DELETE: 'delete',
    LEFT: 'left',
    RIGHT: 'right',
    UP: 'up',
    DOWN: 'down',
    HOME: 'home',
    END: 'end',
    WORD_LEFT: 'wordLeft',
    WORD_RIGHT: 'wordRight',
    KILL_TO_END: 'killToEnd',
    KILL_TO_START: 'killToStart',
    KILL_WORD_BACK: 'killWordBack',
    KILL_BIGWORD_BACK: 'killBigWordBack',
    KILL_WORD_FORWARD: 'killWordForward',
    YANK: 'yank',
    TRANSPOSE: 'transpose',
    HISTORY_PREV: 'historyPrev',
    HISTORY_NEXT: 'historyNext',
    CANCEL: 'cancel',
    CLEAR_SCREEN: 'clearScreen',
    EOF: 'eof',
    TAB: 'tab',
    DEDENT: 'dedent',
  });

  // Byte sequences xterm.js emits, in both normal and application cursor modes.
  const SEQUENCES = new Map([
    ['\r', ACTION.SUBMIT],
    [ESC + '\r', ACTION.NEWLINE],
    ['\x7f', ACTION.BACKSPACE],
    ['\b', ACTION.KILL_WORD_BACK],          // Ctrl+Backspace
    [ESC + '\x7f', ACTION.KILL_WORD_BACK],  // Alt+Backspace
    [CSI + '3~', ACTION.DELETE],
    [CSI + 'D', ACTION.LEFT], [ESC + 'OD', ACTION.LEFT], ['\x02', ACTION.LEFT],
    [CSI + 'C', ACTION.RIGHT], [ESC + 'OC', ACTION.RIGHT], ['\x06', ACTION.RIGHT],
    [CSI + 'A', ACTION.UP], [ESC + 'OA', ACTION.UP],
    [CSI + 'B', ACTION.DOWN], [ESC + 'OB', ACTION.DOWN],
    ['\x10', ACTION.HISTORY_PREV], ['\x0e', ACTION.HISTORY_NEXT],
    [CSI + 'H', ACTION.HOME], [ESC + 'OH', ACTION.HOME], [CSI + '1~', ACTION.HOME], ['\x01', ACTION.HOME],
    [CSI + 'F', ACTION.END], [ESC + 'OF', ACTION.END], [CSI + '4~', ACTION.END], ['\x05', ACTION.END],
    [CSI + '1;5D', ACTION.WORD_LEFT], [CSI + '1;3D', ACTION.WORD_LEFT], [ESC + 'b', ACTION.WORD_LEFT],
    [CSI + '1;5C', ACTION.WORD_RIGHT], [CSI + '1;3C', ACTION.WORD_RIGHT], [ESC + 'f', ACTION.WORD_RIGHT],
    ['\x0b', ACTION.KILL_TO_END],
    ['\x15', ACTION.KILL_TO_START],
    ['\x17', ACTION.KILL_BIGWORD_BACK],
    [ESC + 'd', ACTION.KILL_WORD_FORWARD], [CSI + '3;5~', ACTION.KILL_WORD_FORWARD],
    ['\x19', ACTION.YANK],
    ['\x14', ACTION.TRANSPOSE],
    ['\x03', ACTION.CANCEL],
    ['\x0c', ACTION.CLEAR_SCREEN],
    ['\x04', ACTION.EOF],
    ['\t', ACTION.TAB],
    [CSI + 'Z', ACTION.DEDENT],
  ]);
  const ESCAPE_SEQUENCES = [...SEQUENCES.keys()]
    .filter(s => s.startsWith(ESC))
    .sort((a, b) => b.length - a.length);
  const UNKNOWN_CSI = /^\x1b\[[0-9;?]*[\x40-\x7e]/;
  const UNKNOWN_SS3 = /^\x1bO./;

  const visibleLength = s => s.replace(ANSI_PATTERN, '').length;
  const leadingWhitespace = s => s.match(/^[ \t]*/)[0];
  const commonPrefix = words => words.reduce((acc, w) => {
    let i = 0;
    while (i < acc.length && i < w.length && acc[i] === w[i]) i++;
    return acc.slice(0, i);
  });

  // Split raw terminal input into tokens: { action } or { text } or { paste }.
  function tokenize(data) {
    const tokens = [];
    let i = 0;
    while (i < data.length) {
      const rest = data.slice(i);
      if (rest.startsWith(PASTE_START)) {
        const end = rest.indexOf(PASTE_END);
        const stop = end === -1 ? rest.length : end;
        tokens.push({ paste: rest.slice(PASTE_START.length, stop) });
        i += end === -1 ? rest.length : end + PASTE_END.length;
        continue;
      }
      if (rest[0] === ESC) {
        const seq = ESCAPE_SEQUENCES.find(s => rest.startsWith(s));
        if (seq) { tokens.push({ action: SEQUENCES.get(seq) }); i += seq.length; continue; }
        const unknown = rest.match(UNKNOWN_CSI) || rest.match(UNKNOWN_SS3);
        i += unknown ? unknown[0].length : 1;
        continue;
      }
      const code = rest.charCodeAt(0);
      if (code < 0x20 || code === 0x7f) {
        if (SEQUENCES.has(rest[0])) tokens.push({ action: SEQUENCES.get(rest[0]) });
        i += 1;
        continue;
      }
      const run = rest.match(/^[^\x00-\x1f\x7f]+/)[0];
      tokens.push({ text: run });
      i += run.length;
    }
    return tokens;
  }

  // Unbracketed paste arrives as one chunk with CR line breaks.
  function looksLikePaste(data) {
    return data.length > 1 && !data.startsWith(ESC) && /[\r\n]/.test(data);
  }

  class LineEditor {
    /**
     * @param {Terminal} term xterm.js terminal
     * @param {object} opts
     *   prompt():                    primary prompt string (ANSI allowed)
     *   continuationPrompt(width):   prompt for buffer lines after the first
     *   multiline:                   keep newlines in the buffer (default false)
     *   isComplete(text):            { complete, indent } decides Enter behaviour
     *   onSubmit(text):              runs the accepted buffer; may return a Promise
     *   complete(text, cursor):      { start, end, matches } for Tab completion
     *   highlight(text):             ANSI-coloured copy of text, same line count
     *   indentUnit:                  string inserted by Tab with nothing to complete
     */
    constructor(term, opts) {
      this.term = term;
      this.opts = Object.assign({
        prompt: () => '$ ',
        continuationPrompt: width => ' '.repeat(Math.max(0, width - 2)) + '> ',
        multiline: false,
        isComplete: null,
        onSubmit: () => {},
        complete: null,
        highlight: null,
        indentUnit: '    ',
      }, opts);
      this.buffer = '';
      this.cursor = 0;
      this.history = [];
      this.historyIndex = 0;
      this.historyDraft = '';
      this.historyPrefix = '';
      this.killRing = '';
      this.editing = false;
      this.renderedRow = 0;
      this.promptText = '';
      this.queue = [];
      this.draining = false;

      term.onData(data => this.feed(data));
      term.onResize(() => this._onResize());
      term.write(CSI + '?2004h'); // ask xterm.js for bracketed paste
    }

    // ---------- public API ----------

    /** Show a fresh prompt with an empty buffer. */
    prompt() {
      this.buffer = '';
      this.cursor = 0;
      this._resetHistoryNav();
      this.promptText = this.opts.prompt();
      this.renderedRow = 0;
      this.editing = true;
      this._render();
    }

    /** Write output without corrupting the line being edited. */
    print(text) {
      const out = text.replace(/\r?\n/g, '\r\n') + (text.endsWith('\n') ? '' : '\r\n');
      if (!this.editing) { this.term.write(out); return; }
      this._erase();
      this.term.write(out);
      this.renderedRow = 0;
      this._render();
    }

    /** Clear the screen and scrollback, keeping the current input. */
    clearScreen() {
      this.term.write(CSI + 'H' + CSI + '2J' + CSI + '3J');
      this.renderedRow = 0;
      if (this.editing) this._render();
    }

    feed(data) {
      const tokens = looksLikePaste(data) ? [{ paste: data }] : tokenize(data);
      this.queue.push(...tokens);
      this._drain();
    }

    // ---------- input dispatch ----------

    async _drain() {
      if (this.draining) return;
      this.draining = true;
      try {
        while (this.queue.length) {
          const token = this.queue.shift();
          if (!this.editing) continue;
          if (token.text !== undefined) this._insert(token.text);
          else if (token.paste !== undefined) await this._paste(token.paste);
          else await this._dispatch(token.action);
        }
      } finally {
        this.draining = false;
      }
    }

    async _paste(raw) {
      const text = raw.replace(/\r\n?/g, '\n');
      if (this.opts.multiline) {
        const endsWithNewline = text.endsWith('\n');
        this._insert(endsWithNewline ? text.slice(0, -1) : text);
        if (endsWithNewline) await this._submit();
        return;
      }
      const lines = text.split('\n');
      for (let i = 0; i < lines.length; i++) {
        this._insert(lines[i]);
        if (i < lines.length - 1) await this._submit();
      }
    }

    async _dispatch(action) {
      const handlers = {
        [ACTION.SUBMIT]: () => this._submit(),
        [ACTION.NEWLINE]: () => this.opts.multiline && this._insert('\n' + leadingWhitespace(this._currentLine().text)),
        [ACTION.BACKSPACE]: () => this._backspace(),
        [ACTION.DELETE]: () => this._deleteRange(this.cursor, this.cursor + 1),
        [ACTION.LEFT]: () => this._moveTo(this.cursor - 1),
        [ACTION.RIGHT]: () => this._moveTo(this.cursor + 1),
        [ACTION.UP]: () => this._verticalMove(-1),
        [ACTION.DOWN]: () => this._verticalMove(1),
        [ACTION.HISTORY_PREV]: () => this._historyMove(-1),
        [ACTION.HISTORY_NEXT]: () => this._historyMove(1),
        [ACTION.HOME]: () => this._moveTo(this._currentLine().start),
        [ACTION.END]: () => this._moveTo(this._currentLine().end),
        [ACTION.WORD_LEFT]: () => this._moveTo(this._wordStart(this.cursor, WORD_CHAR)),
        [ACTION.WORD_RIGHT]: () => this._moveTo(this._wordEnd(this.cursor)),
        [ACTION.KILL_TO_END]: () => this._kill(this.cursor, this._currentLine().end),
        [ACTION.KILL_TO_START]: () => this._kill(this._currentLine().start, this.cursor),
        [ACTION.KILL_WORD_BACK]: () => this._kill(this._wordStart(this.cursor, WORD_CHAR), this.cursor),
        [ACTION.KILL_BIGWORD_BACK]: () => this._kill(this._bigWordStart(this.cursor), this.cursor),
        [ACTION.KILL_WORD_FORWARD]: () => this._kill(this.cursor, this._wordEnd(this.cursor)),
        [ACTION.YANK]: () => this._insert(this.killRing),
        [ACTION.TRANSPOSE]: () => this._transpose(),
        [ACTION.CANCEL]: () => this._cancel(),
        [ACTION.CLEAR_SCREEN]: () => this.clearScreen(),
        [ACTION.EOF]: () => this._deleteRange(this.cursor, this.cursor + 1),
        [ACTION.TAB]: () => this._tab(),
        [ACTION.DEDENT]: () => this._dedent(),
      };
      const handler = handlers[action];
      if (handler) await handler();
    }

    // ---------- editing primitives ----------

    _insert(text) {
      if (!text) return;
      const clean = this.opts.multiline ? text : text.replace(/\n/g, ' ');
      this.buffer = this.buffer.slice(0, this.cursor) + clean + this.buffer.slice(this.cursor);
      this.cursor += clean.length;
      this._resetHistoryNav();
      this._render();
    }

    _deleteRange(from, to) {
      const start = Math.max(0, from);
      const end = Math.min(this.buffer.length, to);
      if (end <= start) return '';
      const removed = this.buffer.slice(start, end);
      this.buffer = this.buffer.slice(0, start) + this.buffer.slice(end);
      this.cursor = start;
      this._resetHistoryNav();
      this._render();
      return removed;
    }

    _kill(from, to) {
      const removed = this._deleteRange(from, to);
      if (removed) this.killRing = removed;
    }

    _backspace() {
      const line = this._currentLine();
      const before = this.buffer.slice(line.start, this.cursor);
      const unit = this.opts.indentUnit.length;
      if (before.length > 0 && /^ +$/.test(before)) {
        const drop = before.length % unit || unit;
        this._deleteRange(this.cursor - drop, this.cursor);
        return;
      }
      this._deleteRange(this.cursor - 1, this.cursor);
    }

    _transpose() {
      if (this.cursor === 0 || this.buffer.length < 2) return;
      const at = this.cursor === this.buffer.length ? this.cursor - 1 : this.cursor;
      const b = this.buffer;
      this.buffer = b.slice(0, at - 1) + b[at] + b[at - 1] + b.slice(at + 1);
      this.cursor = at + 1;
      this._render();
    }

    _moveTo(pos) {
      const next = Math.max(0, Math.min(this.buffer.length, pos));
      if (next === this.cursor) return;
      this.cursor = next;
      this._render();
    }

    _wordStart(pos, wordChar) {
      let i = pos;
      while (i > 0 && !wordChar.test(this.buffer[i - 1])) i--;
      while (i > 0 && wordChar.test(this.buffer[i - 1])) i--;
      return i;
    }

    _bigWordStart(pos) {
      let i = pos;
      while (i > 0 && WHITESPACE.test(this.buffer[i - 1])) i--;
      while (i > 0 && !WHITESPACE.test(this.buffer[i - 1])) i--;
      return i;
    }

    _wordEnd(pos) {
      let i = pos;
      while (i < this.buffer.length && !WORD_CHAR.test(this.buffer[i])) i++;
      while (i < this.buffer.length && WORD_CHAR.test(this.buffer[i])) i++;
      return i;
    }

    _currentLine() {
      const start = this.buffer.lastIndexOf('\n', this.cursor - 1) + 1;
      const nl = this.buffer.indexOf('\n', this.cursor);
      const end = nl === -1 ? this.buffer.length : nl;
      const index = this.buffer.slice(0, start).split('\n').length - 1;
      return { start, end, index, text: this.buffer.slice(start, end) };
    }

    _lineCount() {
      return this.buffer.split('\n').length;
    }

    // ---------- history ----------

    _resetHistoryNav() {
      this.historyIndex = this.history.length;
      this.historyDraft = '';
      this.historyPrefix = '';
    }

    _verticalMove(dir) {
      const line = this._currentLine();
      const target = line.index + dir;
      if (target < 0 || target >= this._lineCount()) { this._historyMove(dir); return; }
      const column = this.cursor - line.start;
      const lines = this.buffer.split('\n');
      const targetStart = lines.slice(0, target).reduce((n, l) => n + l.length + 1, 0);
      this._moveTo(targetStart + Math.min(column, lines[target].length));
    }

    _historyMove(dir) {
      if (this.historyIndex === this.history.length) {
        this.historyDraft = this.buffer;
        this.historyPrefix = this.buffer;
      }
      let i = this.historyIndex + dir;
      while (i >= 0 && i < this.history.length && !this.history[i].startsWith(this.historyPrefix)) i += dir;
      if (i < 0) return;
      const atDraft = i >= this.history.length;
      this.historyIndex = atDraft ? this.history.length : i;
      this.buffer = atDraft ? this.historyDraft : this.history[i];
      this.cursor = this.buffer.length;
      this._render();
    }

    _remember(text) {
      if (!text.trim() || this.history[this.history.length - 1] === text) return;
      this.history.push(text);
    }

    // ---------- submit / cancel ----------

    async _submit() {
      const line = this._currentLine();
      if (this.opts.multiline && line.index < this._lineCount() - 1) {
        this._insert('\n' + leadingWhitespace(line.text));
        return;
      }
      if (this.opts.isComplete) {
        const status = this.opts.isComplete(this.buffer);
        if (!status.complete) {
          this._insert('\n' + (status.indent || ''));
          return;
        }
      }
      const text = this.buffer;
      this._finishInput('');
      this._remember(text);
      try {
        await this.opts.onSubmit(text);
      } catch (err) {
        this.term.write('\x1b[31m' + String(err && err.message || err) + '\x1b[0m\r\n');
      }
      this.prompt();
    }

    _cancel() {
      this._finishInput('^C');
      this.prompt();
    }

    // Park the cursor after the buffer, append a marker, and stop editing.
    _finishInput(marker) {
      this.cursor = this.buffer.length;
      this._render();
      this.term.write(marker + '\r\n');
      this.editing = false;
      this.renderedRow = 0;
    }

    // ---------- tab / completion ----------

    _tab() {
      const line = this._currentLine();
      const before = this.buffer.slice(line.start, this.cursor);
      if (!this.opts.complete || before.trim() === '') { this._indent(before.length); return; }
      const result = this.opts.complete(this.buffer, this.cursor);
      if (!result || !result.matches || result.matches.length === 0) return;
      const { start, end, matches } = result;
      const typed = this.buffer.slice(start, this.cursor);
      const prefix = matches.length === 1 ? matches[0] : commonPrefix(matches);
      if (prefix.length > typed.length || matches.length === 1) {
        this.buffer = this.buffer.slice(0, start) + prefix + this.buffer.slice(end);
        this.cursor = start + prefix.length;
        this._resetHistoryNav();
        this._render();
        return;
      }
      this.print(this._formatColumns(matches));
    }

    _indent(column) {
      const unit = this.opts.indentUnit;
      this._insert(' '.repeat(unit.length - (column % unit.length)));
    }

    _dedent() {
      const line = this._currentLine();
      const remove = Math.min(leadingWhitespace(line.text).length, this.opts.indentUnit.length);
      if (remove === 0) return;
      const cursor = this.cursor;
      this.buffer = this.buffer.slice(0, line.start) + this.buffer.slice(line.start + remove);
      this.cursor = Math.max(line.start, cursor - remove);
      this._render();
    }

    _formatColumns(items) {
      const shown = items.slice(0, COMPLETION_LIST_LIMIT);
      const width = Math.max(...shown.map(s => s.length)) + COMPLETION_COLUMN_GAP;
      const perRow = Math.max(1, Math.floor(this.term.cols / width));
      const rows = [];
      for (let i = 0; i < shown.length; i += perRow) {
        rows.push(shown.slice(i, i + perRow).map(s => s.padEnd(width)).join('').trimEnd());
      }
      if (items.length > shown.length) rows.push(`\x1b[90m... ${items.length - shown.length} more\x1b[0m`);
      return rows.join('\n');
    }

    // ---------- rendering ----------

    _prompts(lines) {
      const width = visibleLength(this.promptText);
      return lines.map((_, i) => i === 0 ? this.promptText : this.opts.continuationPrompt(width));
    }

    _highlighted(lines) {
      if (!this.opts.highlight || this.buffer === '') return lines;
      try {
        const colored = this.opts.highlight(this.buffer).split('\n');
        return colored.length === lines.length ? colored.map(l => l + '\x1b[0m') : lines;
      } catch (e) {
        return lines;
      }
    }

    // Row/column of buffer offset `pos`, given `cols` terminal columns.
    _position(pos, cols) {
      const lines = this.buffer.split('\n');
      const prompts = this._prompts(lines);
      const widths = lines.map((l, i) => visibleLength(prompts[i]) + l.length);
      let row = 0;
      let remaining = pos;
      for (let i = 0; i < lines.length; i++) {
        const isLast = i === lines.length - 1;
        if (remaining <= lines[i].length) {
          const offset = visibleLength(prompts[i]) + remaining;
          const atWrapEdge = !isLast && remaining === lines[i].length && offset > 0 && offset % cols === 0;
          return atWrapEdge
            ? { row: row + offset / cols - 1, col: cols - 1 }
            : { row: row + Math.floor(offset / cols), col: offset % cols };
        }
        remaining -= lines[i].length + 1;
        row += Math.max(1, Math.ceil(widths[i] / cols));
      }
      return { row, col: 0 };
    }

    _erase() {
      let out = '';
      if (this.renderedRow > 0) out += CSI + this.renderedRow + 'A';
      this.term.write(out + '\r' + CSI + 'J');
    }

    _render() {
      const cols = this.term.cols;
      const lines = this.buffer.split('\n');
      const prompts = this._prompts(lines);
      const colored = this._highlighted(lines);
      let out = this.renderedRow > 0 ? CSI + this.renderedRow + 'A' : '';
      out += '\r' + CSI + 'J';
      out += colored.map((l, i) => prompts[i] + l).join('\r\n');
      const lastWidth = visibleLength(prompts[prompts.length - 1]) + lines[lines.length - 1].length;
      if (lastWidth > 0 && lastWidth % cols === 0) out += ' \r' + CSI + 'K'; // leave the pending-wrap state
      const end = this._position(this.buffer.length, cols);
      const target = this._position(this.cursor, cols);
      if (end.row > target.row) out += CSI + (end.row - target.row) + 'A';
      out += '\r';
      if (target.col > 0) out += CSI + target.col + 'C';
      this.renderedRow = target.row;
      this.term.write(out);
    }

    _onResize() {
      if (!this.editing) return;
      this.renderedRow = this._position(this.cursor, this.term.cols).row;
      this._render();
    }
  }

  global.LineEditor = LineEditor;
  global.LineEditor.ACTION = ACTION;
  global.LineEditor.tokenize = tokenize;
})(typeof window !== 'undefined' ? window : globalThis);
