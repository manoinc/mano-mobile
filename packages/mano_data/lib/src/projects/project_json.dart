import 'package:mano_domain/mano_domain.dart';

// Selections and JSON mapping shared by the two projects gateway adapters.

const projectFields =
    'id category title description photos estimatedBudget { amount } '
    'status createdAt';

const quoteFields =
    'id worker { id displayName photoUrl } amount { amount } message status '
    'leadPurchased createdAt';

/// A project as its owner reads it, quotes included.
const ownedProjectFields =
    '$projectFields quotes(page: {first: 50}) { items { $quoteFields } }';

/// A quote read on its own by its worker, naming its project.
const standaloneQuoteFields =
    '$quoteFields clientContact { phone email } project { id title category }';

Iterable<Map<String, dynamic>> pageItems(Object? page) =>
    ((page as Map<String, dynamic>)['items'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

Project projectFromJson(Map<String, dynamic> json) {
  final id = json['id'] as String;
  final title = json['title'] as String;
  final quotes = json['quotes'];
  return Project(
    id: id,
    category: ServiceCategories.normalize(json['category'] as String),
    title: title,
    description: json['description'] as String,
    photoUrls: (json['photos'] as List<dynamic>).cast<String>(),
    budgetCop: _pesos(json['estimatedBudget']),
    status: switch (json['status']) {
      'AWARDED' => ProjectStatus.awarded,
      'CLOSED' => ProjectStatus.closed,
      'CANCELLED' => ProjectStatus.cancelled,
      _ => ProjectStatus.open,
    },
    createdAt: DateTime.parse(json['createdAt'] as String),
    quotes: quotes == null
        ? null
        : [
            for (final q in pageItems(quotes))
              quoteFromJson(q, projectId: id, projectTitle: title),
          ],
  );
}

/// [projectId] and [projectTitle] come from the parent when the quote is nested.
Quote quoteFromJson(
  Map<String, dynamic> json, {
  String? projectId,
  String? projectTitle,
}) {
  final project = json['project'] as Map<String, dynamic>?;
  final worker = json['worker'] as Map<String, dynamic>;
  return Quote(
    id: json['id'] as String,
    projectId: projectId ?? project!['id'] as String,
    projectTitle: projectTitle ?? project!['title'] as String,
    worker: Party(
      id: worker['id'] as String,
      displayName: worker['displayName'] as String,
      photoUrl: worker['photoUrl'] as String? ?? '',
    ),
    amountCop: _pesos(json['amount'])!,
    message: json['message'] as String?,
    status: switch (json['status']) {
      'SELECTED' => QuoteStatus.selected,
      'DISCARDED' => QuoteStatus.discarded,
      _ => QuoteStatus.submitted,
    },
    createdAt: DateTime.parse(json['createdAt'] as String),
    leadPurchased: json['leadPurchased'] as bool? ?? false,
    projectCategory: switch (project?['category']) {
      final String category => ServiceCategories.normalize(category),
      _ => '',
    },
    clientContact: switch (json['clientContact']) {
      final Map<String, dynamic> contact => ContactInfo(
        phone: contact['phone'] as String?,
        email: contact['email'] as String?,
      ),
      _ => null,
    },
  );
}

// Money.amount is a JSON number; the app counts whole pesos.
int? _pesos(Object? money) => money == null
    ? null
    : ((money as Map<String, dynamic>)['amount'] as num).round();
