#!/usr/bin/env python3

import os
import sys
from pathlib import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "readies"))
import paella

paella.mkdir_p('install')
for f in Path('tensorflow').glob('**/*.so*'):
    os.symlink(f, Path('install')/os.path.basename(f))
for f in Path('torch').glob('**/*.so*'):
    os.symlink(f, Path('install')/os.path.basename(f))
