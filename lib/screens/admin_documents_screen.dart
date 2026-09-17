import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/admin_document_service.dart';

/// Shown only to users listed in public.admin_users. The database remains the
/// authority: it enforces the same administrator check for storage and rows.
class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  final TextEditingController _titleFa = TextEditingController();
  final TextEditingController _titleEn = TextEditingController();
  final TextEditingController _descriptionFa = TextEditingController();
  final TextEditingController _descriptionEn = TextEditingController();
  PlatformFile? _file;
  String _error = '';
  bool _requiresLogin = true;
  bool _saving = false;

  @override
  void dispose() {
    _titleFa.dispose();
    _titleEn.dispose();
    _descriptionFa.dispose();
    _descriptionEn.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AdminDocumentService.allowedExtensions.toList(),
      withData: true,
    );
    if (result == null) return;
    final PlatformFile selected = result.files.single;
    setState(() {
      _file = selected;
      _error = AdminDocumentService.instance.validate(selected) ?? '';
    });
  }

  Future<void> _upload() async {
    final String? validation = AdminDocumentService.instance.validate(_file);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    if (_titleFa.text.trim().isEmpty || _titleEn.text.trim().isEmpty) {
      setState(() => _error = 'عنوان فارسی و انگلیسی را وارد کنید.');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      await AdminDocumentService.instance.uploadAndPublish(
        file: _file!,
        titleFa: _titleFa.text.trim(),
        titleEn: _titleEn.text.trim(),
        descriptionFa: _descriptionFa.text.trim(),
        descriptionEn: _descriptionEn.text.trim(),
        requiresLogin: _requiresLogin,
      );
      if (!mounted) return;
      setState(() => _file = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فایل بارگذاری و منتشر شد.')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مدیریت اسناد')),
        body: ListView(padding: const EdgeInsets.all(16), children: <Widget>[
          const Text(
              'فایل مجاز: PDF، Word، Excel، PowerPoint، TXT، CSV یا ZIP. حداکثر 25 مگابایت.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: _saving ? null : _chooseFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: const Text('انتخاب فایل')),
          if (_file != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    'فایل انتخاب‌شده: ${_file!.name} (${(_file!.size / 1024 / 1024).toStringAsFixed(2)} MB)')),
          if (_error.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 16),
          TextField(
              controller: _titleFa,
              decoration: const InputDecoration(labelText: 'عنوان فارسی')),
          const SizedBox(height: 10),
          TextField(
              controller: _titleEn,
              decoration: const InputDecoration(labelText: 'English title')),
          const SizedBox(height: 10),
          TextField(
              controller: _descriptionFa,
              decoration: const InputDecoration(labelText: 'توضیح فارسی'),
              maxLines: 2),
          const SizedBox(height: 10),
          TextField(
              controller: _descriptionEn,
              decoration:
                  const InputDecoration(labelText: 'English description'),
              maxLines: 2),
          SwitchListTile(
              value: _requiresLogin,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _requiresLogin = value),
              title: const Text('برای دانلود، ورود با Google لازم باشد')),
          const SizedBox(height: 8),
          FilledButton.icon(
              onPressed: _saving ? null : _upload,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded),
              label:
                  Text(_saving ? 'در حال بارگذاری...' : 'بارگذاری و انتشار')),
        ]),
      );
}
