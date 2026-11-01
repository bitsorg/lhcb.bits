package: TMVAWeights
description: LHCb data package TMVAWeights (MVA weights)
version: "%(tag_basename)s"
tag: "v1r20"
source: https://gitlab.cern.ch/lhcb-datapkg/TMVAWeights.git
build_requires:
  - bits-recipe-tools
---
#!/bin/bash -e
# Installed as <prefix>/TMVAWeights/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/TMVAWeights/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv TMVAWEIGHTSROOT \$PKG_ROOT/TMVAWeights/$PKGVERSION
EoF
