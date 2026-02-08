import 'package:equatable/equatable.dart';

abstract class BackupSettingsState extends Equatable {
  const BackupSettingsState();

  @override
  List<Object?> get props => [];
}

class BackupSettingsInitial extends BackupSettingsState {}

class BackupSettingsLoaded extends BackupSettingsState {
  final bool isSignedIn;
  final String? lastBackupTime;
  final bool autoBackupEnabled;
  final bool isLoading;
  final String? message;

  const BackupSettingsLoaded({
    this.isSignedIn = false,
    this.lastBackupTime,
    this.autoBackupEnabled = false,
    this.isLoading = false,
    this.message,
  });

  BackupSettingsLoaded copyWith({
    bool? isSignedIn,
    String? lastBackupTime,
    bool? autoBackupEnabled,
    bool? isLoading,
    String? message,
  }) {
    return BackupSettingsLoaded(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }

  @override
  List<Object?> get props => [isSignedIn, lastBackupTime, autoBackupEnabled, isLoading, message];
}
