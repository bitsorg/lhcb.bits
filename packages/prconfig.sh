package: PRConfig
description: LHCb data package PRConfig (performance and regression test configuration)
version: "%(tag_basename)s"
tag: "v1r116"
source: https://gitlab.cern.ch/lhcb-datapkg/PRConfig.git
build_requires:
  - bits-recipe-tools
license: GPL-3.0-only
---
#!/bin/bash -e
# Installed as <prefix>/PRConfig/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/PRConfig/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv PRCONFIGROOT \$PKG_ROOT/PRConfig/$PKGVERSION
setenv PRCONFIGOPTS \$PKG_ROOT/PRConfig/$PKGVERSION/options
prepend-path PYTHONPATH \$PKG_ROOT/PRConfig/$PKGVERSION/python
EoF
