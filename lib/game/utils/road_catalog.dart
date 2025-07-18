// road_catalog.dart

class RoadModel {
  final int id;
  final String name;
  final String centerSprite;
  final String leftSprite;
  final String rightSprite;
  final int cost;
  bool isOwned;
  RoadModel({
    required this.id,
    required this.name,
    required this.centerSprite,
    required this.leftSprite,
    required this.rightSprite,
    required this.cost,
    this.isOwned = false,
  });
}

// Catalog of all available roads
final List<RoadModel> allRoads = [
  RoadModel(
    id: 1,
    name: 'Cyber City',
    centerSprite: 'roads/road_1.png',
    leftSprite: 'roads/left.png',
    rightSprite: 'roads/right.png',
    cost: 0,
    isOwned: true,
  ),
  RoadModel(
    id: 2,
    name: 'Snow Valley',
    centerSprite: 'roads/road2.png',
    leftSprite: 'roads/left2.png',
    rightSprite: 'roads/right2.png',
    // cost: 2999,
    cost: -9999,
  ),
  RoadModel(
    id: 3,
    name: 'Sunset Drive',
    centerSprite: 'roads/road3.png',
    leftSprite: 'roads/left3.png',
    rightSprite: 'roads/right3.png',
    cost: 4999,
  ),
  RoadModel(
    id: 4,
    name: 'Desert',
    centerSprite: 'roads/road4.png',
    leftSprite: 'roads/left4.png',
    rightSprite: 'roads/right4.png',
    cost: 2999,
  ),
  RoadModel(
    id: 5,
    name: 'Park',
    centerSprite: 'roads/road5.png',
    leftSprite: 'roads/left5.png',
    rightSprite: 'roads/right5.png',
    cost: 1499,
  ),
  RoadModel(
    id: 6,
    name: 'High Way',
    centerSprite: 'roads/road6.png',
    leftSprite: 'roads/left6.png',
    rightSprite: 'roads/right6.png',
    cost: 799,
  ),
  // Add more roads here...
];

RoadModel getRoadById(int id) {
  return allRoads.firstWhere((r) => r.id == id, orElse: () => allRoads[0]);
}

RoadModel getRoadByFile(String fileName) {
  return allRoads.firstWhere(
    (r) => r.centerSprite == fileName,
    orElse: () => allRoads[0],
  );
}
