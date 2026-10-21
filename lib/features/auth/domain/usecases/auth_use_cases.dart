/// Use cases of the auth feature.
///
/// One public use case per file (`lib/features/auth/domain/usecases/<name>.dart`),
/// matching the `SignIn` / `SignUp` naming from CLAUDE.md rule 1.3.10.
library;

export 'package:family_hub/features/auth/domain/usecases/change_password.dart';
export 'package:family_hub/features/auth/domain/usecases/reauthenticate_with_password.dart';
export 'package:family_hub/features/auth/domain/usecases/send_email_verification.dart';
export 'package:family_hub/features/auth/domain/usecases/send_password_reset.dart';
export 'package:family_hub/features/auth/domain/usecases/sign_in.dart';
export 'package:family_hub/features/auth/domain/usecases/sign_out.dart';
export 'package:family_hub/features/auth/domain/usecases/sign_up.dart';
