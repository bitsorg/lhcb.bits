# SPDX-FileCopyrightText: 2026 CERN
# SPDX-License-Identifier: GPL-3.0-or-later
"""python3 -m unittest discover -s tools: the rules of lcg-deltas.py."""
import importlib.util
import os
import unittest

_spec = importlib.util.spec_from_file_location(
    "lcg_deltas", os.path.join(os.path.dirname(__file__), "lcg-deltas.py"))
ld = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ld)


class Rules(unittest.TestCase):
    def test_names(self):
        self.assertEqual(ld.key("Garfield++"), ld.key("GarfieldCPP"))
        self.assertEqual(ld.key("sherpa-openmpi"), ld.key("sherpa_openmpi"))

    def test_versions_keep_the_recipe_form(self):
        self.assertEqual(ld.follow("v6.40.02", "v6.40.02", "6.36.12"), "v6.36.12")
        self.assertEqual(ld.follow("v6-40-02", "v6.40.02", "6.36.12"), "v6-36-12")
        self.assertEqual(ld.follow("v01-35", "v01-35", "01.37"), "v01-37")
        self.assertEqual(ld.follow(".../boost_1_91_0.tar.gz", "1.91.0", "1.88.0"),
                         ".../boost_1_88_0.tar.gz")
        self.assertEqual(ld.follow("CLHEP_2_4_7_2", "2.4.7.2", "2.4.7.1"), "CLHEP_2_4_7_1")
        self.assertIsNone(ld.follow("main", "1.0", "2.0"))
        # Every form, and only whole numbers.
        self.assertEqual(ld.follow("x/v1.2.3/foo-1.2.3.tgz", "1.2.3", "1.2.4"), "x/v1.2.4/foo-1.2.4.tgz")
        self.assertEqual(ld.follow("py3.10/foo-3.1", "3.1", "3.2"), "py3.10/foo-3.2")
        self.assertTrue(ld.same("02.02.01", "2.2.1"))

    def test_build_labels(self):
        self.assertEqual(ld.lcg_version("0.3.29.openblas", "0.3.33"), "0.3.29")
        self.assertEqual(ld.lcg_version("3.3.1.lhcb1", "3.3.1"), "3.3.1.lhcb1")

    def test_what_stays_at_the_lcg_bits_version(self):
        h = lambda **kw: dict({"package": "p", "version": "3.3.1", "_gates": [], "_patches": []}, **kw)
        self.assertIn("no patch", ld.keep_reason(h(), "3.3.1.lhcb1"))
        self.assertIsNone(ld.keep_reason(h(), "2.9.0.post1"))
        self.assertIn("is for", ld.keep_reason(h(version="1.0.21", _patches=["libsodium-1.0.21.patch"]), "1.0.18"))
        self.assertIsNone(ld.keep_reason(h(version="3.5.1", _patches=["fastjet-fix.patch"]), "3.5.0"))

    def test_override(self):
        h = {"package": "Boost", "version": "1.91.0", "tag": "1.91.0", "_gates": [],
             "_patches": [], "sources": ["https://x/boost_1_91_0.tar.gz"]}
        self.assertEqual(ld.override(h, "1.88.0", False),
                         ({"version": "1.88.0", "tag": "1.88.0",
                           "sources": ["https://x/boost_1_88_0.tar.gz"]}, []))
        h = {"package": "crmc", "version": "2.0.1p5", "tag": "2.0.1p5", "_patches": [],
             "_gates": ["2.0.1p5", "2.0.1p6.lhcb"]}
        self.assertIn("patches are for", ld.keep_reason(h, "2.0.1p7"))
        # The LCG mirror's name; a prefixed tag keeps its prefix.
        h = {"package": "DD4hep", "version": "v01-35", "tag": "v01-35", "_gates": [], "_patches": [],
             "sources": ["https://lcgpackages.web.cern.ch/s/%(name)s-%(version)s.tar.gz"]}
        self.assertEqual(ld.override(h, "01.37", False)[0]["sources"],
                         ["https://lcgpackages.web.cern.ch/s/%(name)s-01.37.tar.gz"])
        h = {"package": "x", "version": "%(tag_basename)s", "tag": "Release_1_17_0",
             "_gates": [], "_patches": []}
        self.assertEqual(ld.override(h, "1.14.0", False)[0], {"tag": "Release_1_14_0"})


if __name__ == "__main__":
    unittest.main()
