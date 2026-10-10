#include "libtrack/kalman_cv.h"

#include <stdexcept>

namespace libtrack {

KalmanCV1D::KalmanCV1D(double accel_noise, double meas_noise)
    : q_(accel_noise), r_(meas_noise) {
  if (q_ < 0.0 || r_ <= 0.0) {
    throw std::invalid_argument("noise values must be positive");
  }
}

void KalmanCV1D::Init(double pos, double pos_var, double vel_var) {
  s_ = AxisState{pos, 0.0, pos_var, 0.0, 0.0, vel_var};
}

void KalmanCV1D::Predict(double dt) {
  if (dt < 0.0) throw std::invalid_argument("dt must be >= 0");
  const double dt2 = dt * dt;
  const double q00 = q_ * dt2 * dt2 / 4.0;
  const double q01 = q_ * dt2 * dt / 2.0;
  const double q11 = q_ * dt2;

  s_.pos += s_.vel * dt;
  const double p00 = s_.p00 + dt * (s_.p01 + s_.p10) + dt2 * s_.p11 + q00;
  const double p01 = s_.p01 + dt * s_.p11 + q01;
  const double p10 = s_.p10 + dt * s_.p11 + q01;
  const double p11 = s_.p11 + q11;
  s_.p00 = p00; s_.p01 = p01; s_.p10 = p10; s_.p11 = p11;
}

void KalmanCV1D::Update(double z) {
  const double innovation = z - s_.pos;
  const double s = s_.p00 + r_;
  const double k0 = s_.p00 / s;
  const double k1 = s_.p10 / s;

  s_.pos += k0 * innovation;
  s_.vel += k1 * innovation;
  const double p00 = (1.0 - k0) * s_.p00;
  const double p01 = (1.0 - k0) * s_.p01;
  const double p10 = s_.p10 - k1 * s_.p00;
  const double p11 = s_.p11 - k1 * s_.p01;
  s_.p00 = p00; s_.p01 = p01; s_.p10 = p10; s_.p11 = p11;
}

}  // namespace libtrack
