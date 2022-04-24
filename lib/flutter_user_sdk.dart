library flutter_user_sdk;

import 'package:flutter_user_sdk/data/cache_repository.dart';
import 'package:flutter_user_sdk/data/repository.dart';
import 'package:flutter_user_sdk/data/requests_retry_service.dart';
import 'package:flutter_user_sdk/data/user_api_service.dart';
import 'package:flutter_user_sdk/models/events/custom_event.dart';
import 'package:flutter_user_sdk/models/events/predefined/device_information.dart';

class UserSDK {
  static UserSDK get instance => _getOrCreateInstance();
  static UserSDK? _instance;

  static UserSDK _getOrCreateInstance() {
    if (_instance != null) return _instance!;
    _instance = UserSDK();
    return _instance!;
  }

  late String _mobileSdkKey;

  late String _integrationsApiKey;

  late String _appDomain;

  late Repository _repository;

  late CacheRepository _cacheRepository;

  Future<void> initialize({
    required String mobileSdkKey,
    required String integrationsApiKey,
    required String appDomain,
  }) async {
    _mobileSdkKey = mobileSdkKey;
    _integrationsApiKey = integrationsApiKey;
    _appDomain = appDomain;

    _cacheRepository = CacheRepository();
    await _cacheRepository.initialize();
    _setupClient();
    RequestsRetryService(_cacheRepository).resendRequests();
  }

  Future<void> registerAnonymousUserSession({String? userKey}) async {
    await _repository.postUserDeviceInfo(
      userKey: userKey,
      deviceInfo: await DeviceInformation.getPlatformInformation(
            fcmToken: '',
          ) ??
          <String, dynamic>{},
    );
    _setupClient();
  }

  Future<void> sendCustomEvent({
    required String eventName,
    required Map<String, dynamic> data,
  }) async {
    await _repository.sendCustomEvent(
      CustomEvent(
        event: eventName,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
  }

  void _setupClient() {
    final service = UserApiService.create(
      cacheRepository: _cacheRepository,
      mobileSdkKey: _mobileSdkKey,
      integrationsApiKey: _integrationsApiKey,
      appDomain: _appDomain,
      userKey: _cacheRepository.getUserKey(),
    );

    _repository = Repository(
      service: service,
      cacheRepository: _cacheRepository,
    );
  }

  // void register(Customer customer) {}
}
