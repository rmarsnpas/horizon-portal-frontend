/* ===== Background/Hero video mobile autoplay fix =====
   Many mobile browsers (iOS Low Power Mode, some Android WebViews, in-app
   browsers, data-saver modes, etc.) ignore the declarative autoplay
   attribute even when muted+playsinline are set. This retries playback
   programmatically and on the first user interaction so the background
   video actually shows/plays on mobile instead of just sitting on its
   poster frame (or not rendering at all). */
(function () {
  'use strict';

  function initVideoAutoplay() {
    var vids = document.querySelectorAll('video.page-video-bg, video.hero-bg-video');
    if (!vids.length) return;

    var tryPlayAll = function () {
      vids.forEach(function (v) {
        if (v.paused) {
          var p = v.play();
          if (p && typeof p.catch === 'function') { p.catch(function () {}); }
        }
      });
    };

    tryPlayAll();

    // Retry shortly after load in case the first attempt was blocked
    // before metadata finished loading.
    window.addEventListener('load', tryPlayAll, { once: true });

    // Retry on the first user interaction (touch/click/scroll), which
    // satisfies stricter mobile autoplay policies.
    ['touchstart', 'click', 'scroll'].forEach(function (evt) {
      document.addEventListener(evt, tryPlayAll, { once: true, passive: true });
    });

    // Retry when the tab/app becomes visible again (iOS often pauses
    // background video when the page is backgrounded).
    document.addEventListener('visibilitychange', function () {
      if (!document.hidden) { tryPlayAll(); }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initVideoAutoplay);
  } else {
    initVideoAutoplay();
  }
})();
