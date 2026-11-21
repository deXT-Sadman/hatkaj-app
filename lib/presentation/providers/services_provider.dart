import 'package:flutter/foundation.dart';

import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';
import 'view_state.dart';

class ServicesProvider extends ChangeNotifier {
  ServicesProvider(this._repository);

  final ServiceRepository _repository;

  ViewState _state = ViewState.loading;
  List<Service> _services = const [];
  String? _errorMessage;

  ViewState get state => _state;
  List<Service> get services => _services;
  String? get errorMessage => _errorMessage;

  Service? findById(int id) {
    for (final service in _services) {
      if (service.id == id) return service;
    }
    return null;
  }

  /// Loads services. Returns an error message if the request failed, otherwise null.
  ///
  /// Existing data stays on screen when a refresh fails; the full error state
  /// is only used when there is nothing to show.
  Future<String?> refresh() async {
    final hadData = _services.isNotEmpty;
    if (!hadData) {
      _state = ViewState.loading;
      notifyListeners();
    }

    try {
      _services = await _repository.fetchServices();
      _errorMessage = null;
      _state = _services.isEmpty ? ViewState.empty : ViewState.success;
      notifyListeners();
      return null;
    } catch (error) {
      final message = describeError(error);
      if (!hadData) {
        _errorMessage = message;
        _state = ViewState.error;
      }
      notifyListeners();
      return message;
    }
  }
}
