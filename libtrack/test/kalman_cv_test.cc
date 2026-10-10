#include "libtrack/kalman_cv.h"

#include <stdexcept>

#include "gtest/gtest.h"

using libtrack::KalmanCV1D;
using libtrack::Track2D;

TEST(KalmanCV1D, ConvergesToConstantVelocity) {
  KalmanCV1D kf(0.01, 0.1);
  kf.Init(0.0, 1.0, 10.0);
  const double dt = 0.1, vel = 2.0;
  for (int i = 1; i <= 200; ++i) {
    kf.Predict(dt);
    kf.Update(vel * dt * i);
  }
  EXPECT_NEAR(kf.state().vel, vel, 0.05);
  EXPECT_NEAR(kf.state().pos, vel * dt * 200, 0.05);
}

TEST(KalmanCV1D, PredictIncreasesUncertainty) {
  KalmanCV1D kf(0.5, 0.1);
  kf.Init(0.0, 1.0, 1.0);
  const double before = kf.state().p00;
  kf.Predict(1.0);
  EXPECT_GT(kf.state().p00, before);
}

TEST(KalmanCV1D, UpdateReducesUncertainty) {
  KalmanCV1D kf(0.5, 0.1);
  kf.Init(0.0, 1.0, 1.0);
  kf.Predict(1.0);
  const double before = kf.state().p00;
  kf.Update(0.5);
  EXPECT_LT(kf.state().p00, before);
}

TEST(KalmanCV1D, RejectsInvalidInput) {
  EXPECT_THROW(KalmanCV1D(0.1, 0.0), std::invalid_argument);
  KalmanCV1D kf(0.1, 0.1);
  EXPECT_THROW(kf.Predict(-1.0), std::invalid_argument);
}

TEST(Track2D, TracksDiagonalMotion) {
  Track2D t(0.01, 0.1);
  t.Init(0.0, 0.0, 1.0, 10.0);
  for (int i = 1; i <= 200; ++i) {
    t.Predict(0.1);
    t.Update(1.0 * 0.1 * i, -3.0 * 0.1 * i);
  }
  EXPECT_NEAR(t.x().vel, 1.0, 0.05);
  EXPECT_NEAR(t.y().vel, -3.0, 0.05);
}
