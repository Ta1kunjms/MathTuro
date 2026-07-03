/**
 * device.js — Viewport & touch detection singleton
 * Must be loaded in <head> before all other scripts.
 * Provides a single source of truth for mobile layout decisions
 * used by device-aware data fetchers and mobile nav injection.
 */
(function () {
  'use strict';

  var Device = {
    _mobileQuery: window.matchMedia('(max-width: 767px)'),
    _touchQuery: window.matchMedia('(pointer: coarse)'),

    /** True when viewport width is < 768px */
    isMobile: function () {
      return this._mobileQuery.matches;
    },

    /** True when primary input is touch (coarse pointer) */
    isTouch: function () {
      return this._touchQuery.matches;
    },

    /**
     * True only when BOTH viewport is narrow AND input is touch-first.
     * Excludes desktop browsers resized to a narrow window.
     */
    isNativeMobile: function () {
      return this.isMobile() && this.isTouch();
    },

    /**
     * Register a callback that fires whenever the mobile/touch state changes
     * (e.g. device rotation, resizing across the 768px breakpoint).
     * @param {function} callback
     */
    onChange: function (callback) {
      this._mobileQuery.addEventListener('change', callback);
      this._touchQuery.addEventListener('change', callback);
    }
  };

  window.Device = Device;

  // Set a data attribute on <html> for CSS targeting without JS
  if (Device.isNativeMobile()) {
    document.documentElement.setAttribute('data-native-mobile', 'true');
  }
})();
