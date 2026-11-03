/// chatservice refuses empty content, so a photo sent without text carries this.
const photoOnlyCaption = '📷 Foto';

/// What goes to the backend as the message body.
String outgoingBody(String text, {required bool hasPhotos}) =>
    text.isEmpty && hasPhotos ? photoOnlyCaption : text;

/// What the bubble shows under its photos; empty when only the default caption.
String visibleCaption(String body, {required bool hasPhotos}) =>
    hasPhotos && body == photoOnlyCaption ? '' : body;
