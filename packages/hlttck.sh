package: HltTCK
description: LHCb data package TCK/HltTCK (trigger configuration keys)
version: "%(tag_basename)s"
tag: "v3r19p29"
source: https://gitlab.cern.ch/lhcb-datapkg/TCK/HltTCK.git
build_requires:
  - bits-recipe-tools
---
#!/bin/bash -e
# Installed as <prefix>/TCK/HltTCK/<version>, where LHCb's find_data_package looks
# (the module puts <prefix> on CMAKE_PREFIX_PATH); the module sets what its xenv sets.
. $(bits-include ModuleRecipe)
MODULE_OPTIONS="--cmake"
dest="$INSTALLROOT/TCK/HltTCK/$PKGVERSION"
mkdir -p "$dest"
rsync -a --exclude .git "$SOURCEDIR"/ "$dest"/
# The TCK database is downloaded by its Makefile from lhcb-datapkg.web.cern.ch
# (about 280 MB), its sha256 checked against the pointer files in git.
make -C "$dest"
MakeModule
cat >> "$MODULEFILE" <<EoF
setenv HLTTCKROOT \$PKG_ROOT/TCK/HltTCK/$PKGVERSION
EoF
