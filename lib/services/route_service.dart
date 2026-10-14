import '../models/route_report.dart';

class RouteService {
  /// Task 1: an async function that returns a Future.
  /// Simulates a slow network call (3 seconds), then returns real data.
  static Future<List<RouteReport>> fetchRouteReports({bool fail = false}) async {
    await Future.delayed(const Duration(seconds: 3)); // the slow operation

    if (fail) {
      throw Exception('Server unreachable. Please try again.');
    }

    return const [
      RouteReport(
        routeName: 'Route R-07',
        zone: 'Malviya Nagar',
        status: 'Completed',
        zonesDone: 5,
        zonesTotal: 5,
      ),
      RouteReport(
        routeName: 'Route R-11',
        zone: 'Vaishali Nagar',
        status: 'Delayed',
        zonesDone: 3,
        zonesTotal: 6,
      ),
      RouteReport(
        routeName: 'Route R-14',
        zone: 'Mansarovar',
        status: 'Missed',
        zonesDone: 0,
        zonesTotal: 4,
      ),
    ];
  }
}