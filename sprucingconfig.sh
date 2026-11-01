package: SprucingConfig
description: LHCb data package SprucingConfig (sprucing configuration)
version: "%(tag_basename)s"
tag: "v26r7p2"
source: https://gitlab.cern.ch/lhcb-datapkg/SprucingConfig.git
build_requires:
  - bits-recipe-tools
---
#!/bin/bash -e
# Installed as <prefix>/SprucingConfig/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/SprucingConfig/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
MakeModule
cat >> "$MODULEFILE" <<EoF
prepend-path PYTHONPATH \$PKG_ROOT/SprucingConfig/$PKGVERSION
EoF
