package: AppConfig
description: LHCb data package AppConfig (application options)
version: "%(tag_basename)s"
tag: "v3r469"
source: https://gitlab.cern.ch/lhcb-datapkg/AppConfig.git
build_requires:
  - bits-recipe-tools
---
#!/bin/bash -e
# Installed as <prefix>/AppConfig/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/AppConfig/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv APPCONFIGROOT \$PKG_ROOT/AppConfig/$PKGVERSION
setenv APPCONFIGOPTS \$PKG_ROOT/AppConfig/$PKGVERSION/options
EoF
