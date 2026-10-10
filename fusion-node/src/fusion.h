#pragma once

#include <cstdint>
#include <map>

#include "libtrack/kalman_cv.h"
#include "proto/detection.pb.h"

namespace fusion {

struct Config {
  double accel_noise = 0.1;
  double meas_noise = 0.25;  // variance, m^2
  double init_pos_var = 1.0;
  double init_vel_var = 100.0;
};

// Builds one track per target_id (association by ID for now).
std::map<std::uint32_t, libtrack::Track2D> Run(
    const swarmforge::v1::Scenario& scenario, const Config& config = Config());

}  // namespace fusion
