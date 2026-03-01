with open('public/guest-modules.html', 'w', encoding='utf-8') as f:
    f.write('''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/png" href="Logo/MATHURO-LOGO.png">
    <title>Learning Modules - MathTuro LMS</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://unpkg.com/@supabase/supabase-js@2"></script>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;600;700;800;900&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
            background: #f5f5f5;
        }
        
        .font-montserrat {
            font-family: 'Montserrat', sans-serif;
        }
        
        .module-card {
            background: white;
            border-radius: 20px;
            padding: 2rem;
            transition: all 0.3s ease;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            cursor: pointer;
        }
        
        .module-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 20px 40px rgba(0,88,1,0.15);
            border: 2px solid #005801;
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
        
        .difficulty-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .difficulty-beginner {
            background: #E8F5E8;
            color{