import 'package:tailor_app/core/l10n/app_strings.dart';

// Icons for garments, fields and styles are drawn in
// presentation/icons/tailor_glyphs.dart, keyed by the ids below.

enum GarmentType {
  shirtKurta('shirt_kurta', 'Shirt / Kurta'),
  shalwarTrouser('shalwar_trouser', 'Shalwar / Trouser'),
  waistcoat('waistcoat', 'Waistcoat');

  const GarmentType(this.id, this._label);

  /// Stored in Firestore. Never change these strings.
  final String id;
  final String _label;

  String get label => S.current.dyn('garment.$id', _label);

  static GarmentType? fromId(String? id) {
    for (final type in GarmentType.values) {
      if (type.id == id) return type;
    }
    return null;
  }
}

class MeasurementField {
  const MeasurementField(this.key, this._label, {String? hint}) : _hint = hint;

  /// Stored in Firestore under `values`. Never change after release.
  final String key;
  final String _label;
  final String? _hint;

  String get label => S.current.dyn('field.$key', _label);

  /// Roman Urdu hint shown in the form (hidden when the app is in Urdu).
  String? get hint => S.current.dynOrNull('hint.$key', _hint);
}

class StyleOption {
  const StyleOption(this.id, this._label);

  final String id;
  final String _label;

  String get label => S.current.dyn('opt.$id', _label);
}

class StyleGroup {
  const StyleGroup(
      this.key,
      this._label,
      this.options, {
        this.multiSelect = false,
      });

  final String key;
  final String _label;

  String get label => S.current.dyn('group.$key', _label);
  final List<StyleOption> options;
  final bool multiSelect;
}

class GarmentTemplate {
  const GarmentTemplate({required this.fields, required this.styleGroups});

  final List<MeasurementField> fields;
  final List<StyleGroup> styleGroups;

  String optionLabel(String groupKey, String optionId) {
    for (final group in styleGroups) {
      if (group.key != groupKey) continue;
      for (final option in group.options) {
        if (option.id == optionId) return option.label;
      }
    }
    return optionId;
  }
}

/// Templates live in code, so adding a garment later is a small change
/// and old documents stay valid (they only reference stable keys).
class MeasurementTemplates {
  MeasurementTemplates._();

  static GarmentTemplate of(GarmentType type) {
    switch (type) {
      case GarmentType.shirtKurta:
        return _shirtKurta;
      case GarmentType.shalwarTrouser:
        return _shalwarTrouser;
      case GarmentType.waistcoat:
        return _waistcoat;
    }
  }

  static const GarmentTemplate _shirtKurta = GarmentTemplate(
    fields: [
      MeasurementField('length', 'Length', hint: 'Lambai'),
      MeasurementField('shoulder', 'Shoulder', hint: 'Teera'),
      MeasurementField('chest', 'Chest', hint: 'Chhati'),
      MeasurementField('waist', 'Waist', hint: 'Kamar'),
      MeasurementField('hip', 'Hip'),
      MeasurementField('daman', 'Daman'),
      MeasurementField('sleeve', 'Sleeve', hint: 'Baazu'),
      MeasurementField('armhole', 'Armhole'),
      MeasurementField('collar', 'Collar', hint: 'Gala'),
      MeasurementField('cuff', 'Cuff'),
    ],
    styleGroups: [
      StyleGroup('collar', 'Collar style', [
        StyleOption('band', 'Band'),
        StyleOption('shirt_collar', 'Shirt collar'),
        StyleOption('round_neck', 'Round neck'),
      ]),
      StyleGroup('cuff', 'Cuff style', [
        StyleOption('round', 'Round'),
        StyleOption('square', 'Square'),
        StyleOption('cuff_link', 'Cuff-link'),
      ]),
      StyleGroup('daman', 'Daman shape', [
        StyleOption('round', 'Round'),
        StyleOption('straight', 'Straight'),
      ]),
      StyleGroup(
        'pockets',
        'Pockets',
        [
          StyleOption('front', 'Front'),
          StyleOption('side', 'Side'),
        ],
        multiSelect: true,
      ),
    ],
  );

  static const GarmentTemplate _shalwarTrouser = GarmentTemplate(
    fields: [
      MeasurementField('length', 'Length', hint: 'Lambai'),
      MeasurementField('waist', 'Waist', hint: 'Kamar'),
      MeasurementField('hip', 'Hip'),
      MeasurementField('thigh', 'Thigh', hint: 'Ran'),
      MeasurementField('knee', 'Knee', hint: 'Ghutna'),
      MeasurementField('bottom', 'Bottom', hint: 'Paancha'),
    ],
    styleGroups: [
      StyleGroup('type', 'Type', [
        StyleOption('shalwar', 'Shalwar'),
        StyleOption('pajama', 'Pajama'),
        StyleOption('trouser', 'Trouser'),
      ]),
      StyleGroup(
        'pockets',
        'Pockets',
        [
          StyleOption('side', 'Side'),
          StyleOption('back', 'Back'),
        ],
        multiSelect: true,
      ),
      StyleGroup('bottom', 'Bottom style', [
        StyleOption('plain', 'Plain'),
        StyleOption('pleated', 'Pleated'),
      ]),
    ],
  );

  static const GarmentTemplate _waistcoat = GarmentTemplate(
    fields: [
      MeasurementField('length', 'Length', hint: 'Lambai'),
      MeasurementField('shoulder', 'Shoulder', hint: 'Teera'),
      MeasurementField('chest', 'Chest', hint: 'Chhati'),
      MeasurementField('waist', 'Waist', hint: 'Kamar'),
      MeasurementField('armhole', 'Armhole'),
    ],
    styleGroups: [
      StyleGroup('front', 'Front', [
        StyleOption('straight', 'Straight'),
        StyleOption('curved', 'Curved'),
      ]),
      StyleGroup(
        'pockets',
        'Pockets',
        [
          StyleOption('chest', 'Chest'),
          StyleOption('side', 'Side'),
        ],
        multiSelect: true,
      ),
    ],
  );
}