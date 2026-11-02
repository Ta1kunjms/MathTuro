/*
  File: student/assets/js/quiz-proof.js
  Purpose: Submit a self-reported score for an external-link quiz together with
  a required screenshot of the result (student/quizzes.html, student/module-view.html).

  Flow: upload the image to the private quiz-screenshots bucket under the
  student's own folder ({uid}/{quizId}/{timestamp}.{ext}), then call the
  4-arg submit_regular_quiz_score RPC, which verifies the object exists in the
  caller's folder before recording the attempt
  (database/migration_passing_rule_floor_and_screenshot.sql).
*/
(function () {
  const BUCKET = 'quiz-screenshots';
  const MAX_BYTES = 5 * 1024 * 1024;
  const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

  function validateScreenshot(file) {
    if (!file) throw new Error('Please attach a screenshot of your quiz result');
    if (!ALLOWED_TYPES.includes(file.type)) throw new Error('Screenshot must be a JPG, PNG, GIF, or WebP image');
    if (file.size > MAX_BYTES) throw new Error('Screenshot must be 5 MB or smaller');
  }

  async function submitExternalQuizScore({ userId, quizId, score, total, file }) {
    validateScreenshot(file);
    const sb = getSupabase();
    const ext = (file.name.split('.').pop() || 'png').toLowerCase().replace(/[^a-z0-9]/g, '') || 'png';
    const path = `${userId}/${quizId}/${Date.now()}.${ext}`;

    const { error: uploadError } = await sb.storage.from(BUCKET).upload(path, file, {
      contentType: file.type,
      upsert: false
    });
    if (uploadError) throw new Error('Screenshot upload failed: ' + uploadError.message);

    const { data, error } = await sb.rpc('submit_regular_quiz_score', {
      p_quiz_id: quizId,
      p_score: score,
      p_total: total,
      p_screenshot_path: path
    });
    if (error) {
      // Best-effort cleanup so a rejected attempt doesn't leave an orphan file.
      sb.storage.from(BUCKET).remove([path]).catch(() => {});
      throw error;
    }
    return data;
  }

  window.MathTuroQuizProof = { validateScreenshot, submitExternalQuizScore, ALLOWED_TYPES };
})();
