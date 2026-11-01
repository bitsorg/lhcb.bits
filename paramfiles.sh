package: ParamFiles
description: LHCb data package ParamFiles (parameter files)
version: "%(tag_basename)s"
tag: "v8r72"
source: https://gitlab.cern.ch/lhcb-datapkg/ParamFiles.git
build_requires:
  - bits-recipe-tools
---
#!/bin/bash -e
# Installed as <prefix>/ParamFiles/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/ParamFiles/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv PARAMFILESROOT \$PKG_ROOT/ParamFiles/$PKGVERSION
EoF
