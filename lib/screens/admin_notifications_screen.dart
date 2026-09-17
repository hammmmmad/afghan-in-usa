import 'package:flutter/material.dart';

import '../models/case_model.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

/// Admin screen for the two notification kinds, kept strictly separate:
///
///  * Public notification  -> stored in `public_notifications`, visible to
///     every user of the app while `status = 'published'`.
///  * Case notification    -> delivered through the `notify_case_subscribers`
///     RPC only to users whose bell is enabled for the selected case.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final TextEditingController _publicTitleFa = TextEditingController();
  final TextEditingController _publicTitleEn = TextEditingController();
  final TextEditingController _publicBodyFa = TextEditingController();
  final TextEditingController _publicBodyEn = TextEditingController();

  final TextEditingController _caseTitleFa = TextEditingController();
  final TextEditingController _caseTitleEn = TextEditingController();
  final TextEditingController _caseBodyFa = TextEditingController();
  final TextEditingController _caseBodyEn = TextEditingController();

  List<CaseSummary>? _cases;
  CaseSummary? _selectedCase;
  String _publicError = '';
  String _caseError = '';
  bool _sendingPublic = false;
  bool _sendingCase = false;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      final List<CaseSummary> cases = await ApiService.instance.fetchCases();
      if (!mounted) return;
      setState(() {
        _cases = cases;
        _selectedCase = cases.isNotEmpty ? cases.first : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cases = <CaseSummary>[]);
    }
  }

  Future<void> _sendPublic() async {
    if (_publicTitleFa.text.trim().isEmpty ||
        _publicBodyFa.text.trim().isEmpty) {
      setState(() => _publicError = 'عنوان و متن فارسی الزامی است.');
      return;
    }
    setState(() {
      _sendingPublic = true;
      _publicError = '';
    });
    try {
      await SupabaseService.client.from('public_notifications').insert(
        <String, dynamic>{
          'title_i18n': <String, String>{
            'fa': _publicTitleFa.text.trim(),
            'en': _publicTitleEn.text.trim(),
          },
          'body_i18n': <String, String>{
            'fa': _publicBodyFa.text.trim(),
            'en': _publicBodyEn.text.trim(),
          },
          'data': <String, dynamic>{},
          'status': 'published',
          'published_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
      if (!mounted) return;
      _publicTitleFa.clear();
      _publicTitleEn.clear();
      _publicBodyFa.clear();
      _publicBodyEn.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اعلان عمومی برای همه کاربران منتشر شد.')),
      );
    } catch (error) {
      if (mounted) setState(() => _publicError = error.toString());
    } finally {
      if (mounted) setState(() => _sendingPublic = false);
    }
  }

  Future<void> _sendCase() async {
    final CaseSummary? selected = _selectedCase;
    if (selected == null) {
      setState(() => _caseError = 'یک پرونده انتخاب کنید.');
      return;
    }
    if (_caseTitleFa.text.trim().isEmpty || _caseBodyFa.text.trim().isEmpty) {
      setState(() => _caseError = 'عنوان و متن فارسی الزامی است.');
      return;
    }
    setState(() {
      _sendingCase = true;
      _caseError = '';
    });
    try {
      final Object? delivered = await SupabaseService.client.rpc(
          'notify_case_subscribers',
          params: <String, dynamic>{
            'p_case_id': selected.id,
            'p_case_type': selected.kind,
            'p_title_i18n': <String, String>{
              'fa': _caseTitleFa.text.trim(),
              'en': _caseTitleEn.text.trim(),
            },
            'p_body_i18n': <String, String>{
              'fa': _caseBodyFa.text.trim(),
              'en': _caseBodyEn.text.trim(),
            },
            'p_data': <String, dynamic>{'case_id': selected.id},
          });
      final int count = int.tryParse(delivered?.toString() ?? '') ?? 0;
      if (!mounted) return;
      _caseTitleFa.clear();
      _caseTitleEn.clear();
      _caseBodyFa.clear();
      _caseBodyEn.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اعلان برای $count مشترکِ این پرونده ارسال شد.')),
      );
    } catch (error) {
      if (mounted) setState(() => _caseError = error.toString());
    } finally {
      if (mounted) setState(() => _sendingCase = false);
    }
  }

  @override
  void dispose() {
    _publicTitleFa.dispose();
    _publicTitleEn.dispose();
    _publicBodyFa.dispose();
    _publicBodyEn.dispose();
    _caseTitleFa.dispose();
    _caseTitleEn.dispose();
    _caseBodyFa.dispose();
    _caseBodyEn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ارسال اعلان')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('اعلان عمومی', style: Theme.of(context).textTheme.titleMedium),
            const Text('برای تمام کاربران اپلیکیشن نمایش داده می‌شود.'),
            const SizedBox(height: 10),
            TextField(
                controller: _publicTitleFa,
                decoration: const InputDecoration(labelText: 'عنوان فارسی *')),
            const SizedBox(height: 8),
            TextField(
                controller: _publicTitleEn,
                decoration: const InputDecoration(labelText: 'English title')),
            const SizedBox(height: 8),
            TextField(
                controller: _publicBodyFa,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'متن فارسی *')),
            const SizedBox(height: 8),
            TextField(
                controller: _publicBodyEn,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'English message')),
            if (_publicError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_publicError,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _sendingPublic ? null : _sendPublic,
              icon: _sendingPublic
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.campaign_rounded),
              label: const Text('انتشار اعلان عمومی'),
            ),
            const Divider(height: 36),
            Text('اعلان ویژه پرونده',
                style: Theme.of(context).textTheme.titleMedium),
            const Text(
                'فقط به کاربرانی می‌رسد که زنگوله همان پرونده را فعال کرده‌اند.'),
            const SizedBox(height: 10),
            DropdownButtonFormField<CaseSummary>(
              value: _selectedCase,
              isExpanded: true,
              items: (_cases ?? <CaseSummary>[]).map((CaseSummary c) {
                final String label =
                    '${c.kind == 'iranian' ? '[ایرانی] ' : '[افغانی] '}${c.name['fa'] ?? c.id}';
                return DropdownMenuItem<CaseSummary>(
                  value: c,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (CaseSummary? value) =>
                  setState(() => _selectedCase = value),
              decoration: const InputDecoration(labelText: 'پرونده هدف'),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _caseTitleFa,
                decoration: const InputDecoration(labelText: 'عنوان فارسی *')),
            const SizedBox(height: 8),
            TextField(
                controller: _caseTitleEn,
                decoration: const InputDecoration(labelText: 'English title')),
            const SizedBox(height: 8),
            TextField(
                controller: _caseBodyFa,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'متن فارسی *')),
            const SizedBox(height: 8),
            TextField(
                controller: _caseBodyEn,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'English message')),
            if (_caseError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_caseError,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _sendingCase ? null : _sendCase,
              icon: _sendingCase
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.notifications_active_rounded),
              label: const Text('ارسال به مشترکان پرونده'),
            ),
          ],
        ),
      );
}
