import unittest

from detector import sim_detector


class GenerateTest(unittest.TestCase):
    def test_shape(self):
        scenario, truth = sim_detector.generate(num_targets=2, num_frames=10)
        self.assertEqual(len(scenario.frames), 10)
        self.assertEqual(len(truth), 2)
        for frame in scenario.frames:
            self.assertEqual(len(frame.detections), 2)

    def test_same_seed_gives_same_output(self):
        a, _ = sim_detector.generate(seed=1)
        b, _ = sim_detector.generate(seed=1)
        self.assertEqual(a.SerializeToString(), b.SerializeToString())

    def test_noiseless_detections_match_truth(self):
        scenario, truth = sim_detector.generate(
            num_targets=1, num_frames=5, dt=0.5, noise=0.0
        )
        x0, y0, vx, vy = truth[0]
        det = scenario.frames[4].detections[0]  # t = 2.0 s
        self.assertAlmostEqual(det.x, x0 + vx * 2.0)
        self.assertAlmostEqual(det.y, y0 + vy * 2.0)


if __name__ == "__main__":
    unittest.main()
