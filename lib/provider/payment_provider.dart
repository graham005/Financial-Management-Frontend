import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_fee.dart';
import '../models/payment.dart';

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