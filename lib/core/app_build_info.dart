/// Identificador de compilación (--dart-define=DTFLY_BUILD=... en el script de deploy).
class AppBuildInfo {
  AppBuildInfo._();

  static const String build = String.fromEnvironment(
    'DTFLY_BUILD',
    defaultValue: 'dev',
  );

  static const String adminUiVersion = 'admin-v4';
}
