#include "fusion-node/src/fusion.h"

namespace fusion {

std::map<std::uint32_t, libtrack::Track2D> Run(
    const swarmforge::v1::Scenario& scenario, const Config& config) {
  std::map<std::uint32_t, libtrack::Track2D> tracks;
  bool first = true;
  double last_t = 0.0;

  for (const auto& frame : scenario.frames()) {
    if (!first) {
      const double dt = frame.timestamp_s() - last_t;
      for (auto& kv : tracks) kv.second.Predict(dt);
    }
    for (const auto& d : frame.detections()) {
      auto it = tracks.find(d.target_id());
      if (it == tracks.end()) {
        libtrack::Track2D track(config.accel_noise, config.meas_noise);
        track.Init(d.x(), d.y(), config.init_pos_var, config.init_vel_var);
        tracks.emplace(d.target_id(), track);
      } else {
        it->second.Update(d.x(), d.y());
      }
    }
    last_t = frame.timestamp_s();
    first = false;
  }
  return tracks;
}

}  // namespace fusion
