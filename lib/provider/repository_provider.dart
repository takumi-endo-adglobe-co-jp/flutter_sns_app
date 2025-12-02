import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repository/post_repository.dart';
import '../repository/post_repository_impl.dart';
import 'supabase_client_provider.dart';

part 'repository_provider.g.dart';

/// Provider for PostRepository
@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  final apiClient = ref.watch(supabaseApiClientProvider);
  return PostRepositoryImpl(apiClient);
}
