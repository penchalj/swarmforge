#pragma once

namespace libtrack {

struct AxisState {
  double pos = 0.0, vel = 0.0;
  double p00 = 1.0, p01 = 0.0, p10 = 0.0, p11 = 1.0;  // covariance
};

// 1D constant-velocity Kalman filter.
class KalmanCV1D {
 public:
  KalmanCV1D(double accel_noise, double meas_noise);
  void Init(double pos, double pos_var, double vel_var);
  void Predict(double dt);
  void Update(double measured_pos);
  const AxisState& state() const { return s_; }

 private:
  double q_, r_;
  AxisState s_;
};

// 2D track = one filter per axis.
class Track2D {
 public:
  Track2D(double accel_noise, double meas_noise)
      : x_(accel_noise, meas_noise), y_(accel_noise, meas_noise) {}
  void Init(double x, double y, double pos_var, double vel_var) {
    x_.Init(x, pos_var, vel_var);
    y_.Init(y, pos_var, vel_var);
  }
  void Predict(double dt) {
    x_.Predict(dt);
    y_.Predict(dt);
  }
  void Update(double mx, double my) {
    x_.Update(mx);
    y_.Update(my);
  }
  const AxisState& x() const { return x_.state(); }
  const AxisState& y() const { return y_.state(); }

 private:
  KalmanCV1D x_, y_;
};

}  // namespace libtrack
