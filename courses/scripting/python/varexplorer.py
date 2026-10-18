"""
Variable Explorer back end for the FOC Python Terminal (browser, Pyodide + IPython).
Ported from varexplorer's kernel_bootstrap.py: same namespace view, value viewers, and
assignment-history tracer. The page exec's this file into a private globals dict, so
nothing here lands in the user's namespace. The page calls call(method, params_json).
"""
import json
import pprint
import sys

try:
    from spyder_kernels.utils import nsview as _nsview
    HAVE_NSVIEW = True
except Exception:  # noqa: BLE001
    _nsview = None
    HAVE_NSVIEW = False

ip = get_ipython()  # noqa: F821  (builtin inside the kernel)

DEFAULT_SETTINGS = {
    "check_all": False,
    "exclude_private": True,
    "exclude_uppercase": False,
    "exclude_capitalized": False,
    "exclude_unsupported": False,
    "exclude_callables_and_modules": True,
    "excluded_names": [],
    "minmax": False,
    "filter_on": True,
}
# Names IPython injects that user_ns_hidden does not always cover.
IPYTHON_NAMES = ["In", "Out", "exit", "quit", "get_ipython", "open"]
CELL_LIMIT = 200
TEXT_LIMIT = 2_000_000


def user_namespace():
    hidden = ip.user_ns_hidden
    # list(dict.items()) is a single C call under the GIL: safe to take while the main thread mutates.
    for _ in range(5):
        try:
            items = list(ip.user_ns.items())
            break
        except RuntimeError:  # dictionary changed size during iteration
            continue
    else:
        items = []
    return {k: v for k, v in items if not (k in hidden and hidden[k] is v) and k not in IPYTHON_NAMES}


def lookup(name):
    ns = ip.user_ns
    if name not in ns:
        raise KeyError("no variable named %r in the kernel" % (name,))
    return ns[name]


def fmt(x, limit=CELL_LIMIT):
    try:
        s = x if isinstance(x, str) else str(x)
    except Exception as e:  # noqa: BLE001
        s = "<unrepresentable: %s>" % (e,)
    s = s.replace("\r", "").replace("\n", "\\n")
    if len(s) > limit:
        s = s[: limit - 3] + "..."
    return s


def _modules():
    return sys.modules.get("numpy"), sys.modules.get("pandas")


# ---- fallback namespace view (no spyder-kernels) ------------------------------
def _is_callable_or_module(v):
    import types
    return callable(v) or isinstance(v, types.ModuleType)


def _fallback_view(ns, s):
    np, pd = _modules()
    out = {}
    for key, value in ns.items():
        if s["filter_on"]:
            if s["exclude_private"] and key.startswith("_"):
                continue
            if s["exclude_capitalized"] and key[:1].isupper():
                continue
            if s["exclude_uppercase"] and key.isupper() and len(key) > 1:
                continue
            if key in s["excluded_names"]:
                continue
            if s["exclude_callables_and_modules"] and _is_callable_or_module(value):
                continue
        size = ""
        try:
            if hasattr(value, "shape"):
                size = tuple(int(n) for n in value.shape)
            elif hasattr(value, "__len__"):
                size = len(value)
            else:
                size = 1
        except Exception:  # noqa: BLE001
            size = ""
        # Mirror spyder_kernels.utils.nsview output so the UI reads the same either way.
        numpy_type = "Unknown"
        human_type = type(value).__name__
        if np is not None and isinstance(value, np.ndarray):
            numpy_type = "Array"
            human_type = "Array of %s" % value.dtype.name
        elif np is not None and isinstance(value, np.generic):
            numpy_type = "Scalar"
        if isinstance(value, str):
            view = value
        else:
            try:
                view = repr(value)
            except Exception as e:  # noqa: BLE001
                view = "<unrepresentable: %s>" % (e,)
        out[key] = {
            "type": human_type,
            "size": size,
            "view": fmt(view, 1000),
            "python_type": type(value).__name__,
            "numpy_type": numpy_type,
        }
    return out


