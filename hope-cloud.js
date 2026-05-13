/* ===== Hope Scene Script ===== */
(function () {
  'use strict';

  var BASE = 'uploads/';
  var activeAnims    = [];
  var activeTimeouts = [];
  var driftAnim      = null;
  var scrollFading   = false;

  function rand(min, max) { return min + Math.random() * (max - min); }

  function cancelAll() {
    activeAnims.forEach(function(a) { try { a.cancel(); } catch(e) {} });
    activeAnims = [];
    activeTimeouts.forEach(function(t) { clearTimeout(t); });
    activeTimeouts = [];
    if (driftAnim) { try { driftAnim.cancel(); } catch(e) {} driftAnim = null; }
  }

  /* -- Inject scene div once -- */
  function ensureScene() {
    if (document.getElementById('hopeScene')) return;
    var scene = document.createElement('div');
    scene.id = 'hopeScene';
    scene.setAttribute('aria-hidden', 'true');

    var sun = new Image();
    sun.src = BASE + 'sun.png';
    sun.className = 'hope-sun';
    sun.alt = '';

    var text = new Image();
    text.src = BASE + 'hope text.png';
    text.className = 'hope-text';
    text.alt = 'Hope is on the Horizon!';

    var cloud = new Image();
    cloud.src = BASE + 'cloud.png';
    cloud.className = 'hope-cloud-img';
    cloud.alt = '';

    scene.appendChild(sun);
    scene.appendChild(text);
    scene.appendChild(cloud);
    document.body.appendChild(scene);
  }

  function showScene() {
    ensureScene();
    cancelAll();
    scrollFading = false;
    var isMobile = window.innerWidth <= 600;

    var scene = document.getElementById('hopeScene');
    var sun   = scene.querySelector('.hope-sun');
    var text  = scene.querySelector('.hope-text');
    var cloud = scene.querySelector('.hope-cloud-img');

    /* reset */
    scene.style.opacity = '0';
    scene.style.transform = '';
    [sun, text, cloud].forEach(function(el) {
      el.style.opacity = '0';
      el.style.transform = '';
    });

    /* 1 -- Cloud fades + slides in offset 30px right of sun (t=0, 1.5s) */
    var t1 = setTimeout(function() {
      var a = cloud.animate([
        { opacity: 0, transform: 'translate(30px, 40px)' },
        { opacity: 1, transform: 'translate(30px, 0px)'  }
      ], { duration: 1500, fill: 'forwards', easing: 'ease-out' });
      activeAnims.push(a);
    }, 0);
    activeTimeouts.push(t1);

    /* 2 -- Sun rises from behind cloud (t=1.2s, 10s) */
    var t2 = setTimeout(function() {
      var a = sun.animate([
        { opacity: 0,   transform: 'translateY(160px)' },
        { opacity: 0.4, transform: 'translateY(90px)',  offset: 0.40 },
        { opacity: 1,   transform: 'translateY(0px)'  }
      ], { duration: 10000, fill: 'forwards', easing: 'cubic-bezier(.1,.9,.25,1)' });
      activeAnims.push(a);
    }, 1200);
    activeTimeouts.push(t2);

    /* 3 -- Text grows from tiny → full as sun rises (t=1.2s, 10s — matches sun) */
    var t3 = setTimeout(function() {
      var a = text.animate([
        { opacity: 0,   transform: 'scale(0.12)' },
        { opacity: 0.3, transform: 'scale(0.40)', offset: 0.30 },
        { opacity: 0.7, transform: 'scale(0.72)', offset: 0.65 },
        { opacity: 1,   transform: 'scale(1)'    }
      ], { duration: 10000, fill: 'forwards', easing: 'cubic-bezier(.1,.9,.25,1)' });
      activeAnims.push(a);
    }, 1200);
    activeTimeouts.push(t3);

    /* 4 -- Drift in from right: mobile crosses full screen, desktop to mid-screen */
    var travel = isMobile
      ? -(window.innerWidth + 400)
      : -(Math.round(window.innerWidth / 2) + 500);
    var driftDuration = isMobile ? 25000 : 16000;
    driftAnim = scene.animate([
      { transform: 'translateX(0px)' },
      { transform: 'translateX(' + travel + 'px)' }
    ], { duration: driftDuration, fill: 'forwards', easing: 'linear' });
    activeAnims.push(driftAnim);

    /* 4b -- Scene fades in as it enters viewport.
       Mobile: scene enters ~6s in, so delay fade-in to match.
       Desktop: enters almost immediately, short delay. */
    var fadeInDelay = isMobile ? 5500 : 0;
    var tFadeIn = setTimeout(function() {
      var fadeInAnim = scene.animate([
        { opacity: 0 },
        { opacity: 1 }
      ], { duration: 1800, fill: 'forwards', easing: 'ease-in' });
      activeAnims.push(fadeInAnim);
    }, fadeInDelay);
    activeTimeouts.push(tFadeIn);

    /* 5 -- Fade out: desktop mid-screen (~10s), mobile while still fully visible (~10s after fade-in) */
    var fadeDelay = isMobile ? 14000 : 10000;
    var tFade = setTimeout(function() {
      if (scrollFading) return;
      scrollFading = true;
      /* Fade out scene */
      var a = scene.animate([
        { opacity: 1 },
        { opacity: 0 }
      ], { duration: 2500, fill: 'forwards', easing: 'ease-in' });
      activeAnims.push(a);
      /* Sun sinks down as it sets */
      var sunEl = scene.querySelector('.hope-sun');
      var textEl = scene.querySelector('.hope-text');
      if (sunEl) {
        var b = sunEl.animate([
          { transform: 'translateY(0px)' },
          { transform: 'translateY(80px)' }
        ], { duration: 2500, fill: 'forwards', easing: 'ease-in', composite: 'add' });
        activeAnims.push(b);
      }
      if (textEl) {
        var c = textEl.animate([
          { transform: 'translateY(0px)' },
          { transform: 'translateY(80px)' }
        ], { duration: 2500, fill: 'forwards', easing: 'ease-in', composite: 'add' });
        activeAnims.push(c);
      }
      var tReschedule = setTimeout(function() { scheduleScene(); }, 3000);
      activeTimeouts.push(tReschedule);
    }, fadeDelay);
    activeTimeouts.push(tFade);
  }

  /* -- Scroll fade-out -- */
  var lastScroll = 0;
  window.addEventListener('scroll', function() {
    var scrollY = window.scrollY || window.pageYOffset;
    if (scrollFading) return;
    if (scrollY > lastScroll && scrollY > 80) {
      /* user scrolled down — fade scene out slowly with sun setting */
      scrollFading = true;
      var scene = document.getElementById('hopeScene');
      if (!scene) return;
      var a = scene.animate([
        { opacity: 1 },
        { opacity: 0 }
      ], { duration: 2500, fill: 'forwards', easing: 'ease-in' });
      activeAnims.push(a);
      var sunEl = scene.querySelector('.hope-sun');
      var textEl = scene.querySelector('.hope-text');
      if (sunEl) {
        var b = sunEl.animate([
          { transform: 'translateY(0px)' },
          { transform: 'translateY(80px)' }
        ], { duration: 2500, fill: 'forwards', easing: 'ease-in', composite: 'add' });
        activeAnims.push(b);
      }
      if (textEl) {
        var c = textEl.animate([
          { transform: 'translateY(0px)' },
          { transform: 'translateY(80px)' }
        ], { duration: 2500, fill: 'forwards', easing: 'ease-in', composite: 'add' });
        activeAnims.push(c);
      }
      /* reschedule next appearance after scene fades */
      setTimeout(function() {
        scheduleScene();
      }, 3000);
    }
    lastScroll = scrollY;
  }, { passive: true });

  function scheduleScene() {
    var delay = rand(20000, 30000);
    var t = setTimeout(function() {
      showScene();
    }, delay);
    activeTimeouts.push(t);
  }

  window.addEventListener('load', function() {
    ensureScene();
    setTimeout(showScene, 1800);
  });
})();


