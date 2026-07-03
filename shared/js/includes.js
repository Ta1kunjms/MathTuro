/**
 * includes.js — Runtime HTML partial loader
 * Finds all [data-include] elements and fetches/injects the
 * corresponding partial from /shared/partials/.
 *
 * Usage in HTML:
 *   <div data-include="nav-mobile-teacher" data-depth="../"></div>
 *
 * The data-depth attribute adjusts the relative path from the
 * current page's directory to the project root.
 *   - Root-level pages: data-depth=""
 *   - Pages in /teacher/, /student/, /admin/, /public/: data-depth="../"
 */
(function () {
  'use strict';

  async function loadIncludes() {
    var elements = document.querySelectorAll('[data-include]');
    var loads = Array.from(elements).map(function (el) {
      var partialName = el.dataset.include;
      var depth = el.dataset.depth || '';
      var url = depth + 'shared/partials/' + partialName + '.html';

      return fetch(url)
        .then(function (res) {
          if (!res.ok) throw new Error('Partial not found: ' + url);
          return res.text();
        })
        .then(function (html) {
          var temp = document.createElement('div');
          temp.innerHTML = html;
          
          var parent = el.parentNode;
          var next = el.nextSibling;
          
          // Query for scripts before changing the DOM
          var scripts = Array.from(temp.querySelectorAll('script'));
          
          while (temp.firstChild) {
            parent.insertBefore(temp.firstChild, next);
          }
          parent.removeChild(el);

          // Manually execute scripts to bypass browser innerHTML/outerHTML security restrictions
          scripts.forEach(function (oldScript) {
            var newScript = document.createElement('script');
            if (oldScript.src) {
              newScript.src = oldScript.src;
            } else {
              newScript.textContent = oldScript.textContent;
            }
            document.body.appendChild(newScript);
          });
        })
        .catch(function (err) {
          console.warn('[includes.js]', err.message);
        });
    });

    return Promise.all(loads);
  }

  window.loadIncludes = loadIncludes;

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadIncludes);
  } else {
    loadIncludes();
  }
})();