# ---- methods ------------------------------------------------------------------
def hello():
    return {"nsview": HAVE_NSVIEW, "python_version": sys.version.split()[0], "live": True, "trace": _trace_enabled,
            "tracer": "monitoring" if _MON_TOOL is not None else "settrace"}


def list_vars(settings=None):
    s = dict(DEFAULT_SETTINGS)
    for k, v in (settings or {}).items():
        if v is not None and k in s:
            s[k] = v
    ns = user_namespace()
    if HAVE_NSVIEW:
        view = _nsview.make_remote_view(ns, s, more_excluded_names=IPYTHON_NAMES)
    else:
        view = _fallback_view(ns, s)
    result = []
    counts = _history_counts()
    for name, info in view.items():
        result.append({
            "name": name,
            "history": counts.get(name, 0),
            "type": str(info.get("type", "")),
            "size": str(info.get("size", "")),
            "view": str(info.get("view", "")),
            "python_type": str(info.get("python_type", "")),
            "numpy_type": str(info.get("numpy_type", "Unknown")),
        })
    return result


def _table(type_name, shape, columns, rows, offset, col_offset, total_rows, total_cols, index=None, index_name="", numeric=None, dtype=None):
    return {
        "kind": "table",
        "type": type_name,
        "shape": [int(n) for n in shape],
        "dtype": dtype,
        "columns": columns,
        "index": index,
        "index_name": index_name,
        "rows": rows,
        "numeric": numeric or [False] * len(columns),
        "offset": int(offset),
        "col_offset": int(col_offset),
        "total_rows": int(total_rows),
        "total_cols": int(total_cols),
    }


def _text(type_name, text, shape=None, dtype=None):
    if len(text) > TEXT_LIMIT:
        text = text[:TEXT_LIMIT] + "\n... [truncated]"
    return {"kind": "text", "type": type_name, "text": text, "shape": shape, "dtype": dtype}


