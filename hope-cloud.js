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
    var rot   = rand(-45, 0);           /* 0° … -45° CCW  */
    var scale = rand(0.80, 1.20);       /* ±20% of base   */
    var dur   = rand(5000, 10000);      /* 5 – 10 s     */

    var s0 = scale * 0.85;
    var r0 = rot;
    var r1 = rot * 0.5;                 /* gentle unwind mid-flight */

    var keyframes = [
      { opacity: 0, transform: 'translateY(20px) scale(' + s0 + ') rotate(' + r0 + 'deg)' },
      { opacity: 1, transform: 'translateY(0)    scale(' + scale + ') rotate(' + r0 + 'deg)', offset: 0.13 },
      { opacity: 1, transform: 'translateY(-12px) scale(' + scale + ') rotate(' + r1 + 'deg)', offset: 0.73 },
      { opacity: 0, transform: 'translateY(-28px) scale(' + (scale * 0.93) + ') rotate(0deg)' }
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
