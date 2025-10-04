#!/usr/bin/env python3
import os
from pathlib import Path
import heapq
import pathspec

# 1. Load .gitignore
gitignore_file = Path(".gitignore")
if gitignore_file.exists():
    with gitignore_file.open("r") as f:
        gitignore_patterns = f.read().splitlines()
else:
    gitignore_patterns = []

spec = pathspec.PathSpec.from_lines("gitwildmatch", gitignore_patterns)

# 2. Traverse the directory
file_sizes = []

for root, dirs, files in os.walk("."):
    # Remove ignored directories from traversal
    dirs[:] = [d for d in dirs if not spec.match_file(os.path.relpath(os.path.join(root, d), "."))]
    for file in files:
        filepath = os.path.join(root, file)
        relpath = os.path.relpath(filepath, ".")
        if spec.match_file(relpath):
            continue
        try:
            size = os.path.getsize(filepath)
            file_sizes.append((size, relpath))
        except OSError:
            continue

# 3. Get top 20 largest files
top20 = heapq.nlargest(20, file_sizes)

print("Top 20 largest files (size in bytes):")
for size, path in top20:
    print(f"{size:>10}  {path}")

