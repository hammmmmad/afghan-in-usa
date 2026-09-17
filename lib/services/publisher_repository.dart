import '../models/news_model.dart';
import 'supabase_service.dart';

/// Public publisher directory. Publisher/news writes are intentionally absent
/// from the mobile app and are performed through the Supabase dashboard or a
/// trusted server using the service-role key.
class PublisherRepository {
  const PublisherRepository();

  Future<List<Publisher>> fetchPublishers() async {
    if (!SupabaseService.isReady) return <Publisher>[];
    final List<dynamic> rows = await SupabaseService.client
        .from('publishers')
        .select(
            'id,display_name,avatar_url,bio_fa,bio_en,website_url,verified,is_active')
        .eq('is_active', true)
        .order('display_name');
    return rows
        .map((dynamic row) =>
            Publisher.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<Publisher?> fetchById(String id) async {
    if (!SupabaseService.isReady || id.isEmpty) return null;
    final Map<String, dynamic>? row = await SupabaseService.client
        .from('publishers')
        .select(
            'id,display_name,avatar_url,bio_fa,bio_en,website_url,verified,is_active')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Publisher.fromJson(row);
  }
}
