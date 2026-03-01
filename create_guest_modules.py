with open('public/guest-modules.html', 'w', encoding='utf-8') as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guest Modules</title>
    <script src="https://unpkg.com/@supabase/supabase-js@2"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Inter', sans-serif;
        }

        body {
            background: #f5f5f5;
            color: #1f2937;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }

        header {
            background: white;
            padding: 1.5rem 0;
            border-bottom: 1px solid #e5e7eb;
            margin-bottom: 2rem;
        }

        h1 {
            color: #005801;
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 1rem;
        }

        .hero {
            text-align: center;
            padding: 4rem 0;
            margin-bottom: 3rem;
        }

        .hero h2 {
            font-size: 3rem;
            color: #005801;
            margin-bottom: 1rem;
            font-weight: 800;
        }

        .hero p {
            font-size: 1.25rem;
            color: #6b7280;
            max-width: 600px;
            margin: 0 auto;
        }

        .filter-tabs {
            display: flex;
            justify-content: center;
            margin-bottom: 3rem;
            gap: 1rem;
            flex-wrap: wrap;
        }

        .filter-tab {
            padding: 0.75rem 1.5rem;
            border: 1px solid #e5e7eb;
            border-radius: 25px;
            background: white;
            color: #6b7280;
            cursor: pointer;
            transition: all 0.3s ease;
            font-weight: 500;
        }

        .filter-tab:hover {
            background: #f3f4f6;
            color: #005801;
            border-color: #005801;
        }

        .filter-tab.active {
            background: #005801;
            color: white;
            border-color: #005801;
        }

        .modules-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 2rem;
            margin-bottom: 3rem;
        }

        .module-card {
            background: white;
            border-radius: 16px;
            padding: 2rem;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
            transition: all 0.3s ease;
            cursor: pointer;
            border: 2px solid transparent;
        }

        .module-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            border-color: #005801;
        }

        .module-icon {
            width: 80px;
            height: 80px;
            border-radius: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 2rem;
            margin-bottom: 1.5rem;
        }

        .icon-green {
            background: linear-gradient(135deg, #005801 0%, #34C759 100%);
            color: white;
        }

        .icon-purple {
            background: linear-gradient(135deg, #7C0058 0%, #C6008D 100%);
            color: white;
        }

        .icon-orange {
            background: linear-gradient(135deg, #FEA501 0%, #FFC860 100%);
            color: white;
        }

        .icon-blue {
            background: linear-gradient(135deg, #0066FF 0%, #00CCFF 100%);
            color: white;
        }

        .module-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: #1f2937;
            margin-bottom: 1rem;
        }

        .module-description {
            color: #6b7280;
            line-height: 1.6;
            margin-bottom: 1.5rem;
        }

        .module-details {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
        }

        .difficulty {
            padding: 0.25rem 0.75rem;
            border-radius: 12px;
            font-size: 0.875rem;
            font-weight: 500;
        }

        .difficulty-beginner {
            background: #d1fae5;
            color: #065f46;
        }

        .difficulty-intermediate {
            background: #fed7aa;
            color: #9a3412;
        }

        .difficulty-advanced {
            background: #fecaca;
            color: #991b1b;
        }

        .lessons-count {
            color: #6b7280;
            font-size: 0.875rem;
        }

        .view-btn {
            width: 100%;
            padding: 0.75rem;
            background: #005801;
            color: white;
            border: none;
            border-radius: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            font-size: 1rem;
        }

        .view-btn:hover {
            background: #004601;
        }

        .empty-state {
            text-align: center;
            padding: 4rem 0;
            grid-column: 1 / -1;
        }

        .empty-state-icon {
            font-size: 4rem;
            color: #d1d5db;
            margin-bottom: 1rem;
        }

        .empty-state h3 {
            font-size: 1.5rem;
            color: #6b7280;
            margin-bottom: 0.5rem;
        }

        .empty-state p {
            color: #9ca3af;
            max-width: 400px;
            margin: 0 auto;
        }

        /* Modal Styles */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 1000;
            align-items: center;
            justify-content: center;
        }

        .modal.active {
            display: flex;
        }

        .modal-content {
            background: white;
            border-radius: 20px;
            padding: 2.5rem;
            max-width: 500px;
            width: 90%;
            text-align: center;
            animation: slideUp 0.3s ease;
        }

        @keyframes slideUp {
            from {
                transform: translateY(30px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }

        .modal-icon {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            background: #fef3c7;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 1.5rem;
            font-size: 2rem;
            color: #f59e0b;
        }

        .modal h2 {
            font-size: 1.5rem;
            color: #1f2937;
            margin-bottom: 1rem;
            font-weight: 700;
        }

        .modal p {
            color: #6b7280;
            margin-bottom: 2rem;
            line-height: 1.6;
        }

        .modal-buttons {
            display: flex;
            gap: 1rem;
            justify-content: center;
        }

        .modal-btn {
            padding: 0.75rem 1.5rem;
            border-radius: 12px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            border: none;
            font-size: 1rem;
        }

        .modal-btn-primary {
            background: #005801;
            color: white;
        }

        .modal-btn-primary:hover {
            background: #004601;
        }

        .modal-btn-secondary {
            background: #e5e7eb;
            color: #374151;
        }

        .modal-btn-secondary:hover {
            background: #d1d5db;
        }

        /* Loading Animation */
        .loading {
            text-align: center;
            padding: 4rem 0;
        }

        .spinner {
            border: 4px solid #f3f4f6;
            border-top: 4px solid #005801;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
            margin: 0 auto 1rem;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .loading p {
            color: #6b7280;
            font-size: 1rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>Guest Modules</h1>
        </header>

        <div class="hero">
            <h2>Explore Our Learning Modules</h2>
            <p>Discover a wide range of educational modules designed to enhance your learning experience</p>
        </div>

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
            <div class="empty-state-icon">📚</div>
            <h3>No Modules Found</h3>
            <p>No modules are available for this grade level yet. Check back soon for new content!</p>
        </div>
    </div>

    <!-- Login/Register Modal -->
    <div id="loginModal" class="modal">
        <div class="modal-content">
            <div class="modal-icon">🔐</div>
            <h2>Login Required</h2>
            <p>You need to sign up or sign in to view this module. Create an account to get access to all our learning resources.</p>
            <div class="modal-buttons">
                <button class="modal-btn modal-btn-primary" onclick="window.location.href='register.html'">Sign Up</button>
                <button class="modal-btn modal-btn-secondary" onclick="document.getElementById('loginModal').classList.remove('active')">Cancel</button>
            </div>
        </div>
    </div>

    <!-- Application scripts -->
    <script src="public/shared/js/config.js"></script>
    <script src="public/shared/js/supabase.js"></script>
    <script src="public/shared/js/utils.js"></script>

    <script>
        // Global variables
        let allModules = [];
        let filteredModules = [];

        // Initialize page
        document.addEventListener('DOMContentLoaded', async function() {
            try {
                // Load modules
                await loadModules();
                // Set up event listeners
                setupEventListeners();
                // Display all modules
                filterByGrade('all');
            } catch (error) {
                console.error('Error initializing page:', error);
                displayError('Failed to load modules');
            }
        });

        // Load modules from Supabase
        async function loadModules() {
            try {
                const { data, error } = await supabase
                    .from('modules')
                    .select('*')
                    .order('title');

                if (error) {
                    throw error;
                }

                allModules = data;
                filteredModules = [...allModules];
            } catch (error) {
                console.error('Error loading modules:', error);
                displayError('Failed to fetch modules from database');
            }
        }

        // Set up event listeners
        function setupEventListeners() {
            // Filter buttons
            document.querySelectorAll('.filter-tab').forEach(button => {
                button.addEventListener('click', function() {
                    const grade = this.getAttribute('data-grade');
                    filterByGrade(grade);
                });
            });

            // Close modal
            document.getElementById('loginModal').addEventListener('click', function(e) {
                if (e.target === this) {
                    this.classList.remove('active');
                }
            });
        }

        // Filter modules by grade
        function filterByGrade(grade) {
            // Update active button
            document.querySelectorAll('.filter-tab').forEach(button => {
                button.classList.remove('active');
                if (button.getAttribute('data-grade') === grade) {
                    button.classList.add('active');
                }
            });

            // Filter modules
            if (grade === 'all') {
                filteredModules = [...allModules];
            } else {
                filteredModules = allModules.filter(module => module.grade_level === grade);
            }

            // Display modules
            displayModules(filteredModules);
        }

        // Display modules
        function displayModules(modules) {
            const modulesGrid = document.getElementById('modulesGrid');
            const loadingDiv = document.getElementById('loading');
            const emptyStateDiv = document.getElementById('emptyState');

            // Hide loading
            loadingDiv.style.display = 'none';

            if (modules.length === 0) {
                // Show empty state
                modulesGrid.style.display = 'none';
                emptyStateDiv.style.display = 'block';
            } else {
                // Show modules
                modulesGrid.style.display = 'grid';
                emptyStateDiv.style.display = 'none';

                // Render modules
                modulesGrid.innerHTML = modules.map(module => createModuleCard(module)).join