Reveal.initialize({ hash:true, width:1280, height:720, margin:0.02,
  controls:false, progress:true, transition:'fade', plugins:[] });

var NAV = document.getElementById('navbar');
/* control bar shows when the mouse is near the bottom edge */
var navHideT;
function showNav(){
  NAV.classList.add('show'); clearTimeout(navHideT);
  navHideT = setTimeout(function(){ if(!NAV.matches(':hover')) NAV.classList.remove('show'); }, 2200);
}
document.addEventListener('mousemove', function(e){ if(e.clientY > window.innerHeight - 140) showNav(); });
NAV.addEventListener('mouseenter', function(){ NAV.classList.add('show'); clearTimeout(navHideT); });
NAV.addEventListener('mouseleave', function(){ navHideT = setTimeout(function(){ NAV.classList.remove('show'); }, 700); });
function toggleFull(){ var d=document; if(!d.fullscreenElement){ (d.documentElement.requestFullscreen||function(){}).call(d.documentElement); } else { d.exitFullscreen(); } }

/* ---- presenter window (synced over postMessage) ---- */
var PW=null;
function openPresenter(){
  PW = window.open('vendor/presenter.html','foc_presenter','width=1180,height=820');
  if(!PW){ alert('Allow pop-ups for this page, then click Presenter again.'); }
}
function cleanClone(s){
  if(!s) return '';
  var c=s.cloneNode(true);
  c.removeAttribute('hidden'); c.removeAttribute('style'); c.setAttribute('data-thumb','1');
  c.querySelectorAll('aside.notes').forEach(function(a){ a.remove(); });
  c.querySelectorAll('.fragment').forEach(function(f){ f.classList.add('visible'); });
  return c.outerHTML;
}
function notesOf(s){ var a=s&&s.querySelector('aside.notes'); return a?a.innerHTML:''; }
function pushState(){
  if(!PW||PW.closed) return;
  var slides=Reveal.getSlides(), i=Reveal.getSlidePastCount(), s=slides[i], nx=slides[i+1];
  PW.postMessage({type:'state', cur:i+1, total:slides.length,
    notes:notesOf(s), curHTML:cleanClone(s), nextHTML:cleanClone(nx), video:{has:false} }, '*');
}
window.addEventListener('message', function(e){
  var d=e.data||{};
  if(d.type==='ready'){ pushState(); }
  else if(d.type==='cmd'){ if(d.act==='prev') Reveal.prev(); else if(d.act==='next') Reveal.next(); }
});
NAV.addEventListener('click', function(e){
  var b=e.target.closest('button'); if(!b) return;
  var a=b.dataset.act;
  if(a==='prev') Reveal.prev();
  else if(a==='next') Reveal.next();
  else if(a==='present') openPresenter();
  else if(a==='full') toggleFull();
});
function updateCount(){
  document.getElementById('cur').textContent=Reveal.getSlidePastCount()+1;
  document.getElementById('tot').textContent=Reveal.getTotalSlides();
}

/* ---- step highlight: the newest visible step lights its code lines ---- */
function highlight(sec){
  if(!sec || !sec.classList.contains('walk')) return;
  var vis=sec.querySelectorAll('.steps .fragment.visible');
  var last=vis.length ? vis[vis.length-1] : null;
  var on = last ? last.dataset.lines.split(',') : [];
  sec.querySelectorAll('.steps li').forEach(function(li){ li.classList.toggle('current', li===last); });
  sec.querySelector('.code').classList.toggle('focus', on.length>0);
  sec.querySelectorAll('.code .ln').forEach(function(l){ l.classList.toggle('on', on.indexOf(l.dataset.n)>=0); });
}

/* ---- auto-fit: biggest type whose content extent fits its box ----
   Extent is measured from children's offsets, because centered flex boxes
   hide overflow from scrollHeight. */
function extent(box){
  var kids=box.children, top=1e9, bot=-1e9;
  for(var i=0;i<kids.length;i++){ var k=kids[i]; if(!k.offsetHeight) continue;
    top=Math.min(top,k.offsetTop); bot=Math.max(bot,k.offsetTop+k.offsetHeight); }
  return bot>top ? bot-top : 0;
}
function innerH(box){ var c=getComputedStyle(box); return box.clientHeight-parseFloat(c.paddingTop)-parseFloat(c.paddingBottom); }
function tooBig(box){ return extent(box) > innerH(box) + 1 || box.scrollWidth > box.clientWidth + 1; }
function fitVar(box, name, lo, hi, test){
  var v=hi, guard=0; box.style.setProperty(name, v.toFixed(3));
  if(!box.offsetHeight) return;                      /* not laid out yet: refit on arrival */
  while(test() && v>lo && guard++<80){ v-=0.02; box.style.setProperty(name, v.toFixed(3)); }
}
/* The box whose children are measured: a bounded wrapper when the slide has one,
   otherwise the stage itself. Wrappers are clipped to the stage by CSS, so measuring
   the stage's direct child would always say "fits". */
function measureBox(st){
  return st.querySelector(':scope > .concept > .txt, :scope > .prob, :scope > .how') || st;
}
function fitStage(sec){
  var st = sec && sec.querySelector('.stage'); if(!st) return;
  var code = st.querySelector('.code'), box = measureBox(st);
  if(code){
    var pre = code.querySelector('pre'), steps = st.querySelector('.steps');
    fitVar(code, '--cfs', 0.55, 1.45, function(){ return pre.offsetHeight > innerH(code) + 1 || pre.scrollWidth > pre.clientWidth + 1; });
    if(steps){ fitVar(steps, '--sfs', 0.6, 1.35, function(){ return tooBig(steps); }); }
    else { fitVar(st, '--fs', 0.6, 1.2, function(){ return tooBig(box); }); }
  } else {
    fitVar(st, '--fs', 0.6, 1.2, function(){ return tooBig(box); });
  }
}
function fitAll(){ document.querySelectorAll('.reveal .slides > section').forEach(fitStage); }
if(document.fonts && document.fonts.ready){ document.fonts.ready.then(fitAll); }
window.addEventListener('load', fitAll);
window.addEventListener('resize', fitAll);

function raf2(fn){ requestAnimationFrame(function(){ requestAnimationFrame(fn); }); }
Reveal.on('ready', function(e){ updateCount(); pushState(); raf2(function(){ fitAll(); highlight(e.currentSlide); }); });
Reveal.on('slidechanged', function(e){ updateCount(); pushState(); raf2(function(){ fitStage(e.currentSlide); highlight(e.currentSlide); }); });
Reveal.on('fragmentshown', function(e){ highlight(e.fragment.closest('section')); pushState(); });
Reveal.on('fragmenthidden', function(e){ highlight(e.fragment.closest('section')); pushState(); });
