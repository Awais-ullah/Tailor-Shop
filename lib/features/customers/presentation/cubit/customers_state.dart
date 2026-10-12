import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';

enum CustomersStatus { loading, loaded, failure }

class CustomersState extends Equatable {
  const CustomersState({
    this.status = CustomersStatus.loading,
    this.customers = const [],
    this.query = '',
    this.showArchived = false,
    this.errorMessage,
  });

  final CustomersStatus status;
  final List<Customer> customers;
  final String query;
  final bool showArchived;
  final String? errorMessage;

  /// What the list screen displays: filtered by archived flag and search.
  List<Customer> get visibleCustomers {
    final q = query.trim().toLowerCase();
    final queryDigits = q.replaceAll(RegExp(r'[^0-9]'), '');

    return customers.where((customer) {
      if (customer.isArchived != showArchived) return false;
      if (q.isEmpty) return true;

      final nameMatches = customer.nameLower.contains(q);
      final phoneMatches = queryDigits.isNotEmpty &&
          customer.phoneNormalized.contains(queryDigits);
      return nameMatches || phoneMatches;
    }).toList();
  }

  Customer? customerById(String id) {
    for (final customer in customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  CustomersState copyWith({
    CustomersStatus? status,
    List<Customer>? customers,
    String? query,
    bool? showArchived,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CustomersState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      query: query ?? this.query,
      showArchived: showArchived ?? this.showArchived,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, customers, query, showArchived, errorMessage];
}