package: defaults-lhcb
version: v1
env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
  MACOSX_DEPLOYMENT_TARGET: '14.0'

requires:
  - common.bits

package_family:
  default: externals
  lcg:
    - ROOT
  lhcb:
    - Gaudi  
  
overrides:
  Gaudi:
    tag: "v40r2"
  Detector:
    tag: "v3r9"
  LHCb:
    tag: "v58r8"
  Lbcom:
    tag: "v38r8"
  Rec:
    tag: "v39r8"
  Allen:
    tag: "v7r8"
  stacks.bits:
    tag: "v109"
---
