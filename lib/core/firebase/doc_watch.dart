import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/firebase/doc_state.dart';

/// Listens to one document and classifies every snapshot as
/// [DocUnknown] / [DocAbsent] / [DocPresent] (see [DocState]).
Stream<DocState<Map<String, dynamic>>> watchDoc(
  DocumentReference<Map<String, dynamic>> ref,
) =>
    ref.snapshots(includeMetadataChanges: true).map(
          (s) => docStateOf(
            exists: s.exists,
            isFromCache: s.metadata.isFromCache,
            data: s.data(),
          ),
        );

/// Like [watchDoc] but silent while the state is [DocUnknown]: it emits the data
/// when the document is present and `null` only when the server confirmed it is
/// absent.  A consumer therefore stays in its loading state while offline with
/// nothing cached, instead of acting on a false "does not exist".
Stream<Map<String, dynamic>?> watchKnownDoc(
  DocumentReference<Map<String, dynamic>> ref,
) =>
    knownOnly(watchDoc(ref));

/// Drops [DocUnknown] states and unwraps the rest.  Split out for unit tests.
Stream<Map<String, dynamic>?> knownOnly(
  Stream<DocState<Map<String, dynamic>>> source,
) async* {
  await for (final state in source) {
    switch (state) {
      case DocUnknown<Map<String, dynamic>>():
        break;
      case DocAbsent<Map<String, dynamic>>():
        yield null;
      case DocPresent<Map<String, dynamic>>(:final value):
        yield value;
    }
  }
}
