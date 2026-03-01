with open('public/guest-modules.html', 'w', encoding='utf-8') as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="Logo/MATHURO-LOGO.png">
    <title>Guest Modules</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/@supabase/supabase-js@2"></script>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;600;700;800;900&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background: #f5f5f5; color: #1f2937; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        h1 { color: #005801; font-size: 2.5rem; font-weight: 700; margin-bottom: 1rem; text-align: center; }
        .filter-tabs { display: flex; justify-content: center; margin-bottom: 3rem; gap: 1rem; flex-wrap: wrap; }
        .filter-tab { padding: 0.75rem 1.5rem; border: 1px solid #e5e7eb; border-radius: 25px; background: white; color: #6b7280; cursor: pointer; transition: all 0.3s ease; font-weight: 500; }
        .filter-tab:hover { background: #f3f4f6; color: #005801; border-color: #005801; }
        .filter-tab.active { background: #005801; color: white; border-color: #005801; }
        .modules-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 2rem; margin-bottom: 3rem; }
        .module-card { background: white; border-radius: 16px; padding: 2rem; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05); transition: all 0.3s ease; cursor: pointer; border: 2px solid transparent; }
        .module-card:hover { transform: translateY(-5px); box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1); border-color: #005801; }
        .module-icon { width: 80px; height: 80px; border-radius: 20px; display: flex; align-items: center; justify-content: center; font-size: 2rem; margin-bottom: 1.5rem; }
        .icon-green { background: linear-gradient(135deg, #005801 0%, #34C759 100%); color: white; }
        .icon-purple { background: linear-gradient(135deg, #7C0058 0%, #C6008D 100%); color: white; }
        .icon-orange { background: linear-gradient(135deg, #FEA501 0%, #FFC860 100%); color: white; }
        .icon-blue { background: linear-gradient(135deg, #0066FF 0%, #00CCFF 100%); color: white; }
        .module-title { font-size: 1.5rem; font-weight: 700; color: #1f2937; margin-bottom: 1rem; }
        .module-description { color: #6b7280; line-height: 1.6; margin-bottom: 1.5rem; }
        .view-btn { width: 100%; padding: 0.75rem; background: #005801; color: white; border: none; border-radius: 12px; font-weight: 600; cursor: pointer; transition: all 0.3s ease; font-size: 1rem; }
        .view-btn:hover { background: #004601; }
        .empty-state { text-align: center; padding: 4rem 0; grid-column: 1 / -1; }
        .empty-state h3 { font-size: 1.5rem; color: #6b7280; margin-bottom: 0.5rem; }
        .empty-state p { color: #9ca3af; max-width: 400px; margin: 0 auto; }
        .modal { display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0, 0, 0, 0.5); z-index: 1000; align-items: center; justify-content: center; }
        .modal.active { display: flex; }
        .modal-content { background: white; border-radius: 20px; padding: 2.5rem; max-width: 500px; width: 90%; text-align: center; animation: slideUp 0.3s ease; }
        @keyframes slideUp { from { transform: translateY(30px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
        .modal h2 { font-size: 1.5rem; color: #1f2937; margin-bottom: 1rem; font-weight: 700; }
        .modal p { color: #6b7280; margin-bottom: 2rem; line-height: 1.6; }
        .modal-buttons { display: flex; gap: 1rem; justify-content: center; }
        .modal-btn { padding: 0.75rem 1.5rem; border-radius: 12px; font-weight: 600; cursor: pointer; transition: all 0.3s ease; border: none; font-size: 1rem; }
        .modal-btn-primary { background: #005801; color: white; }
        .modal-btn-primary:hover { background: #004601; }
        .modal-btn-secondary { background: #e5e7eb; color: #374151; }
        .modal-btn-secondary:hover { background: #d1d5db; }
        .loading { text-align: center; padding: 4rem 0; }
        .spinner { border: 4px solid #f3f4f6; border-top: 4px solid #005801; border-radius: 50%; width: 50px; height: 50px; animation: spin 1s linear infinite; margin: 0 auto 1rem; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
        .loading p { color: #6b7280; font-size: 1rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Guest Modules</h1>
        <div class="filter-tabs">
            <button class="filter-tab active" data-grade="all">All Grades</button>
            <button class="filter-tab" data-grade="grade7">Grade 7</button>
            <button class="filter-tab" data-grade="grade8">Grade 8</button>
            <button class="filter-tab" data-grade="grade9">Grade 9</button>
            <button class="filter-tab" data-grade="grade10">Grade 10</button>
            <button class="filter-tab" data-grade="grade11">Grade 11</button>
            <button class="filter-tab" data-grade="grade12">Grade 12</button>
        </div>
        <div id="loading" class="loading">
            <div class="spinner"></div>
            <p>Loading modules...</p>
        </div>
        <div id="modulesGrid" class="modules-grid"></div>
        <div id="emptyState" class="empty-state" style="display: none;">
            <h3>No Modules Found</h3>
            <p>No modules are available for this grade level yet. Check back soon for new content!</p>
        </div>
    </div>

    <div id="loginModal" class="modal">
        <div class="modal-content">
            <h2>Login Required</h2>
            <p>You need to sign up or sign in to view this module. Create an account to get access to all our learning resources.</p>
            <div class="modal-buttons">
                <button class="modal-btn modal-btn-primary" onclick="window.location.href='register.html'">Sign Up</button>
                <button class="modal-btn modal-btn-secondary" onclick="document.getElementById('loginModal').classList.remove('active')">Cancel</button>
            </div>
        </div>
    </div>

    <script src="public/shared/js/config.js"></script>
    <script src="public/shared/js/supabase.js"></script>
    <script src="public/shared/js/utils.js"></script>

    <script>
        let allModules = [];
        let filteredModules = [];

        document.addEventListener('DOMContentLoaded', async function() {
            try {
                await loadModules();
                setupEventListeners();
                filterByGrade('all');
            } catch (error) {
                console.error('Error initializing page:', error);
                displayError('Failed to load modules');
            }
        });

        async function loadModules() {
            try {
                const { data, error } = await supabase
                    .from('modules')
                    .select('*')
                    .order('title');

                if (error) throw error;
                allModules = data;
                filteredModules = [...allModules];
            } catch (error) {
                console.error('Error loading modules:', error);
                displayError('Failed to fetch modules');
            }
        }

        function setupEventListeners() {
            document.querySelectorAll('.filter-tab').forEach(button => {
                button.addEventListener('click', function() {
                    const grade = this.getAttribute('data-grade');
                    filterByGrade(grade);
                });
            });

            document.getElementById('loginModal').addEventListener('click', function(e) {
                if (e.target === this) {
                    this.classList.remove('active');
                }
            });
        }

        function filterByGrade(grade) {
            document.querySelectorAll('.filter-tab').forEach(button => {
                button.classList.remove('active');
                if (button.getAttribute('data-grade') === grade) {
                    button.classList.add('active');
                }
            });

            if (grade === 'all') {
                filteredModules = [...allModules];
            } else {
                filteredModules = allModules.filter(module => module.grade_level === grade);
            }

            displayModules(filteredModules);
        }

        function displayModules(modules) {
            const modulesGrid = document.getElementById('modulesGrid');
            const loadingDiv = document.getElementById('loading');
            const emptyStateDiv = document.getElementById('emptyState');

            loadingDiv.style.display = 'none';

            if (modules.length === 0) {
                modulesGrid.style.display = 'none';
                emptyStateDiv.style.display = 'block';
            } else {
                modulesGrid.style.display = 'grid';
                emptyStateDiv.style.display = 'none';

                modulesGrid.innerHTML = modules.map(module => `
                    <div class="module-card" onclick="showLoginModal()">
                        <div class="module-icon icon-green">📚</div>
                        <h3 class="module-title">${module.title}</h3>
                        <p class="module-description">${module.description || 'No description available'}</p>
                        <button class="view-btn">View Module</button>
                    </div>
                `).join('');
            }
        }

        function showLoginModal() {
            document.getElementById('loginModal').classList.add('active');
        }

        function displayError(message) {
            const modulesGrid = document.getElementById('modulesGrid');
            const loadingDiv = document.getElementById('loading');
            const emptyStateDiv = document.getElementById('emptyState');

            loadingDiv.style.display = 'none';
            modulesGrid.style.display = 'none';
            emptyStateDiv.style.display = 'block';
            emptyStateDiv.querySelector('h3').textContent = 'Error';
            emptyStateDiv.querySelector('p').textContent = message;
        }
    </script>
</body>
</html>
''')