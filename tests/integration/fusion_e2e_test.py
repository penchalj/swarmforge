"""Python detector -> Protobuf file -> C++ fusion-node -> compare with truth."""

import csv
import io
import os
import subprocess
import unittest

from detector import sim_detector


class FusionEndToEndTest(unittest.TestCase):

    def test_fused_velocities_match_truth(self):
        scenario, truth = sim_detector.generate(
            num_targets=3, num_frames=300, dt=0.1, noise=0.5, seed=7)

        path = os.path.join(os.environ["TEST_TMPDIR"], "scenario.pb")
        with open(path, "wb") as f:
            f.write(scenario.SerializeToString())

        result = subprocess.run(
            [os.environ["FUSION_NODE"], path],
            check=True, capture_output=True, text=True)
        rows = list(csv.DictReader(io.StringIO(result.stdout)))

        self.assertEqual(len(rows), 3)
        for row in rows:
            _, _, vx, vy = truth[int(row["target_id"]) - 1]
            self.assertAlmostEqual(float(row["vx"]), vx, delta=0.3)
            self.assertAlmostEqual(float(row["vy"]), vy, delta=0.3)


if __name__ == "__main__":
    unittest.main()
