import '../../core/network/api_client.dart';
import '../models/service.dart';

class ServiceRepository {
  const ServiceRepository(this._api);

  final ApiClient _api;

  Future<List<Service>> fetchServices() async {
    final json = await _api.get('/services');
    return [
      for (final item in json['data'] as List)
        Service.fromJson(item as Map<String, dynamic>),
    ];
  }
}
