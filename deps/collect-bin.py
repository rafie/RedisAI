#!/usr/bin/env python3

import os
import sys
from pathlib import Path
import itertools

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "readies"))
import paella

paella.mkdir_p('install')
for f in itertools.chain(Path('tensorflow').glob('**/*.so*'), Path('libtorch').glob('**/*.so*')):
    link = Path('install')/os.path.basename(f)
    if link.exists():
        os.unlink(link)
    os.symlink(Path('..')/f, link)
