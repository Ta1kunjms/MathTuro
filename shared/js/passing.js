/*
  File: shared/js/passing.js
  Purpose: Single source of the MathTuro passing rule (DepEd 75%, rounded down)
  so teacher authoring screens and student cards always show the same number
  the server grades against (see database/migration_passing_rule_floor_and_screenshot.sql).

  Rule: passing = max(1, floor(total × 0.75)) for total ≥ 1, else 0.
    10 items → 7, 4 → 3, 2 → 1, 1 → 1.
  The minimum of 1 keeps a short quiz from passing with a score of zero.
*/
(function () {
  const PASSING_RATIO = 0.75;

  function passingScore(total) {
    const n = Math.floor(Number(total) || 0);
    if (n < 1) return 0;
    return Math.max(1, Math.floor(n * PASSING_RATIO));
  }

  function passingLabel(total) {
    const n = Math.floor(Number(total) || 0);
    if (n < 1) return 'Pass: 75%';
    return `Pass: ${passingScore(n)} / ${n}`;
  }

  window.MathTuroPassing = { PASSING_RATIO, passingScore, passingLabel };
})();
