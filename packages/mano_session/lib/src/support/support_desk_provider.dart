import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mano_data/mano_data.dart';
import 'package:mano_domain/mano_domain.dart';

// Mock: createSupportTicket is a gateway stub.
final supportDeskProvider = Provider<SupportDesk>((ref) => MockSupportDesk());
