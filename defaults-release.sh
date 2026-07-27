package: defaults-release
version: v1

# CVMFS path templates — LHCb's declaration of where its packages, modulefiles
# and noarch content land on CVMFS (its structural choice). Under system: so they
# never affect a package hash. The build records them in each package's
# .meta.json (cvmfs_templates); the publish pipeline resolves them there, so the
# path is never defined in bits-console.
system:
  # {prefix} is the releases ROOT (auth boundary). bits-console (ui-config.yaml:
  # cvmfs_prefix) injects the authoritative value, which WINS; the value below MUST
  # match it (kept in sync by bits-admin PR) or an injected build refuses to publish.
  # It lets local `bits build` (no injection) work and is a checked declaration.
  prefix:                     "/cvmfs/bits.cern.ch/lhcb/releases"
  cvmfs_user_prefix:          "/cvmfs/bits.cern.ch/lhcb/user"  # sibling of releases, not {prefix}/user
  cvmfs_releases_template:    "{prefix}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/noarch/{pkg}/{tag}"

env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
---
  
    
