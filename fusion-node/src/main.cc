#include <cstdio>
#include <fstream>
#include <iostream>

#include "fusion-node/src/fusion.h"

int main(int argc, char** argv) {
  if (argc != 2) {
    std::cerr << "usage: fusion_node <scenario.pb>\n";
    return 2;
  }
  std::ifstream in(argv[1], std::ios::binary);
  swarmforge::v1::Scenario scenario;
  if (!in || !scenario.ParseFromIstream(&in)) {
    std::cerr << "error: cannot read " << argv[1] << "\n";
    return 1;
  }

  const auto tracks = fusion::Run(scenario);
  std::printf("target_id,x,y,vx,vy\n");
  for (const auto& kv : tracks) {
    const auto& t = kv.second;
    std::printf("%u,%.3f,%.3f,%.3f,%.3f\n", kv.first, t.x().pos, t.y().pos,
                t.x().vel, t.y().vel);
  }
  return 0;
}
