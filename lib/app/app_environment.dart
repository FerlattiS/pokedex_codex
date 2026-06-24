enum AppEnvironment {
  development,
  beta,
  production;

  static AppEnvironment get current {
    const value = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    return switch (value) {
      'production' => AppEnvironment.production,
      'beta' => AppEnvironment.beta,
      _ => AppEnvironment.development,
    };
  }

  String get label {
    return switch (this) {
      AppEnvironment.development => 'DEV',
      AppEnvironment.beta => 'BETA',
      AppEnvironment.production => '',
    };
  }

  String get displayName {
    return switch (this) {
      AppEnvironment.development => 'Desarrollo',
      AppEnvironment.beta => 'Beta publica',
      AppEnvironment.production => 'Produccion',
    };
  }
}

class AppBuildInfo {
  const AppBuildInfo._();

  static const version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'local',
  );
}
