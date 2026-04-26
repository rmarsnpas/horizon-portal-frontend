/* ===== Hope Cloud Script ===== */
(function () {
  'use strict';

  var IMG_SRC = 'uploads/hope cloud.png';
  var BASE_WIDTH = 200; // px, desktop default

  /* ── inject roam div if not already in HTML ── */
  function ensureRoamDiv() {
    if (document.getElementById('hopeCloudRoam')) return;
    var d = document.createElement('div');
    d.id = 'hopeCloudRoam';
    d.setAttribute('aria-hidden', 'true');
    var img = document.createElement('img');
    img.src = IMG_SRC;
    img.alt = 'Hope is on the Horizon!';
    d.appendChild(img);
    document.body.appendChild(d);
  }

  function rand(min, max) { return min + Math.random() * (max - min); }

  /* ── build and play a random animation on the element ── */
  function animateCloud(el) {
    var rot   = (Math.random() < 0.5 ? -1 : 1) * rand(10, 20); /* 10–20° either way */
    var scale = rand(0.80, 1.20);       /* ±20% of base   */
    var dur   = rand(12000, 20000);     /* 12 – 20 s      */

    var s0   = scale * 0.40;            /* start tiny — slow zoom in  */
    var sPeak = scale * 1.10;           /* overshoot peak             */
    var r0 = rot;
    var r1 = rot * 0.4;

    var keyframes = [
      /* fade + zoom in */
      { opacity: 0,   transform: 'scale(' + s0    + ') rotate(' + r0  + 'deg)', offset: 0.00 },
      { opacity: 1,   transform: 'scale(' + sPeak + ') rotate(' + r0  + 'deg)', offset: 0.30 },
      /* hold near peak */
      { opacity: 1,   transform: 'scale(' + scale + ') rotate(' + r1  + 'deg)', offset: 0.55 },
      /* zoom back out while fading */
      { opacity: 0.7, transform: 'scale(' + sPeak + ') rotate(' + (r1 * 0.5) + 'deg)', offset: 0.78 },
      { opacity: 0,   transform: 'scale(' + s0    + ') rotate(0deg)',               offset: 1.00 }
    ];

    /* Web Animations API — widely supported */
    var anim = el.animate(keyframes, {
      duration: dur,
      easing: 'cubic-bezier(.4,0,.2,1)',
      fill: 'forwards'
    });
    anim.onfinish = function () {
      el.style.opacity = '0';
      el.style.transform = '';
      anim.cancel();
    };
  }

  /* ── hero cloud (index.html only) ── */
  function showHero() {
    var hero = document.getElementById('hopeCloudHero');
    if (!hero) return;
    animateCloud(hero);
  }

  /* ── roaming cloud ── */
  function showRoam() {
    var roam = document.getElementById('hopeCloudRoam');
    if (!roam) return;
    roam.style.left = rand(8, 70) + 'vw';
    roam.style.top  = rand(8, 65) + 'vh';
    animateCloud(roam);
  }

  /* ── schedule roam recursively ── */
  function scheduleRoam() {
    var delay = rand(8000, 14000);
    setTimeout(function () {
      showRoam();
      scheduleRoam();
    }, delay);
  }

  /* ── init on load ── */
  window.addEventListener('load', function () {
    ensureRoamDiv();
    setTimeout(showHero, 1800);   /* hero fires 1.8 s after load  */
    scheduleRoam();               /* roam fires 25-50 s intervals */
  });
})();
