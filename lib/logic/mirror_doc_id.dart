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

/// The mirror's key for one *occurrence* of an event.
///
/// EventKit hands every occurrence of a repeating event the same
/// `eventIdentifier`, so keying the mirror on the id alone kept exactly one
/// Tuesday of a weekly standup and dropped the rest — which looked, on the
/// Mac, like the meeting simply not existing. The day and the clock make each
/// occurrence its own document.
String mirrorOccurrenceId(String eventId, String dayKey, String? time) =>
    mirrorDocId('$eventId@$dayKey${time == null ? '' : 'T$time'}');
