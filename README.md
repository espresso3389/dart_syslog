# dart_syslog

A syslog protocol ([RFC 3164](https://datatracker.ietf.org/doc/html/rfc3164)/[RFC 5424](https://datatracker.ietf.org/doc/html/rfc5424)) implementation that only supports [UDP transport](https://datatracker.ietf.org/doc/html/rfc3164#section-2).

## Features

- [RFC 3164](https://datatracker.ietf.org/doc/html/rfc3164)/[RFC 5424](https://datatracker.ietf.org/doc/html/rfc5424)
- UDP transport only

## Usage

The following sample illustrates a program that sends syslog message to the server that runs on `192.168.10.222:5140`:

```dart
import 'dart:io';

import 'package:syslog/syslog.dart';

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
```
