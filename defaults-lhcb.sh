package: defaults-lhcb
version: v1
env:
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
  MACOSX_DEPLOYMENT_TARGET: '14.0'

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
  Moore:
    tag: "v58r8"
  Python:
    version: "3.9.16"
  ROOT:
    tag: "v6-36-04"
  boost:
    version: "1.88.0"
  GitCondDB:
    version: "0.2.2"
  rapidyaml:
    version: "0.7.0"
  zlib:
    version: "1.2.11"
  LCIO:
    version: "2.22.6"
  DD4Hep:
    version: "1.34"
  CLHEP:
    version: "2.4.7.1"
  Eigen3:
    version: "3.4.1"
  cppgsl:
    version: "2.8"
  nlohmann_json:
    version: "3.11.3"
  ONNXRuntime:
    version: "1.23.2"
  Vc:
    versionn: "1.4.5"
  vdt:
    version: "0.4"
  XercesC:
    version: "3.3.0"
  yamlcpp:
    version: "0.6.3"
  fmt:
    version: "10.2.1"
  TBB:
    version: "2022.2.0"
----