def get_value(name, offset=0, limit=100, col_offset=0, col_limit=50):
    obj = lookup(name)
    np, pd = _modules()
    tname = type(obj).__name__

    if pd is not None and isinstance(obj, pd.DataFrame):
        nrows, ncols = obj.shape
        sub = obj.iloc[offset:offset + limit, col_offset:col_offset + col_limit]
        numeric = [bool(pd.api.types.is_numeric_dtype(sub.iloc[:, j])) for j in range(sub.shape[1])]
        rows = [[fmt(x) for x in row] for row in sub.itertuples(index=False, name=None)]
        return _table("DataFrame", (nrows, ncols), [fmt(c) for c in sub.columns], rows, offset, col_offset, nrows, ncols,
                      index=[fmt(i) for i in sub.index], index_name=fmt(obj.index.name) if obj.index.name is not None else "",
                      numeric=numeric)

    if pd is not None and isinstance(obj, pd.Series):
        n = len(obj)
        sub = obj.iloc[offset:offset + limit]
        rows = [[fmt(x)] for x in sub.tolist()]
        return _table("Series", (n,), [fmt(obj.name) if obj.name is not None else "value"], rows, offset, 0, n, 1,
                      index=[fmt(i) for i in sub.index], index_name=fmt(obj.index.name) if obj.index.name is not None else "",
                      numeric=[bool(pd.api.types.is_numeric_dtype(obj))], dtype=str(obj.dtype))

    if np is not None and isinstance(obj, np.ndarray):
        dtype = str(obj.dtype)
        isnum = bool(np.issubdtype(obj.dtype, np.number) or np.issubdtype(obj.dtype, np.bool_))
        if obj.ndim == 0:
            return _text("ndarray", fmt(obj.item() if obj.size else obj, TEXT_LIMIT), shape=[], dtype=dtype)
        if obj.ndim == 1:
            n = obj.shape[0]
            sub = obj[offset:offset + limit]
            return _table("ndarray", obj.shape, ["0"], [[fmt(x)] for x in sub.tolist()], offset, 0, n, 1, numeric=[isnum], dtype=dtype)
        if obj.ndim == 2:
            nrows, ncols = obj.shape
            sub = obj[offset:offset + limit, col_offset:col_offset + col_limit]
            cols = [str(j) for j in range(col_offset, col_offset + sub.shape[1])]
            rows = [[fmt(x) for x in row] for row in sub.tolist()]
            return _table("ndarray", obj.shape, cols, rows, offset, col_offset, nrows, ncols, numeric=[isnum] * len(cols), dtype=dtype)
        text = np.array2string(obj, threshold=5000, max_line_width=200)
        return _text("ndarray", text, shape=list(obj.shape), dtype=dtype)

    if isinstance(obj, dict):
        n = len(obj)
        keys = list(obj.keys())[offset:offset + limit]
        rows = [[fmt(k), type(obj[k]).__name__, fmt(obj[k])] for k in keys]
        return _table(tname, (n,), ["key", "type", "value"], rows, offset, 0, n, 3, index=[str(offset + i) for i in range(len(keys))])

    if isinstance(obj, (list, tuple, set, frozenset)):
        items = list(obj) if not isinstance(obj, (list, tuple)) else obj
        n = len(items)
        sub = items[offset:offset + limit]
        rows = [[type(v).__name__, fmt(v)] for v in sub]
        return _table(tname, (n,), ["type", "value"], rows, offset, 0, n, 2, index=[str(offset + i) for i in range(len(sub))])

    if isinstance(obj, str):
        return _text("str", obj, shape=[len(obj)])

    try:
        text = pprint.pformat(obj, width=120)
    except Exception:  # noqa: BLE001
        text = repr(obj)
    return _text(tname, text)


def get_text(name):
    obj = lookup(name)
    np, pd = _modules()
    if pd is not None and isinstance(obj, (pd.DataFrame, pd.Series)):
        if obj.size > 5_000_000:
            raise ValueError("%s has %d cells; too large to copy" % (name, obj.size))
        return obj.to_csv(sep="\t")
    if np is not None and isinstance(obj, np.ndarray):
        if obj.size > 5_000_000:
            raise ValueError("%s has %d elements; too large to copy" % (name, obj.size))
        return np.array2string(obj, threshold=sys.maxsize, max_line_width=10_000, separator=", ")
    if isinstance(obj, str):
        return obj
    text = pprint.pformat(obj, width=120)
    if len(text) > TEXT_LIMIT:
        raise ValueError("%s is too large to copy (%d chars)" % (name, len(text)))
    return text


def set_value(name, expr):
    val = eval(expr, ip.user_ns)  # noqa: S307  (user asked for it, in their own kernel)
    ip.user_ns[name] = val
    h = _history.get(name)
    if h is not None:
        h["run"] = _run_no  # append to the existing history instead of starting a new run
    _record(name, val, 0, "", "explorer")
    return {"ok": True}


def delete_var(name):
    if name not in ip.user_ns:
        raise KeyError("no variable named %r" % (name,))
    del ip.user_ns[name]
    _history.pop(name, None)
    _last_obj.pop(name, None)
    return {"ok": True}


# ---- assignment history (tracer) ---------------------------------------------
# While a cell / %run executes, sys.settrace records every value a *module-level* name takes,
# with the line that assigned it. That is how `for i in range(10): i + 1` shows i = 0..9 instead
# of just 9. Only the module frames of user code are traced line by line; function frames get a
# single 'call' callback and run untraced. No breakpoints, no debugger.
import ast
import linecache

