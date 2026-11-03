import 'dart:convert';

import 'package:flutter/painting.dart';

/// A 1x1 PNG, so image widgets decode without the network.
final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

final tinyImage = MemoryImage(tinyPng);
