import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/features/bazar/contributions/data/contribution_mappers.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/fund/data/fund_mappers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// Translates contributions and ledger rows into staged batch writes.
///
/// A contribution is always written as the WHOLE document (`set`), so a
/// removed `pendingChange` really disappears; the author and creation time are
/// carried by the entity (`requestedBy`, `createdAt`), so no read is needed.
class ContributionWriteStager {
  const ContributionWriteStager();

  void contribution(
    BatchContext batch,
    String familyId,
    Contribution contribution,
    AuditEvent event,
  ) {
    batch.set(
      FirestorePaths.contributionDoc(familyId, contribution.id),
      ContributionMappers.toMap(
        contribution,
        BaseDocumentMetadata(
          createdAt: contribution.createdAt,
          createdBy: contribution.requestedBy,
          updatedAt: event.at,
          updatedBy: event.actorId,
        ),
      ),
    );
  }

  /// Appends ledger rows (null entries are skipped).  Rows are never updated.
  void fundRows(
    BatchContext batch,
    String familyId,
    List<FundTransaction?> rows,
    AuditEvent event,
  ) {
    for (final row in rows) {
      if (row == null) continue;
      batch.set(
        FirestorePaths.fundTransactionDoc(familyId, row.id),
        FundMappers.fundTxToMap(
          row,
          BaseDocumentMetadata(
            createdAt: row.createdAt,
            createdBy: row.createdBy,
            updatedAt: event.at,
            updatedBy: event.actorId,
          ),
        ),
      );
    }
  }
}
