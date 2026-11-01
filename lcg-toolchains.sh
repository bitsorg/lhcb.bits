package: lcg-toolchains
description: LHCb's lcg-toolchains fragments (compiler flags, package handling) that the lcg-view toolchain includes
version: "%(short_hash)s"
tag: "e5d8a399ab8d815e38ee9f1172ed24dbfe890daf"   # master of 2026-07-29 (LHCB_11 added)
source: https://gitlab.cern.ch/lhcb-core/lcg-toolchains.git
build_requires:
  - bits-recipe-tools
license: GPL-3.0-only
env:
  LCG_TOOLCHAINS_DIR: "$LCG_TOOLCHAINS_ROOT"
---
#!/bin/bash -e
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--root"
rsync -a --exclude .git "$SOURCEDIR"/ "$INSTALLROOT"/
MakeModule
echo "setenv LCG_TOOLCHAINS_DIR \$PKG_ROOT" >> "$MODULEFILE"
