import re
import os

def check_links(file_path, base_dir):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    links = re.findall(r'href=["\'](.*?)["\']', content)
    links.extend(re.findall(r'src=["\'](.*?)["\']', content))
    
    broken_links = []
    for link in links:
        if link.startswith('#') or link.startswith('http') or not link:
            continue
        
        # Handle relative paths
        target_path = os.path.join(base_dir, link)
        if not os.path.exists(target_path):
            broken_links.append(link)
    
    return broken_links

def check_all_html_files(directory):
    broken_links = {}
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.html'):
                file_path = os.path.join(root, file)
                base_dir = os.path.dirname(file_path)
                links = check_links(file_path, base_dir)
                if links:
                    broken_links[file_path] = links
    
    return broken_links

if __name__ == "__main__":
    public_dir = os.path.join(os.path.dirname(__file__), 'public')
    broken_links = check_all_html_files(public_dir)
    
    if broken_links:
        print("Found broken links:")
        for file_path, links in broken_links.items():
            print(f"\nFile: {file_path}")
            for link in links:
                print(f"  - {link}")
    else:
        print("All links are valid")