package: lcg-externals
description: LHCb top-level LCG externals meta-package. Requires the full LHCb
  externals set (the .heptools.packages[] list from lhcb-core/rpm-recipes
  LHCBEXTERNALS/dev4lhcb.json), so building this one target pulls the whole LHCb
  externals closure from lcg.bits — the bits analog of lcgcmake's
  LCG_top_packages()/`top_packages` target. Package versions come from the
  selected lcg.bits release branch (--flavour release=...); LHCb-specific version
  and variant deltas are pinned in defaults-lhcb.sh. Gaudi is NOT here (it is a
  project, built from lhcb.bits/gaudi.sh, not an external).
version: "1"
license: Apache-2.0
requires:
  - lcg.bits
  - AIDA
  - Boost
  - Catch2
  - DD4hep
  - GSL
  - GitCondDB
  - HepPDT
  - Jinja2
  - PyYAML
  - Python
  - RELAX
  - ROOT
  - Vc
  - XercesC
  - blas
  - cachetools
  - catboost
  - chardet
  - clhep
  - click
  - coverage
  - cppgsl
  - cppzmq
  - crmc
  - doxygen
  - eigen
  - fastjet
  - fftw
  - fjcontrib
  - flatbuffers
  - fmt
  - gdb
  - gperftools
  - graphviz
  - herwig3
  - idna
  - ipython
  - jemalloc
  - jsonmcpp
  - lhapdf
  - libgit2
  - libunwind
  - libxml2
  - lxml
  - madgraph5amc
  - matplotlib
  - mpmath
  - networkx
  - onnxruntime
  # - oracle          # OTN-licensed: never on public CVMFS (lcg.bits recipe is a stub)
  - orjson
  - packaging
  - pathos
  - photoscpp
  - powheg-box-v2
  - pydantic
  - pydot
  - pyeda
  - pytest
  - pytest_cov
  - pythia6
  - pythia8
  - pyxxhash
  - pyzmq
  - rapidyaml
  - rangev3
  - rivet
  - ruamel_yaml
  - six
  - sortedcontainers
  - spdlog
  - sqlite
  - starlight
  - superchic
  - sympy
  - tauolacpp
  - tbb
  - tensorflow
  - thepeg
  - torch
  - vdt
  - veccore
  - vectorclass
  - wcwidth
  - wrapt
  - xgboost
  - xrootd
  - yamlcpp
  - yoda
build_requires:
  - bits-recipe-tools
  - "GCC-Toolchain:(?!osx)"
---
