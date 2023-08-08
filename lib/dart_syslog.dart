// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:synchronized/extension.dart';

/// Syslog tags.
class SyslogTags {
  /// Sender host name.
  final String? hostName;

  /// Sender application name.
  final String? appName;

  /// Sender process ID or such.
  final String? procId;
  SyslogTags({
    this.hostName,
    this.appName,
    this.procId,
  });
}

/// A syslog protocol ([RFC 3164](https://datatracker.ietf.org/doc/html/rfc3164)/[RFC 5424](https://datatracker.ietf.org/doc/html/rfc5424)) implementation
/// that only supports [UDP transport](https://datatracker.ietf.org/doc/html/rfc3164#section-2).
class SyslogUdpClient {
  /// syslog server address.
  final InternetAddress address;

  /// syslog server port (The default is 514).
  final int port;

  /// Tag values for messages.
  final SyslogTags? tags;

  /// Whether to use RFC-5424 or not. By default, it is false and uses [RFC 3164](https://datatracker.ietf.org/doc/html/rfc3164).
  final bool useRfc5424;

  /// Create a new syslog client. It should be closed by calling [close].
  SyslogUdpClient({
    required this.address,
    this.port = 514,
    this.tags,
    this.useRfc5424 = false,
  });

  RawDatagramSocket? _soc;

  /// Explicitly initialize the socket; normally you don't have to call it.
  Future<void> init() async {
    if (_soc != null) return;
    await synchronized(() async {
      if (_soc != null) return;
      _soc = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    });
  }

  /// Close the socket if opened.
  void close() {
    _soc?.close();
    _soc = null;
  }

  final _dateFormatForRfc3164 = DateFormat('MMM d HH:mm:ss', 'en_US');

  /// Send [message] with [severity] and [facility] or [facilityInt] (for custom facility) to the syslog server.
  /// [tags] can be used to override the values passed to [SyslogUdpClient] constructor.
  /// If [msgId] or [structuredData] are used, the message is sent using [RFC 5424](https://datatracker.ietf.org/doc/html/rfc5424).
  Future<void> send(Severity severity, String message,
      {Facility? facility,
      int? facilityInt,
      DateTime? timeStamp,
      SyslogTags? tags,
      String? msgId,
      String? structuredData}) async {
    facilityInt ??= facility?.index;
    assert(facilityInt != null);
    final priority = facilityInt! * 8 + severity.index;
    const version = 1;
    timeStamp ??= DateTime.now();
    timeStamp = timeStamp.toUtc();
    final hostName = tags?.hostName ?? this.tags?.hostName ?? '-';
    final appName = tags?.appName ?? this.tags?.appName ?? '-';
    final procId = tags?.procId ?? this.tags?.procId ?? '-';
    final hasMessageId = msgId != null;
    msgId ??= '-';
    final hasStructuredData = structuredData != null;
    structuredData = hasStructuredData ? '[$structuredData]' : '-';
    final useRfc5424 = this.useRfc5424 || hasMessageId || hasStructuredData;

    final m = useRfc5424
        ? '<$priority>$version ${timeStamp.toIso8601String()} $hostName $appName $procId $msgId $structuredData $message'
        : '<$priority>${_dateFormatForRfc3164.format(timeStamp)} $hostName $appName[$procId]: $message';

    await init();
    _soc!.send(utf8.encode(m), address, port);
  }
}

/// Syslog facility
enum Facility {
  kernel, // 0 kernel messages
  user, // 1 user-level messages
  mail, // 2 mail system
  system, // 3 system daemons
  security1, // 4 security/authorization messages
  syslogd, // 5 messages generated internally by syslogd
  printer, // 6 line printer subsystem
  news, // 7 network news subsystem
  uucp, // 8 UUCP subsystem
  clock, // 9 clock daemon
  security2, // 10 security/authorization messages
  ftp, // 11 FTP daemon
  ntp, // 12 NTP subsystem
  audit, // 13 log audit
  alert, // 14 log alert
  clock_, // 15 clock daemon (note 2)
  local0, // 16 local use 0  (local0)
  local1, // 17 local use 1  (local1)
  local2, // 18 local use 2  (local2)
  local3, // 19 local use 3  (local3)
  local4, // 20 local use 4  (local4)
  local5, // 21 local use 5  (local5)
  local6, // 22 local use 6  (local6)
  local7, // 23 local use 7  (local7)
}

/// Syslog severity
enum Severity {
  emergency, // 0 Emergency: system is unusable
  alert, // 1 Alert: action must be taken immediately
  critical, // 2 Critical: critical conditions
  error, // 3 Error: error conditions
  warning, // 4 Warning: warning conditions
  notice, // 5 Notice: normal but significant condition
  informational, // 6 Informational: informational messages
  debug, // 7 Debug: debug-level messages
}
