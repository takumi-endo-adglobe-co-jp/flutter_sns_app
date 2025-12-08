import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../infrastructure/supabase_api_client.dart';

part 'supabase_client_provider.g.dart';

/// Provider for Supabase client instance
@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}

/// Provider for Supabase API client
@riverpod
SupabaseApiClient supabaseApiClient(SupabaseApiClientRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseApiClient(client);
}
