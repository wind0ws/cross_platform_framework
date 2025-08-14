import os
import sys
import re
import zipfile
import requests
import argparse
from urllib.parse import urlparse
from pathlib import Path


def download_file(url, dest_folder):
    local_filename = url.split('/')[-1]
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        dest_path = Path(dest_folder) / local_filename
        with open(dest_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192): 
                f.write(chunk)
    return dest_path

def unzip_file(zip_path, extract_to='.'):
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)

def get_latest_cjson_zipball_url():
    response = requests.get('https://api.github.com/repos/DaveGamble/cJSON/releases/latest')
    response.raise_for_status()  # 如果请求失败，则抛出异常
    release_info = response.json()
    return release_info['zipball_url']

def update_include_statement(file_path, old_header_name, new_header_name):
    """Update the include statement in the source file to point to the new header name."""
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    # Replace the old header include statement with the new one
    updated_content = re.sub(rf'#include\s+["<]{old_header_name}[">]', f'#include "{new_header_name}"', content)

    # Save the modified content back to the file
    with open(file_path, 'w', encoding='utf-8') as file:
        file.write(updated_content)

def replace_prefix_in_files(file_paths, prefix, old_header_name):
    for file_path in file_paths:
        # Update the include statement if it's cJSON.c
        if file_path.name == 'cJSON.c':
            new_header_name = f"{prefix}{old_header_name}"
            update_include_statement(file_path, old_header_name, new_header_name)

        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()

        # Replace all occurrences of cJSON_ with the new prefix followed by cJSON_
        updated_content = re.sub(r'\bcJSON_([a-zA-Z0-9_]+)\b', rf'{prefix}cJSON_\1', content)

        # Save the modified content to a new file
        new_file_name = f"{prefix}{file_path.name}"
        with open(new_file_name, 'w', encoding='utf-8') as file:
            file.write(updated_content)
        
        print(f" save it ==> {new_file_name}")

def main():
    parser = argparse.ArgumentParser(description="Add prefix to cJSON functions.")
    parser.add_argument('--func_prefix', default='my_', help='Prefix to add to function names')
    parser.add_argument('--cjson_url', help='URL to cJSON release package, default we pick latest package.')

    args = parser.parse_args()

    func_prefix = args.func_prefix
    cjson_url = args.cjson_url or get_latest_cjson_zipball_url()
    print(f" func_prefix={func_prefix} \n cjson_url={cjson_url}\n")

    temp_dir = 'temp_cjson'
    os.makedirs(temp_dir, exist_ok=True)

    zip_path = download_file(cjson_url, temp_dir)
    unzip_file(zip_path, temp_dir)

    # Find cJSON.c and cJSON.h in the extracted files
    cjson_files = []
    for root, _, files in os.walk(temp_dir):
        for name in files:
            if name in ('cJSON.c', 'cJSON.h'):
                cjson_files.append(Path(root) / name)

    if len(cjson_files) != 2:
        print("Error: Could not find both cJSON.c and cJSON.h files.")
        sys.exit(1)

    replace_prefix_in_files(cjson_files, func_prefix, 'cJSON.h')
    print("done of task.")

if __name__ == '__main__':
    main()
    print("\n bye... \n")
