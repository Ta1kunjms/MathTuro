/*
  File: font-toggle.js
  Purpose: Accessible on/off switch for the dyslexia-friendly font (OpenDyslexic).
  - Per-viewer UI preference: localStorage 'mathturo_font_pref' ('dyslexic' | 'default'),
    applied as html[data-font="dyslexic"] (styles in shared/css/base.css).
  - The pre-paint snippet in each page <head> applies the saved choice before
    first paint; this file only renders and wires the switch.
  - Mount points: any element with [data-font-toggle-mount] (sidebars call
    MathTuroFont.mountAll() after injecting their markup). Pages without a
    sidebar or mount point get a compact fixed switch (public pages).
*/
(function () {
  var STORAGE_KEY = 'mathturo_font_pref';

  var VARIANT_CLASSES = {
    light: 'w-full flex items-center gap-3 px-4 py-3 rounded-xl text-gray-700 hover:bg-gray-100 transition-colors',
    dark: 'w-full flex items-center gap-3 px-3 py-2 rounded-lg text-gray-300 hover:bg-gray-800 hover:text-white transition-colors',
    nav: 'inline-flex items-center gap-2 px-3 py-2 rounded-full text-sm font-semibold text-ink-700 hover:bg-forest-50 transition-colors',
    floating: 'fixed left-3 z-40 inline-flex items-center gap-2 px-3 py-2 rounded-full text-sm font-semibold bg-white text-ink-900 border-2 border-ink-900 shadow-[2px_2px_0_0_#1c1b1a]'
  };

  function isEnabled() {
    return document.documentElement.getAttribute('data-font') === 'dyslexic';
  }

  function setEnabled(enabled) {
    if (enabled) {
      document.documentElement.setAttribute('data-font', 'dyslexic');
    } else {
      document.documentElement.removeAttribute('data-font');
    }
    try { localStorage.setItem(STORAGE_KEY, enabled ? 'dyslexic' : 'default'); } catch (e) { /* storage unavailable */ }
  }

  function syncSwitches() {
    var on = isEnabled();
    var switches = document.querySelectorAll('[data-font-switch]');
    for (var i = 0; i < switches.length; i++) {
      switches[i].setAttribute('aria-checked', on ? 'true' : 'false');
      var state = switches[i].querySelector('[data-font-switch-state]');
      if (state) state.textContent = on ? 'On' : 'Off';
    }
    // Student dashboard keeps its own dropdown item; keep its label in step too
    if (typeof window.syncFontToggleLabel === 'function') window.syncFontToggleLabel();
  }

  function createSwitch(variant) {
    var button = document.createElement('button');
    button.type = 'button';
    button.setAttribute('role', 'switch');
    button.setAttribute('data-font-switch', '');
    button.className = VARIANT_CLASSES[variant] || VARIANT_CLASSES.light;
    // Accessible name is the visible label; "Aa" and the On/Off text are decorative
    // because aria-checked already announces the state.
    // In the compact landing nav only "Aa" + state show on small screens; the
    // label stays available to screen readers
    var labelClass = variant === 'nav' ? 'sr-only lg:not-sr-only' : 'flex-1 text-left';
    button.innerHTML =
      '<span aria-hidden="true" class="font-bold">Aa</span>' +
      '<span class="' + labelClass + '">Dyslexia-friendly font</span>' +
      '<span aria-hidden="true" data-font-switch-state class="text-xs font-bold"></span>';
    button.addEventListener('click', function () {
      setEnabled(!isEnabled());
      syncSwitches();
    });
    return button;
  }

  function mountAll() {
    var mounts = document.querySelectorAll('[data-font-toggle-mount]');
    for (var i = 0; i < mounts.length; i++) {
      if (mounts[i].getAttribute('data-font-toggle-mounted') === 'true') continue;
      mounts[i].appendChild(createSwitch(mounts[i].getAttribute('data-variant') || 'light'));
      mounts[i].setAttribute('data-font-toggle-mounted', 'true');
    }
    syncSwitches();
  }

  function mountFloatingIfNeeded() {
    if (document.querySelector('[data-font-switch]') || document.getElementById('sidebar')) return;
    var floating = createSwitch('floating');
    floating.style.bottom = 'calc(0.75rem + env(safe-area-inset-bottom, 0px))';
    document.body.appendChild(floating);
    syncSwitches();
  }

  // Keep every switch in step when the attribute changes elsewhere
  new MutationObserver(syncSwitches).observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['data-font']
  });

  window.MathTuroFont = { isEnabled: isEnabled, setEnabled: setEnabled, mountAll: mountAll };

  function init() {
    mountAll();
    mountFloatingIfNeeded();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
