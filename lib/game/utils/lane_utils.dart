// lane_util.dart
enum Lane { left, center, right }

const Map<Lane, double> laneX = {
  Lane.left: 100.0,
  Lane.center: 180.0,
  Lane.right: 280.0,
};

Lane getLaneForX(double x) {
  if ((x - laneX[Lane.left]!).abs() < 45) return Lane.left;
  if ((x - laneX[Lane.center]!).abs() < 45) return Lane.center;
  return Lane.right;
}

