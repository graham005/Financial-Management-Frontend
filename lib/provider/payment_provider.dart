import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_fee.dart';
import '../models/payment.dart';
import '../models/student_arrears.dart';

class PaymentProvider extends StateNotifier<AsyncValue<StudentFee?>> {
  PaymentProvider() : super(const AsyncValue.data(null));

  final Dio _dio = Dio(BaseOptions(baseUrl: dotenv.env['API_BASE_URL'] ?? ''));

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

// Updated student payments notifier to use backend filtering
class StudentPaymentsNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  StudentPaymentsNotifier(this._dio, this._getAuth) : super(const AsyncValue.loading());
  final Dio _dio;
  final Future<void> Function() _getAuth;

  Future<void> fetchPaymentsForStudent(String studentId) async {
    try {
      state = const AsyncValue.loading();
      await _getAuth();
      
      // Use backend filtering with studentId query parameter
      final res = await _dio.get("/Payment", queryParameters: {
        'studentId': studentId,
      });
      
      if (res.statusCode == 200) {
        final payments = (res.data as List).map((e) => Payment.fromJson(e)).toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate)); // Sort by date descending
        state = AsyncValue.data(payments);
      } else if (res.statusCode == 404) {
        state = const AsyncValue.data([]);
      } else {
        state = AsyncValue.error("Failed to load payment history", StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data([]);
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