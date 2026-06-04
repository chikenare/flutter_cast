import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

import 'device.dart';

const _domain = '_googlecast._tcp';

class CastDiscoveryService {
  static final CastDiscoveryService _instance = CastDiscoveryService._();
  CastDiscoveryService._();

  factory CastDiscoveryService() {
    return _instance;
  }

  Future<List<CastDevice>> search(
      {Duration timeout = const Duration(seconds: 5)}) async {
    final results = <CastDevice>[];

    final discovery = BonsoirDiscovery(type: _domain);
    await discovery.initialize();

    discovery.eventStream!.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent():
          event.service.resolve(discovery.serviceResolver);

        case BonsoirDiscoveryServiceResolvedEvent():
          final port = event.service.port;
          final host = event.service.toJson()['service.ip'] ??
              event.service.toJson()['service.host'];

          String name = [
            event.service.attributes['md'],
            event.service.attributes['fn'],
          ].whereType<String>().join(' - ');
          if (name.isEmpty) {
            name = event.service.name;
          }

          if (host == null) {
            return;
          }

          results.add(
            CastDevice(
              serviceName: event.service.name,
              name: name,
              port: port,
              host: host,
              extras: event.service.attributes,
            ),
          );
          break;
        default:
          print('Another event occurred : $event.');
          break;
      }
    }, onError: (error) {
      print('[CastDiscoveryService] error ${error.runtimeType} - $error');
    });

    await discovery.start();
    await Future.delayed(timeout);
    await discovery.stop();

    return results.toSet().toList();
  }
}
