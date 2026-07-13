package: defaults-release
version: v1

# CVMFS path templates — LHCb's declaration of where its packages, modulefiles
# and noarch content land on CVMFS (its structural choice). Under system: so they
# never affect a package hash. The build records them in each package's
# .meta.json (cvmfs_templates); the publish pipeline resolves them there, so the
# path is never defined in bits-console.
system:
  prefix:                     "/cvmfs/sft-nightlies-test.cern.ch/lhcb/releases"
  cvmfs_user_prefix:          "/cvmfs/sft-nightlies-test.cern.ch/lhcb/user"  # sibling of releases, not {prefix}/user
  cvmfs_releases_template:    "{prefix}/{pkg}/{tag}/{platform}"
  cvmfs_modules_template:     "{prefix}/{platform}/Modules/modulefiles/{pkg}"
  cvmfs_shared_path_template: "{prefix}/noarch/{pkg}/{tag}"

env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
---
  
    
