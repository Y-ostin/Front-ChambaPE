import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import 'dart:async';

class OffersProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _offers = [];
  Timer? _pollingTimer;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get offers => _offers;

  Future<void> fetchWorkerOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.get('/offers/my-offers');
    if (response['success'] == true) {
      _offers = List<Map<String, dynamic>>.from(response['data']);
    } else {
      _error = response['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> acceptOffer(int offerId) async {
    final res = await ApiService.post('/offers/$offerId/accept', {});
    if (res['success'] == true) {
      await fetchWorkerOffers();
      return true;
    }
    _error = res['message'];
    notifyListeners();
    return false;
  }

  Future<bool> rejectOffer(int offerId, {String? reason}) async {
    final res = await ApiService.post('/offers/$offerId/reject', {
      'reason': reason ?? 'No disponible',
    });
    if (res['success'] == true) {
      await fetchWorkerOffers();
      return true;
    }
    _error = res['message'];
    notifyListeners();
    return false;
  }

  void startPolling({Duration interval = const Duration(seconds: 15)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => fetchWorkerOffers());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