HISTORY_CAP = 1000  # entries kept per name per run; the total count keeps counting
_MISSING = object()
_trace_enabled = True
_run_no = 0
_history = {}  # name -> {"run": int, "count": int, "entries": [[line, file, kind, value], ...]}
_last_obj = {}  # name -> object last recorded (identity check; released after each run)
_store_maps = {}  # filename -> {lineno: set(names assigned by the statement on that line)}


def _target_names(node, out):
    if isinstance(node, ast.Name):
        out.add(node.id)
    elif isinstance(node, (ast.Tuple, ast.List)):
        for e in node.elts:
            _target_names(e, out)
    elif isinstance(node, ast.Starred):
        _target_names(node.value, out)


def _walrus_names(expr, out):
    if expr is None:
        return
    for n in ast.walk(expr):
        if isinstance(n, ast.NamedExpr):
            out.add(n.target.id)


def _pattern_names(pattern, out):
    for n in ast.walk(pattern):
        if isinstance(n, (ast.MatchAs, ast.MatchStar)) and n.name:
            out.add(n.name)
        elif isinstance(n, ast.MatchMapping) and n.rest:
            out.add(n.rest)


def _add_range(m, lo, hi, names):
    if names:
        for ln in range(lo, max(lo, hi) + 1):
            m.setdefault(ln, set()).update(names)


def _end(node):
    return getattr(node, "end_lineno", None) or node.lineno


def _collect_stores(stmts, m):
    """Module-scope statements only: never descends into def/class/lambda/comprehension scopes."""
    for node in stmts:
        names = set()
        lo, hi = node.lineno, _end(node)
        if isinstance(node, ast.Assign):
            for t in node.targets:
                _target_names(t, names)
            _walrus_names(node.value, names)
        elif isinstance(node, ast.AugAssign):
            _target_names(node.target, names)
        elif isinstance(node, ast.AnnAssign):
            if node.value is not None:
                _target_names(node.target, names)
        elif isinstance(node, (ast.Import, ast.ImportFrom)):
            for a in node.names:
                if a.name != "*":
                    names.add((a.asname or a.name).split(".")[0])
        elif isinstance(node, ast.Delete):
            for t in node.targets:
                _target_names(t, names)
        elif isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            names.add(node.name)
            lo = min([node.lineno] + [d.lineno for d in node.decorator_list])
            hi = node.body[0].lineno - 1 if node.body else node.lineno
        elif isinstance(node, (ast.For, ast.AsyncFor)):
            _target_names(node.target, names)
            _walrus_names(node.iter, names)
            hi = _end(node.iter)
            _collect_stores(node.body, m)
            _collect_stores(node.orelse, m)
        elif isinstance(node, (ast.While, ast.If)):
            _walrus_names(node.test, names)
            hi = _end(node.test)
            _collect_stores(node.body, m)
            _collect_stores(node.orelse, m)
        elif isinstance(node, (ast.With, ast.AsyncWith)):
            for item in node.items:
                if item.optional_vars is not None:
                    _target_names(item.optional_vars, names)
            hi = _end(node.items[-1].optional_vars or node.items[-1].context_expr)
            _collect_stores(node.body, m)
        elif isinstance(node, (ast.Try, getattr(ast, "TryStar", ast.Try))):
            _collect_stores(node.body, m)
            _collect_stores(node.orelse, m)
            _collect_stores(node.finalbody, m)
            for h in node.handlers:
                if h.name:
                    _add_range(m, h.lineno, h.lineno, {h.name})
                _collect_stores(h.body, m)
            continue
        elif hasattr(ast, "Match") and isinstance(node, ast.Match):
            for case in node.cases:
                caught = set()
                _pattern_names(case.pattern, caught)
                _add_range(m, case.pattern.lineno, _end(case.pattern), caught)
                _collect_stores(case.body, m)
            continue
        elif isinstance(node, ast.Expr):
            _walrus_names(node.value, names)
        _add_range(m, lo, hi, names)


