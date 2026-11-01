package: QMTestFiles
description: LHCb data package QMTestFiles (QM test input files)
version: "%(tag_basename)s"
tag: "v1r3"
source: https://gitlab.cern.ch/lhcb-datapkg/QMTestFiles.git
build_requires:
  - bits-recipe-tools
---
#!/bin/bash -e
# Installed as <prefix>/QMTestFiles/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/QMTestFiles/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv QMTESTFILESROOT \$PKG_ROOT/QMTestFiles/$PKGVERSION
EoF
