import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_fee.dart';
import '../models/payment.dart';
import '../models/payment_detail.dart';
import '../models/student_arrears.dart';
import '../services/auth_interceptor.dart';

class PaymentProvider extends StateNotifier<AsyncValue<StudentFee?>> {
  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));
  
  PaymentProvider() : super(const AsyncValue.data(null)){
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<void> fetchStudentAvailableFees(String studentId) async {
    try {
      state = const AsyncValue.loading();
      await _setAuthHeader();
      
      final response = await _dio.get("/Payment/student/$studentId/available-fees");
      
      if (response.statusCode == 200) {
        final studentFee = StudentFee.fromJson(response.data);
        state = AsyncValue.data(studentFee);
      } else if (response.statusCode == 404) {
        state = const AsyncValue.data(null);
        print("No available fees found for student (404)");
      } else {
        state = AsyncValue.error("Failed to fetch student fees", StackTrace.current);
      }
    } catch (e, stackTrace) {
      if (e is DioException && e.response?.statusCode == 404) {
        state = const AsyncValue.data(null);
        print("No available fees found for student (404)");
      } else {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<bool> processPayment(Payment payment) async {
    try {
      await _setAuthHeader();

      final response = await _dio.post("/Payment", data: payment.toJson());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh the student fees after successful payment
        await fetchStudentAvailableFees(payment.studentId);
        return true;
      }
      return false;
    } catch (e) {
      print("Error processing payment: $e");
      return false;
    }
  }

  void clearStudentFees() {
    state = const AsyncValue.data(null);
  }
}

final paymentProvider = StateNotifierProvider<PaymentProvider, AsyncValue<StudentFee?>>((ref) {
  return PaymentProvider();
});

// Provider for payment methods
final paymentMethodsProvider = Provider<List<String>>((ref) {
  return [
    'Cash',
    'Mobile Money',
    'Bank Transfer',
    'Cheque',
    'Card Payment',
  ];
});

// Payment detail notifier
class PaymentDetailNotifier extends StateNotifier<AsyncValue<PaymentDetail?>> {
  PaymentDetailNotifier(this._dio, this._getAuth) : super(const AsyncValue.data(null));
  final Dio _dio;
  final Future<void> Function() _getAuth;

  Future<void> fetchPaymentDetail(String paymentId) async {
    try {
      state = const AsyncValue.loading();
      await _getAuth();
      final res = await _dio.get("/Payment/$paymentId");
      if (res.statusCode == 200) {
        state = AsyncValue.data(PaymentDetail.fromJson(res.data));
      } else if (res.statusCode == 404) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error("Failed to load payment details", StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

// Student arrears notifier
class StudentArrearsNotifier extends StateNotifier<AsyncValue<StudentArrears?>> {
  StudentArrearsNotifier(this._dio, this._getAuth) : super(const AsyncValue.loading());
  final Dio _dio;
  final Future<void> Function() _getAuth;

  Future<void> fetchArrears(String studentId) async {
    try {
      state = const AsyncValue.loading();
      await _getAuth();
      final res = await _dio.get("/Payment/student/$studentId/arrears");
      if (res.statusCode == 200) {
        state = AsyncValue.data(StudentArrears.fromJson(res.data));
      } else if (res.statusCode == 404) {
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error("Failed to load arrears", StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

// Updated student payments notifier with CLIENT-SIDE filtering
class StudentPaymentsNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  StudentPaymentsNotifier(this._dio, this._getAuth) : super(const AsyncValue.loading());
  final Dio _dio;
  final Future<void> Function() _getAuth;
  
  List<Payment> _allPayments = []; // Store all payments for filtering

  Future<void> fetchPaymentsForStudent(String studentId, {
    String? term,
    int? year,
    String? paymentMethod,
    String? status,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _getAuth();
      
      // Only send studentId to the backend (since that's all it supports)
      final queryParams = <String, dynamic>{'studentId': studentId};
      
      
      
      final res = await _dio.get("/Payment", queryParameters: queryParams);
      
      if (res.statusCode == 200) {
        // Get all payments from backend
        _allPayments = (res.data as List).map((e) => Payment.fromJson(e)).toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        
        
        // Apply client-side filtering
        final filteredPayments = _applyClientSideFilters(
          _allPayments,
          term: term,
          year: year,
          paymentMethod: paymentMethod,
          status: status,
        );
        
        state = AsyncValue.data(filteredPayments);
      } else if (res.statusCode == 404) {
        _allPayments = [];
        state = const AsyncValue.data([]);
      } else {
        state = AsyncValue.error("Failed to load payment history", StackTrace.current);
      }
    } catch (e, st) {
      print('Error fetching payments: $e');
      state = AsyncValue.error(e, st);
    }
  }

  // Client-side filtering method
  List<Payment> _applyClientSideFilters(
    List<Payment> payments, {
    String? term,
    int? year,
    String? paymentMethod,
    String? status,
  }) {
    List<Payment> filtered = List.from(payments);
    
    // Filter by term
    if (term != null && term != 'All' && term.isNotEmpty) {
      filtered = filtered.where((payment) {
        return payment.terms?.any((t) => t.toLowerCase().contains(term.toLowerCase())) ?? false;
      }).toList();
    }
    
    // Filter by year
    if (year != null && year > 0) {
      filtered = filtered.where((payment) {
        return payment.paymentDate.year == year;
      }).toList();
    }
    
    // Filter by payment method
    if (paymentMethod != null && paymentMethod != 'All' && paymentMethod.isNotEmpty) {
      filtered = filtered.where((payment) {
        return payment.paymentMethod.toLowerCase().contains(paymentMethod.toLowerCase());
      }).toList();
    }
    
    // Filter by status
    if (status != null && status != 'All' && status.isNotEmpty) {
      filtered = filtered.where((payment) {
        return payment.status?.toLowerCase() == status.toLowerCase();
      }).toList();
    }
    
    return filtered;
  }

  // Method to apply filters without refetching from backend
  void applyFilters({
    String? term,
    int? year,
    String? paymentMethod,
    String? status,
  }) {
    if (_allPayments.isEmpty) return;
    
    final filteredPayments = _applyClientSideFilters(
      _allPayments,
      term: term,
      year: year,
      paymentMethod: paymentMethod,
      status: status,
    );
    
    state = AsyncValue.data(filteredPayments);
  }

  void clear() {
    _allPayments = [];
    state = const AsyncValue.data([]);
  }
}

// Family providers
final studentArrearsProvider = StateNotifierProvider.family<StudentArrearsNotifier, AsyncValue<StudentArrears?>, String>((ref, studentId) {
  final base = ref.read(paymentProvider.notifier);
  return StudentArrearsNotifier(base._dio, base._setAuthHeader)..fetchArrears(studentId);
});

final studentPreviousPaymentsProvider = StateNotifierProvider.family<StudentPaymentsNotifier, AsyncValue<List<Payment>>, String>((ref, studentId) {
  final base = ref.read(paymentProvider.notifier);
  return StudentPaymentsNotifier(base._dio, base._setAuthHeader)..fetchPaymentsForStudent(studentId);
});

final paymentDetailProvider = StateNotifierProvider.family<PaymentDetailNotifier, AsyncValue<PaymentDetail?>, String>((ref, paymentId) {
  final base = ref.read(paymentProvider.notifier);
  return PaymentDetailNotifier(base._dio, base._setAuthHeader)..fetchPaymentDetail(paymentId);
});

// Add this new provider for fetching ALL payments (not student-specific)
class AllPaymentsNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  AllPaymentsNotifier(this._dio, this._getAuth) : super(const AsyncValue.loading());
  final Dio _dio;
  final Future<void> Function() _getAuth;

  Future<void> fetchAllPayments() async {
    try {
      state = const AsyncValue.loading();
      await _getAuth();
      
      // Fetch ALL payments from backend (no studentId filter)
      final res = await _dio.get("/Payment");
      
      if (res.statusCode == 200) {
        final payments = (res.data as List)
            .map((e) => Payment.fromJson(e))
            .toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        
        print('✅ Fetched ${payments.length} total payments from backend');
        state = AsyncValue.data(payments);
      } else if (res.statusCode == 404) {
        state = const AsyncValue.data([]);
      } else {
        state = AsyncValue.error("Failed to load all payments", StackTrace.current);
      }
    } catch (e, st) {
      print('❌ Error fetching all payments: $e');
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
}

// Provider for all payments (not student-specific)
final allPaymentsProvider = StateNotifierProvider<AllPaymentsNotifier, AsyncValue<List<Payment>>>((ref) {
  final base = ref.read(paymentProvider.notifier);
  return AllPaymentsNotifier(base._dio, base._setAuthHeader);
});