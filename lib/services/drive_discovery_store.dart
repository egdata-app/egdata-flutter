import '../database/database_service.dart';

abstract class DriveDiscoveryStore {
  Future<List<InstalledGameEntry>> loadInstalledEntries();
  Future<void> saveInstalledEntries(List<InstalledGameEntry> entries);
  Future<void> addActivity(ActivityEventEntry entry);
}

class DatabaseDriveDiscoveryStore implements DriveDiscoveryStore {
  final DatabaseService database;

  const DatabaseDriveDiscoveryStore(this.database);

  @override
  Future<List<InstalledGameEntry>> loadInstalledEntries() =>
      database.getAllInstalledGameEntries();

  @override
  Future<void> saveInstalledEntries(List<InstalledGameEntry> entries) =>
      database.saveInstalledGameEntries(entries);

  @override
  Future<void> addActivity(ActivityEventEntry entry) =>
      database.addActivityEvent(entry);
}
