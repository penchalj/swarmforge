"""Synthetic sensor: noisy detections of targets moving at constant velocity."""

import argparse
import random
import sys

from proto import detection_pb2


def generate(num_targets=3, num_frames=200, dt=0.1, noise=0.5, seed=42):
    """Returns (scenario, truth); truth[i] = (x0, y0, vx, vy) for target i+1."""
    rng = random.Random(seed)
    truth = [
        (
            rng.uniform(-100, 100),
            rng.uniform(-100, 100),
            rng.uniform(-5, 5),
            rng.uniform(-5, 5),
        )
        for _ in range(num_targets)
    ]
    scenario = detection_pb2.Scenario()
    for k in range(num_frames):
        t = k * dt
        frame = scenario.frames.add()
        frame.timestamp_s = t
        for i, (x0, y0, vx, vy) in enumerate(truth):
            det = frame.detections.add()
            det.target_id = i + 1
            det.x = x0 + vx * t + rng.gauss(0.0, noise)
            det.y = y0 + vy * t + rng.gauss(0.0, noise)
            det.sensor = "radar"
    return scenario, truth


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="output file (.pb)")
    parser.add_argument("--targets", type=int, default=3)
    parser.add_argument("--frames", type=int, default=200)
    parser.add_argument("--dt", type=float, default=0.1)
    parser.add_argument("--noise", type=float, default=0.5)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args(argv)

    scenario, truth = generate(
        args.targets, args.frames, args.dt, args.noise, args.seed
    )
    with open(args.out, "wb") as f:
        f.write(scenario.SerializeToString())
    for i, (_, _, vx, vy) in enumerate(truth, start=1):
        print(f"truth target {i}: vx={vx:.3f} vy={vy:.3f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
