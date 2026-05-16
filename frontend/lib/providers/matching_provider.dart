import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class MatchingProvider with ChangeNotifier {
  final _api = ApiService();
  List<dynamic> nearbyWorkers = [];
  bool isLoading = false;
  String? error;

  Future<void> findNearbyWorkers(String skill, {double? lat, double? lon}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _api.matchWorkers(
        skill: skill,
        lat:   lat  ?? 24.8607,
        lon:   lon  ?? 67.0011,
      );
      nearbyWorkers = result['matching_workers'] ?? [];
    } catch (e) {
      error = e.toString();
      nearbyWorkers = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    nearbyWorkers = [];
    error = null;
    notifyListeners();
  }
}
