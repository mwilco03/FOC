// =============================================================================
// CTFd Scoreboard Enhancements
// Inject via theme_footer: live ticker, first blood, confetti, countdown
// =============================================================================

(function() {
  'use strict';

  // --- CONFIG ---
  const POLL_INTERVAL = 5000;      // Check for new solves every 5s
  const SHOW_CONFETTI = true;
  const SHOW_TICKER = true;
  const CONTROLLER_URL = window.location.protocol + '//' + window.location.hostname + ':8888';

  let knownSolves = new Set();
  let firstLoad = true;

  // --- TICKER BAR ---
  function createTicker() {
    if (!SHOW_TICKER) return;
    if (document.getElementById('solve-ticker')) return;

    const ticker = document.createElement('div');
    ticker.id = 'solve-ticker';
    ticker.style.cssText = `
      position: fixed; bottom: 0; left: 0; right: 0; z-index: 9998;
      background: rgba(15,15,35,.95); backdrop-filter: blur(10px);
      border-top: 1px solid rgba(0,255,65,.2);
      padding: 8px 20px; font-family: 'JetBrains Mono', monospace;
      font-size: 13px; color: #8888aa; overflow: hidden; height: 36px;
    `;
    ticker.innerHTML = '<div id="ticker-content" style="white-space:nowrap;display:inline-block;"></div>';
    document.body.appendChild(ticker);

    // Add bottom padding to body so content isn't hidden behind ticker
    document.body.style.paddingBottom = '50px';
  }

  function addTickerMessage(msg, isFirstBlood) {
    const content = document.getElementById('ticker-content');
    if (!content) return;

    const span = document.createElement('span');
    span.style.cssText = `
      display: inline-block; margin-right: 40px; animation: fadeInSlide .5s ease;
      color: ${isFirstBlood ? '#ff6b35' : '#00ff41'};
    `;
    span.textContent = (isFirstBlood ? '\u{1F3C6} FIRST BLOOD: ' : '\u2713 ') + msg;
    content.insertBefore(span, content.firstChild);

    // Keep only last 20 messages
    while (content.children.length > 20) {
      content.removeChild(content.lastChild);
    }
  }

  // --- CONFETTI ---
  function fireConfetti() {
    if (!SHOW_CONFETTI) return;
    const colors = ['#00ff41', '#ff6b35', '#6c9bff', '#ffd93d', '#c471ed'];
    for (let i = 0; i < 50; i++) {
      const particle = document.createElement('div');
      particle.style.cssText = `
        position: fixed; z-index: 99999; pointer-events: none;
        width: ${4 + Math.random() * 6}px;
        height: ${4 + Math.random() * 6}px;
        background: ${colors[Math.floor(Math.random() * colors.length)]};
        border-radius: ${Math.random() > .5 ? '50%' : '0'};
        left: ${Math.random() * 100}vw;
        top: -10px;
        opacity: 1;
        transition: none;
      `;
      document.body.appendChild(particle);

      const destX = (Math.random() - .5) * 200;
      const destY = window.innerHeight + 50;
      const duration = 1500 + Math.random() * 2000;
      const delay = Math.random() * 500;

      setTimeout(() => {
        particle.style.transition = `all ${duration}ms cubic-bezier(.25,.46,.45,.94)`;
        particle.style.transform = `translate(${destX}px, ${destY}px) rotate(${Math.random()*720}deg)`;
        particle.style.opacity = '0';
        setTimeout(() => particle.remove(), duration + 100);
      }, delay);
    }
  }

  // --- COUNTDOWN TIMER (polls lab-controller) ---
  function createCountdown() {
    if (document.getElementById('ctf-countdown')) return;

    const countdown = document.createElement('div');
    countdown.id = 'ctf-countdown';
    countdown.style.cssText = `
      position: fixed; top: 60px; right: 20px; z-index: 9997;
      background: rgba(20,20,40,.9); border: 1px solid rgba(0,255,65,.3);
      border-radius: 12px; padding: 12px 20px;
      font-family: 'JetBrains Mono', monospace; font-size: 20px;
      color: #00ff41; text-shadow: 0 0 10px rgba(0,255,65,.4);
      backdrop-filter: blur(10px);
    `;
    countdown.innerHTML = '\u23F0 --:--:--';
    document.body.appendChild(countdown);

    function updateTimer() {
      fetch(CONTROLLER_URL + '/api/timer')
        .then(r => r.json())
        .then(data => {
          if (!data.started) {
            countdown.innerHTML = '\u23F0 WAITING';
            countdown.style.color = '#8888aa';
            return;
          }
          if (data.expired) {
            countdown.innerHTML = "\u23F0 TIME'S UP";
            countdown.style.color = '#ff4757';
            countdown.style.borderColor = 'rgba(255,71,87,.5)';
            return;
          }
          const s = data.remaining;
          const h = Math.floor(s / 3600);
          const m = Math.floor((s % 3600) / 60);
          const sec = s % 60;
          countdown.innerHTML = `\u23F0 ${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}:${String(sec).padStart(2,'0')}`;

          if (s < 300) {
            countdown.style.color = sec % 2 ? '#ff4757' : '#ff6b35';
            countdown.style.borderColor = 'rgba(255,71,87,.5)';
          } else {
            countdown.style.color = '#00ff41';
            countdown.style.borderColor = 'rgba(0,255,65,.3)';
          }
        })
        .catch(() => {
          countdown.innerHTML = '\u23F0 --:--:--';
        });
    }

    updateTimer();
    setInterval(updateTimer, 1000);
  }

  // --- POLL FOR SOLVES ---
  function pollSolves() {
    fetch('/api/v1/scoreboard')
      .then(r => r.json())
      .then(data => {
        if (!data.success || !data.data) return;
        // Track solve count changes
      })
      .catch(() => {});

    // Also check recent submissions
    fetch('/api/v1/submissions?type=correct&page=1')
      .then(r => r.json())
      .then(data => {
        if (!data.success || !data.data) return;

        data.data.forEach(sub => {
          const key = `${sub.user_id}-${sub.challenge_id}`;
          if (!knownSolves.has(key)) {
            knownSolves.add(key);
            if (!firstLoad) {
              // Fetch challenge name
              fetch(`/api/v1/challenges/${sub.challenge_id}`)
                .then(r => r.json())
                .then(chal => {
                  if (!chal.success) return;
                  const chalName = chal.data.name;
                  const solveCount = chal.data.solves;

                  fetch(`/api/v1/users/${sub.user_id}`)
                    .then(r => r.json())
                    .then(user => {
                      if (!user.success) return;
                      const userName = user.data.name;
                      const isFirstBlood = solveCount === 1;
                      addTickerMessage(`${userName} solved "${chalName}" (+${sub.challenge && sub.challenge.value || '?'} pts)`, isFirstBlood);
                      if (isFirstBlood) fireConfetti();
                    });
                });
            }
          }
        });
        firstLoad = false;
      })
      .catch(() => {});
  }

  // --- INJECT STYLES ---
  const style = document.createElement('style');
  style.textContent = `
    @keyframes fadeInSlide {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
    }
  `;
  document.head.appendChild(style);

  // --- INIT ---
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  function init() {
    createTicker();
    createCountdown();
    pollSolves();
    setInterval(pollSolves, POLL_INTERVAL);
  }
})();
