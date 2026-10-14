class WasteCollectionRoute {
  const WasteCollectionRoute({
    required this.id,
    required this.routeName,
    required this.driverName,
    required this.zonesDone,
    required this.zonesTotal,
    required this.status,
  });

  final String id;
  final String routeName;
  final String driverName;
  final int zonesDone;
  final int zonesTotal;
  final String status;

  bool get isCompleted => status.toLowerCase() == 'completed';

  String label() => '$zonesDone of $zonesTotal zones serviced';
}
