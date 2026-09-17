import '../utils/helpers.dart';

class CaseStep {
  const CaseStep({
    required this.index,
    required this.label,
    required this.title,
    required this.body,
  });

  final int index;
  final Map<String, dynamic> label;
  final Map<String, dynamic> title;
  final Map<String, dynamic> body;

  factory CaseStep.fromJson(Map<String, dynamic> json) => CaseStep(
        index: (json['index'] ?? 0) as int,
        label: (json['label'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        title: (json['title'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        body: (json['body'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      );

  String localizedLabel(String lang) => Helpers.pick(label, lang);
  String localizedTitle(String lang) => Helpers.pick(title, lang);
  String localizedBody(String lang) => Helpers.pick(body, lang);
}

class CaseNote {
  const CaseNote({required this.title, required this.body});

  final Map<String, dynamic> title;
  final Map<String, dynamic> body;

  factory CaseNote.fromJson(Map<String, dynamic> json) => CaseNote(
        title: (json['title'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        body: (json['body'] ?? <String, dynamic>{}) as Map<String, dynamic>,
      );

  String localizedTitle(String lang) => Helpers.pick(title, lang);
  String localizedBody(String lang) => Helpers.pick(body, lang);
}

/// Lightweight entry used by the Cases grid.
class CaseSummary {
  const CaseSummary({
    required this.id,
    required this.icon,
    required this.colorHex,
    required this.name,
    required this.subtitle,
    required this.stepCount,
    required this.file,
    this.kind = 'afghan',
    this.description = const <String, dynamic>{},
  });

  final String id;
  final String icon;
  final String colorHex;
  final Map<String, dynamic> name;
  final Map<String, dynamic> subtitle;
  final int stepCount;
  final String file;

  /// 'afghan' or 'iranian'; keeps the two sections' data strictly apart.
  final String kind;
  final Map<String, dynamic> description;

  bool get isIranian => kind == 'iranian';

  factory CaseSummary.fromJson(Map<String, dynamic> json) => CaseSummary(
        id: (json['id'] ?? '') as String,
        icon: (json['icon'] ?? 'folder') as String,
        colorHex: (json['color'] ?? '#1E88E5') as String,
        name: (json['name'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        subtitle:
            (json['subtitle'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        stepCount: (json['stepCount'] ?? 0) as int,
        file: (json['file'] ?? '') as String,
        kind: (json['kind'] ?? 'afghan') as String,
        description: (json['description'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
      );

  String localizedName(String lang) => Helpers.pick(name, lang, fallback: id);
  String localizedSubtitle(String lang) => Helpers.pick(subtitle, lang);
  String localizedDescription(String lang) =>
      Helpers.pick(description, lang);
}

/// Full case detail, loaded on demand from `assets/cases/<id>.json`.
class CaseModel {
  const CaseModel({
    required this.id,
    required this.icon,
    required this.colorHex,
    required this.name,
    required this.title,
    required this.steps,
    required this.notes,
    this.kind = 'afghan',
    this.description = const <String, dynamic>{},
  });

  final String id;
  final String icon;
  final String colorHex;
  final Map<String, dynamic> name;
  final Map<String, dynamic> title;
  final List<CaseStep> steps;
  final List<CaseNote> notes;
  final String kind;
  final Map<String, dynamic> description;

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
        id: (json['id'] ?? '') as String,
        icon: (json['icon'] ?? 'folder') as String,
        colorHex: (json['color'] ?? '#1E88E5') as String,
        name: (json['name'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        title: (json['title'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        steps: ((json['steps'] ?? const <dynamic>[]) as List<dynamic>)
            .map((dynamic e) => CaseStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: ((json['notes'] ?? const <dynamic>[]) as List<dynamic>)
            .map((dynamic e) => CaseNote.fromJson(e as Map<String, dynamic>))
            .toList(),
        kind: (json['kind'] ?? 'afghan') as String,
        description: (json['description'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
      );

  String localizedName(String lang) => Helpers.pick(name, lang, fallback: id);
  String localizedTitle(String lang) => Helpers.pick(title, lang);
  String localizedDescription(String lang) => Helpers.pick(description, lang);
}
