class RouteReport {
  final String routeName;
  final String zone;
  final String status; // Completed, Delayed, Missed
  final int zonesDone;
  final int zonesTotal;

  const RouteReport({
    required this.routeName,
    required this.zone,
    required this.status,
    required this.zonesDone,
    required this.zonesTotal,
  });
}