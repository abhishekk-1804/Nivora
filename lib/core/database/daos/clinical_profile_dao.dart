import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/schema_tables.dart';

part 'clinical_profile_dao.g.dart';

@DriftAccessor(tables: [ClinicalProfile])
class ClinicalProfileDao extends DatabaseAccessor<AppDatabase> with _$ClinicalProfileDaoMixin {
  ClinicalProfileDao(super.db);

  Future<ClinicalProfileData?> getProfile() => select(clinicalProfile).getSingleOrNull();

  Future<void> saveProfile(String? phenotype, bool hasPCOM) async {
    final existing = await getProfile();
    if (existing != null) {
      await update(clinicalProfile).replace(
        existing.copyWith(phenotype: Value(phenotype), hasPCOM: hasPCOM),
      );
    } else {
      await into(clinicalProfile).insert(
        ClinicalProfileCompanion.insert(
          phenotype: Value(phenotype),
          hasPCOM: Value(hasPCOM),
        ),
      );
    }
  }
}
