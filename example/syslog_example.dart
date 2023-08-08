import 'dart:io';

import 'package:dart_syslog/dart_syslog.dart';

void main() async {
  final syslog = SyslogUdpClient(
    address: InternetAddress.tryParse('192.168.10.222')!,
    port: 5140,
    tags: SyslogTags(
      hostName: 'myhost',
      appName: 'hello_syslog',
      procId: pid.toString(),
    ),
  );
  await syslog.send(facility: Facility.local0, Severity.debug, 'Hello, world!');
}
