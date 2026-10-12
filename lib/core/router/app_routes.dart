/// All route paths in one place, so we never mistype a path string.
class AppRoutes {
  AppRoutes._();

  // Auth (outside the main shell)
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Main app (inside the shell)
  static const String dashboard = '/dashboard';
  static const String customers = '/customers';
  static const String customerNew = '/customers/new';
  static String customerDetails(String id) => '/customers/$id';
  static String customerEdit(String id) => '/customers/$id/edit';
  static String customerMeasurementNew(String customerId, String garment) =>
      '/customers/$customerId/measurements/new?garment=$garment';
  static String customerMeasurementDetails(String customerId, String id) =>
      '/customers/$customerId/measurements/$id';
  static String customerMeasurementEdit(String customerId, String id) =>
      '/customers/$customerId/measurements/$id/edit';
  static String customerOrderNew(String customerId) =>
      '/customers/$customerId/orders/new';
  static String customerOrderDetails(String customerId, String id) =>
      '/customers/$customerId/orders/$id';
  static String customerOrderEdit(String customerId, String id) =>
      '/customers/$customerId/orders/$id/edit';
  static const String measurements = '/measurements';
  static String measurementNewFor(String customerId, String garment) =>
      '/measurements/new?customerId=$customerId&garment=$garment';
  static String measurementDetails(String id) => '/measurements/$id';
  static String measurementEdit(String id) => '/measurements/$id/edit';
  static const String orders = '/orders';
  static String orderNewFor(String customerId) =>
      '/orders/new?customerId=$customerId';
  static String orderDetails(String id) => '/orders/$id';
  static String orderEdit(String id) => '/orders/$id/edit';
  static const String ledger = '/ledger';
  static String ledgerCustomer(String customerId) => '/ledger/$customerId';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String more = '/more';

  /// Screens a logged-out user is allowed to see.
  static const List<String> authRoutes = [login, signup, forgotPassword];
}