import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/promotion_service.dart';
import '../models/student_promotion.dart';

final promotionServiceProvider = Provider<PromotionService>((ref) {
  return PromotionService();
});

final promotionPreviewProvider = FutureProvider<PromotionPreview>((ref) async {
  final service = ref.watch(promotionServiceProvider);
  return service.getPromotionPreview();
});

class PromotionNotifier extends StateNotifier<AsyncValue<bool>> {
  final PromotionService _service;

  PromotionNotifier(this._service) : super(const AsyncValue.data(false));

  Future<bool> promoteStudents(List<String> studentIds) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _service.promoteStudents(studentIds);
      state = AsyncValue.data(success);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final promotionNotifierProvider = StateNotifierProvider<PromotionNotifier, AsyncValue<bool>>((ref) {
  final service = ref.watch(promotionServiceProvider);
  return PromotionNotifier(service);
});