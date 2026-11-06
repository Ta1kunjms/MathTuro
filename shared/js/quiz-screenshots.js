/*
  File: shared/js/quiz-screenshots.js
  Purpose: Show student score screenshots to teachers.

  quiz_submissions.screenshot_url holds a storage path in the quiz-screenshots
  bucket ({uid}/{quizId}/{file}); older rows may hold a full URL. Pages render
  <img data-screenshot="..."> or <a data-screenshot="...">, then call hydrate()
  to swap in a short-lived signed URL.
*/
(function () {
  const BUCKET = 'quiz-screenshots';
  const SIGNED_URL_SECONDS = 3600;

  function attr(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  async function resolveUrl(value) {
    const stored = String(value || '').trim();
    if (/^https?:\/\//i.test(stored)) return stored;
    const { data, error } = await getSupabase().storage.from(BUCKET).createSignedUrl(stored, SIGNED_URL_SECONDS);
    if (error) throw error;
    return data.signedUrl;
  }

  async function hydrate(root) {
    const scope = root || document;
    await Promise.all(Array.from(scope.querySelectorAll('[data-screenshot]')).map(async (el) => {
      try {
        const url = await resolveUrl(el.dataset.screenshot);
        if (el.tagName === 'IMG') el.src = url;
        else el.href = url;
      } catch (error) {
        console.error('Could not load screenshot:', error);
        const note = document.createElement('p');
        note.className = 'text-sm text-red-600';
        note.textContent = 'Screenshot could not be loaded: ' + (error.message || 'unknown error');
        el.replaceWith(note);
      }
    }));
  }

  window.MathTuroScreenshots = { attr, hydrate };
})();
