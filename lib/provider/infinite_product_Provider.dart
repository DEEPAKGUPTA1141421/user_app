import 'package:flutter_riverpod/flutter_riverpod.dart';

final InfiniteproductProvider =
    StateNotifierProvider<InfiniteProductNotifier, Map<String, dynamic>>((ref) {
  return InfiniteProductNotifier();
});

class InfiniteProductNotifier extends StateNotifier<Map<String, dynamic>> {
  InfiniteProductNotifier()
      : super({
          'isLoading': false,
          'success': false,
          'message': '',
          'products': [],
          'page': 1,
          'hasMore': true,
        });

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (state['isLoading'] == true) return;

    state = {...state, 'isLoading': true};

    try {
      await Future.delayed(const Duration(seconds: 2)); // simulate API call

      // Fake data generator
      final newProducts = List.generate(10, (index) {
        final id = ((state['page'] - 1) * 10) + index + 1;
        return {
          'id': id,
          'name': 'Product $id',
          'image':
              'https://via.placeholder.com/150?text=Product+$id', // mock image
          'price': 999 + id,
          'discountPrice': 799 + id,
        };
      });

      final currentProducts =
          List<Map<String, dynamic>>.from(state['products']);
      final updatedList =
          loadMore ? [...currentProducts, ...newProducts] : newProducts;

      final hasMore = newProducts.isNotEmpty;

      state = {
        ...state,
        'isLoading': false,
        'success': true,
        'products': updatedList,
        'page': loadMore ? state['page'] + 1 : 2,
        'hasMore': hasMore,
      };
    } catch (e) {
      state = {
        ...state,
        'isLoading': false,
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
