import 'package:flutter_riverpod/flutter_riverpod.dart';

final createJobSelectedCategoryProvider = StateProvider.autoDispose<String>(
  (ref) => 'Plumbing',
);
