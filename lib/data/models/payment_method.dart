/// How the customer says they will pay. Nothing is charged by the app or the API.
enum PaymentMethod {
  cashOnService('cash_on_service', 'Cash on service'),
  demoWallet('demo_wallet', 'Demo wallet');

  const PaymentMethod(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PaymentMethod fromApi(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.apiValue == value,
      orElse: () => PaymentMethod.cashOnService,
    );
  }
}
