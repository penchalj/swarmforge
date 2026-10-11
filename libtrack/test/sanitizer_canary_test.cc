// Deliberately broken code. The sanitizer lane runs these tests and expects
// them to FAIL: that proves ASan and UBSan really detect bugs. Tagged
// "manual" so they never run in normal builds.
#include <climits>
#include <vector>

#include "gtest/gtest.h"

TEST(AsanCanary, ReadsPastTheEndOfAVector) {
  std::vector<int> values(4, 1);
  volatile int* data = values.data();
  EXPECT_EQ(data[4], 1);  // heap-buffer-overflow
}

TEST(UbsanCanary, OverflowsASignedInt) {
  volatile int big = INT_MAX;
  volatile int one = 1;
  EXPECT_GT(big + one, 0);  // signed integer overflow
}
