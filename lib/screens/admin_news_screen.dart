import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/admin_news_service.dart';

/// Admin news management: create, edit, publish/unpublish, feature and
/// delete articles. Authorization is enforced by Supabase RLS (`is_admin()`),
/// not by this screen.
class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  List<Map<String, dynamic>>? _items;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _error = '');
    try {
      final List<Map<String, dynamic>> items =
          await AdminNewsService.instance.fetchAll();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _items = <Map<String, dynamic>>[];
        _error = error.toString();
      });
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? existing]) async {
    final bool? changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewsEditor(existing: existing),
    );
    if (changed == true) await _reload();
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('حذف خبر'),
        content: Text('«${item['title_fa']}» برای همیشه حذف شود؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await AdminNewsService.instance.delete(item['id'].toString());
      await _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حذف ناموفق بود: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت اخبار'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reload,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('خبر جدید'),
        ),
        body: _buildBody(context),
      );

  Widget _buildBody(BuildContext context) {
    final List<Map<String, dynamic>>? items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return const Center(child: Text('هیچ خبری یافت نشد.'));
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final Map<String, dynamic> item = items[index];
          final String status = item['status'].toString();
          final bool published = status == 'published';
          final bool featured = item['featured'] == true;
          return Card(
            child: ListTile(
              title: Text(
                (item['title_fa'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'دسته: ${item['category_id']} • $status'
                '${featured ? ' • ویژه' : ''}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (String value) async {
                  switch (value) {
                    case 'edit':
                      await _openEditor(item);
                      break;
                    case 'toggle':
                      await AdminNewsService.instance
                          .setPublished(item['id'].toString(), !published);
                      await _reload();
                      break;
                    case 'feature':
                      await AdminNewsService.instance
                          .setFeatured(item['id'].toString(), !featured);
                      await _reload();
                      break;
                    case 'delete':
                      await _confirmDelete(item);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                      value: 'edit', child: Text('ویرایش')),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: Text(published ? 'لغو انتشار' : 'انتشار'),
                  ),
                  PopupMenuItem<String>(
                    value: 'feature',
                    child: Text(featured ? 'حذف از ویژه' : 'ویژه کردن'),
                  ),
                  const PopupMenuItem<String>(
                      value: 'delete', child: Text('حذف')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewsEditor extends StatefulWidget {
  const _NewsEditor({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_NewsEditor> createState() => _NewsEditorState();
}

class _NewsEditorState extends State<_NewsEditor> {
  late final TextEditingController _titleFa;
  late final TextEditingController _titleEn;
  late final TextEditingController _summaryFa;
  late final TextEditingController _summaryEn;
  late final TextEditingController _contentFa;
  late final TextEditingController _contentEn;
  late final TextEditingController _category;
  late bool _featured;
  String _imageUrl = '';
  String _error = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic>? e = widget.existing;
    _titleFa = TextEditingController(text: _s(e?['title_fa']));
    _titleEn = TextEditingController(text: _s(e?['title_en']));
    _summaryFa = TextEditingController(text: _s(e?['summary_fa']));
    _summaryEn = TextEditingController(text: _s(e?['summary_en']));
    _contentFa = TextEditingController(text: _paragraphs(e?['content_fa']));
    _contentEn = TextEditingController(text: _paragraphs(e?['content_en']));
    _category = TextEditingController(
        text: _s(e?['category_id']).isEmpty ? 'general' : _s(e?['category_id']));
    _featured = e?['featured'] == true;
    _imageUrl = _s(e?['image_url']);
  }

  static String _s(Object? value) => (value ?? '').toString();

  static String _paragraphs(Object? value) {
    if (value is List) return value.join('\n\n');
    return _s(value);
  }

  Future<void> _pickImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    final PlatformFile file = result.files.single;
    setState(() => _saving = true);
    try {
      final String url = await AdminNewsService.instance.uploadImage(
        file.name,
        file.bytes ?? Uint8List(0),
        file.extension == 'png' ? 'image/png' : 'image/jpeg',
      );
      setState(() => _imageUrl = url);
    } catch (error) {
      setState(() => _error = 'بارگذاری تصویر ناموفق بود: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_titleFa.text.trim().isEmpty || _summaryFa.text.trim().isEmpty) {
      setState(() => _error = 'عنوان فارسی و خلاصه فارسی الزامی است.');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final AdminNewsService service = AdminNewsService.instance;
      final Map<String, dynamic>? existing = widget.existing;
      if (existing == null) {
        await service.create(
          titleFa: _titleFa.text.trim(),
          titleEn: _titleEn.text.trim(),
          summaryFa: _summaryFa.text.trim(),
          summaryEn: _summaryEn.text.trim(),
          contentFa: _contentFa.text.trim(),
          contentEn: _contentEn.text.trim(),
          categoryId: _category.text.trim(),
          imageUrl: _imageUrl,
          featured: _featured,
          publish: true,
        );
      } else {
        await service.update(
          existing['id'].toString(),
          titleFa: _titleFa.text.trim(),
          titleEn: _titleEn.text.trim(),
          summaryFa: _summaryFa.text.trim(),
          summaryEn: _summaryEn.text.trim(),
          contentFa: _contentFa.text.trim(),
          contentEn: _contentEn.text.trim(),
          categoryId: _category.text.trim(),
          imageUrl: _imageUrl,
          featured: _featured,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleFa.dispose();
    _titleEn.dispose();
    _summaryFa.dispose();
    _summaryEn.dispose();
    _contentFa.dispose();
    _contentEn.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'خبر جدید' : 'ویرایش خبر',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _titleFa,
                decoration: const InputDecoration(labelText: 'عنوان فارسی *')),
            const SizedBox(height: 10),
            TextField(
                controller: _titleEn,
                decoration: const InputDecoration(labelText: 'English title')),
            const SizedBox(height: 10),
            TextField(
                controller: _summaryFa,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'خلاصه فارسی *')),
            const SizedBox(height: 10),
            TextField(
                controller: _summaryEn,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'English summary')),
            const SizedBox(height: 10),
            TextField(
                controller: _contentFa,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'متن خبر (فارسی) - پاراگراف‌ها را با خط خالی جدا کنید')),
            const SizedBox(height: 10),
            TextField(
                controller: _contentEn,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'English content (blank line between paragraphs)')),
            const SizedBox(height: 10),
            TextField(
                controller: _category,
                decoration: const InputDecoration(
                    labelText: 'دسته (مثلاً general، siv، ir_f1_f2)')),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _imageUrl.isEmpty ? 'تصویری انتخاب نشده' : 'تصویر آپلود شد ✓',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _pickImage,
                  icon: const Icon(Icons.image_rounded),
                  label: const Text('تصویر'),
                ),
              ],
            ),
            SwitchListTile(
              value: _featured,
              onChanged: _saving
                  ? null
                  : (bool value) => setState(() => _featured = value),
              title: const Text('خبر ویژه (Featured)'),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: const Text('ذخیره و انتشار'),
            ),
          ],
        ),
      );
}
