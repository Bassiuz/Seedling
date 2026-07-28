import 'dart:convert';

/// A Firestore document id for a calendar event.
///
/// EventKit ids cannot be used directly. A real one looks like:
///
///     ______NativeStorePersistentID_______:gregorian/2DFB19BE-B573-…
///
/// which breaks two Firestore rules at once: the slash is read as a path
/// separator (the crash this exists to prevent), and an id matching `__…__` is
/// reserved. Encoding sidesteps both without having to guess at every id
/// format EventKit and the Android provider might produce.
///
/// The real id is stored in the document body, so nothing depends on being
/// able to read this one.
String mirrorDocId(String eventId) =>
    // Prefixed so the result can never itself match the reserved `__…__` shape.
    'e${base64Url.encode(utf8.encode(eventId)).replaceAll('=', '')}';
