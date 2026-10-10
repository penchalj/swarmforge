#include "fusion-node/src/fusion.h"

#include "gtest/gtest.h"

namespace {

// Two targets moving at known constant velocities, no noise.
swarmforge::v1::Scenario MakeScenario() {
  swarmforge::v1::Scenario s;
  for (int k = 0; k < 300; ++k) {
    const double t = 0.1 * k;
    auto* frame = s.add_frames();
    frame->set_timestamp_s(t);
    auto* a = frame->add_detections();
    a->set_target_id(1);
    a->set_x(1.0 * t);
    a->set_y(2.0 * t);
    auto* b = frame->add_detections();
    b->set_target_id(2);
    b->set_x(50.0 - 3.0 * t);
    b->set_y(10.0);
  }
  return s;
}

}  // namespace

TEST(Fusion, CreatesOneTrackPerTarget) {
  EXPECT_EQ(fusion::Run(MakeScenario()).size(), 2u);
}

TEST(Fusion, EstimatesVelocityPerTarget) {
  const auto tracks = fusion::Run(MakeScenario());
  EXPECT_NEAR(tracks.at(1).x().vel, 1.0, 0.05);
  EXPECT_NEAR(tracks.at(1).y().vel, 2.0, 0.05);
  EXPECT_NEAR(tracks.at(2).x().vel, -3.0, 0.05);
  EXPECT_NEAR(tracks.at(2).y().vel, 0.0, 0.05);
}

TEST(Fusion, EmptyScenarioGivesNoTracks) {
  EXPECT_TRUE(fusion::Run(swarmforge::v1::Scenario()).empty());
}