def _stores_for(filename):
    m = _store_maps.get(filename)
    if m is None:
        m = {}
        try:
            linecache.checkcache(filename)
            src = "".join(linecache.getlines(filename))
            if src:
                _collect_stores(ast.parse(src, filename).body, m)
        except Exception:  # noqa: BLE001  (unparsable -> no history for that file)
            m = {}
        _store_maps[filename] = m
    return m


def _is_cell(filename):
    fmap = getattr(getattr(ip, "compile", None), "_filename_map", None)
    return bool(fmap) and filename in fmap


def _short(v):
    if v is _MISSING:
        return "<deleted>"
    try:
        if isinstance(v, (int, float, bool, complex, type(None))):
            return repr(v)
        if isinstance(v, str):
            return fmt(repr(v), 120)
        if HAVE_NSVIEW:
            return fmt(str(_nsview.value_to_display(v, minmax=False)), 120)
        return fmt(repr(v), 120)
    except Exception as e:  # noqa: BLE001
        return "<unrepresentable: %s>" % (e,)


def _record(name, val, line, filename, kind):
    if val is _MISSING:
        _last_obj.pop(name, None)
    else:
        _last_obj[name] = val
    h = _history.get(name)
    if h is None or h["run"] != _run_no:
        h = _history[name] = {"run": _run_no, "count": 0, "entries": []}
    h["count"] += 1
    entries = h["entries"]
    if len(entries) >= HISTORY_CAP:
        del entries[: HISTORY_CAP // 10]  # drop the oldest tenth; the count still says how many there were
    entries.append([line, filename, kind, _short(val)])


def _trace_call(frame, event, arg):
    """Global trace function: traces only module frames whose globals are the user namespace."""
    if event != "call":
        return None
    code = frame.f_code
    if code.co_name != "<module>" or frame.f_globals is not ip.user_ns:
        return None
    stores = _stores_for(code.co_filename)
    if not stores:
        return None
    filename = code.co_filename
    kind = "cell" if _is_cell(filename) else "file"
    state = [None, 0]  # names the previous line may have assigned, and that line

    def local(frame, event, arg):
        pending = state[0]
        if pending:
            ns = frame.f_globals
            for name in pending:
                val = ns.get(name, _MISSING)
                if val is not _last_obj.get(name, _MISSING):
                    _record(name, val, state[1], filename, kind)
        if event == "line":
            ln = frame.f_lineno
            state[0] = stores.get(ln)
            state[1] = ln
        else:
            state[0] = None
        return local

    return local


# Python >= 3.12: sys.monitoring. PY_START fires once per function and we answer DISABLE, so
# function calls cost nothing afterwards; only module code objects get LINE events.
_MON = getattr(sys, "monitoring", None)
_MON_TOOL = None
if _MON is not None:
    for _tid in (4, 3):
        try:
            _MON.use_tool_id(_tid, "varexplorer")
            _MON_TOOL = _tid
            break
        except ValueError:
            continue
_mstate = {}  # code object -> [pending names, line, filename, kind, stores]


def _mon_flush(st, ns):
    for name in st[0]:
        val = ns.get(name, _MISSING)
        if val is not _last_obj.get(name, _MISSING):
            _record(name, val, st[1], st[2], st[3])


def _mon_start(code, offset):
    if code.co_name != "<module>" or sys._getframe(1).f_globals is not ip.user_ns:
        return _MON.DISABLE  # a function, or another module's body: never look at it again
    stores = _stores_for(code.co_filename)
    if not stores:
        return None
    _mstate[code] = [None, 0, code.co_filename, "cell" if _is_cell(code.co_filename) else "file", stores]
    _MON.set_local_events(_MON_TOOL, code, _MON.events.LINE | _MON.events.PY_RETURN)  # PY_UNWIND cannot be local
    return None


def _mon_line(code, line):
    st = _mstate.get(code)
    if st is None:
        return _MON.DISABLE
    had_pending = st[0]
    if had_pending:
        _mon_flush(st, sys._getframe(1).f_globals)
    names = st[4].get(line)
    st[0] = names
    st[1] = line
    if names is None and not had_pending:
        # This line assigns nothing and does not follow an assignment: stop paying for it.
        # Lines after a store stay on so the new value is read before anything mutates it.
        return _MON.DISABLE
    return None


def _mon_end(code, offset, _arg):
    st = _mstate.pop(code, None)
    if st is not None and st[0]:
        _mon_flush(st, sys._getframe(1).f_globals)
    return None


if _MON_TOOL is not None:
    _MON.register_callback(_MON_TOOL, _MON.events.PY_START, _mon_start)
    _MON.register_callback(_MON_TOOL, _MON.events.LINE, _mon_line)
    _MON.register_callback(_MON_TOOL, _MON.events.PY_RETURN, _mon_end)


def _debugger_active():
    if sys.gettrace() is not None:
        return True
    return _MON is not None and _MON.get_tool(_MON.DEBUGGER_ID) is not None


def _pre_run_cell(info=None):
    global _run_no
    _run_no += 1
    if not _trace_enabled or _debugger_active():  # never clobber a debugger
        return
    _store_maps.clear()
    if _MON_TOOL is not None:
        _mstate.clear()
        _MON.set_events(_MON_TOOL, _MON.events.PY_START)
    else:
        sys.settrace(_trace_call)


def _post_run_cell(result=None):
    if _MON_TOOL is not None:
        _MON.set_events(_MON_TOOL, 0)
        _mstate.clear()
    if sys.gettrace() is _trace_call:
        sys.settrace(None)
    ns = ip.user_ns
    for name in [n for n, o in list(_last_obj.items()) if ns.get(n, _MISSING) is not o]:
        _last_obj.pop(name, None)  # hold no reference to values the namespace dropped


ip.events.register("pre_run_cell", _pre_run_cell)
ip.events.register("post_run_cell", _post_run_cell)


def set_trace(enabled):
    global _trace_enabled
    _trace_enabled = bool(enabled)
    return {"trace": _trace_enabled}


def get_history(name):
    h = _history.get(name)
    if h is None:
        return {"count": 0, "entries": []}
    return {
        "count": h["count"],
        "entries": [{"line": e[0], "file": e[1], "kind": e[2], "value": e[3]} for e in list(h["entries"])],
    }


def clear_history():
    _history.clear()
    _last_obj.clear()
    return {"ok": True}


def _history_counts():
    for _ in range(5):
        try:
            return {k: v["count"] for k, v in _history.items()}
        except RuntimeError:
            continue
    return {}


METHODS = {
    "hello": hello,
    "set_trace": set_trace,
    "get_history": get_history,
    "clear_history": clear_history,
    "list_vars": list_vars,
    "get_value": get_value,
    "get_text": get_text,
    "set_value": set_value,
    "delete_var": delete_var,
}


# ---- browser additions ---------------------------------------------------------
def cell_source(file):
    """Source and IPython cell number for a history entry's file (the 'reveal line' target)."""
    fmap = getattr(getattr(ip, "compile", None), "_filename_map", None) or {}
    return {"cell": fmap.get(file), "lines": [l.rstrip("\n") for l in linecache.getlines(file)]}


def clear_all():
    """Spyder's 'Remove all variables': drop every user name, keep IPython's own."""
    for name in list(user_namespace()):
        ip.user_ns.pop(name, None)
    clear_history()
    return {"ok": True}


METHODS.update({"cell_source": cell_source, "clear_all": clear_all})


def call(method, params_json="{}"):
    """Single entry point for the page: JSON in, JSON out."""
    try:
        result = METHODS[method](**json.loads(params_json or "{}"))
        return json.dumps({"result": result}, default=str)
    except Exception as e:  # noqa: BLE001
        return json.dumps({"error": "%s: %s" % (type(e).__name__, e)})
