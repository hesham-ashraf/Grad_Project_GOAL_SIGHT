class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const bool enableMockFallback = true;

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String managerMatchesEndpoint = '/manager/matches';
  static const String adminUsersEndpoint = '/admin/users';
  static const String adminOverviewEndpoint = '/admin/overview';
}
