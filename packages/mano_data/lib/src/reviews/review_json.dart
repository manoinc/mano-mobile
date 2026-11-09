import 'package:mano_domain/mano_domain.dart';

import '../gateway/gateway_json.dart';
import '../messaging/gateway_chat_json.dart';

const reviewFields =
    'id rating comment createdAt author { $participantFields }';

Review reviewFromJson(Map<String, dynamic> json) => Review(
  id: json['id'] as String,
  reviewer: toParty(json['author'] as Map<String, dynamic>),
  stars: json['rating'] as int,
  date: dateTimeFromJson(json['createdAt']),
  text: json['comment'] as String? ?? '',
);
