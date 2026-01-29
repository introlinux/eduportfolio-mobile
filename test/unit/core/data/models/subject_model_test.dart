import 'package:eduportfolio/core/data/models/subject_model.dart';
import 'package:eduportfolio/core/domain/entities/subject.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubjectModel', () {
    final testDate = DateTime(2025, 1, 29);

    final testSubject = Subject(
      id: 1,
      name: 'Matemáticas',
      color: '#FF5733',
      icon: 'calculate',
      isDefault: true,
      createdAt: testDate,
    );

    final testModel = SubjectModel(
      id: 1,
      name: 'Matemáticas',
      color: '#FF5733',
      icon: 'calculate',
      isDefault: true,
      createdAt: testDate,
    );

    test('should convert from entity to model', () {
      final model = SubjectModel.fromEntity(testSubject);

      expect(model.id, testSubject.id);
      expect(model.name, testSubject.name);
      expect(model.color, testSubject.color);
      expect(model.icon, testSubject.icon);
      expect(model.isDefault, testSubject.isDefault);
      expect(model.createdAt, testSubject.createdAt);
    });

    test('should convert from model to entity', () {
      final entity = testModel.toEntity();

      expect(entity.id, testModel.id);
      expect(entity.name, testModel.name);
      expect(entity.color, testModel.color);
      expect(entity.icon, testModel.icon);
      expect(entity.isDefault, testModel.isDefault);
      expect(entity.createdAt, testModel.createdAt);
    });

    test('should convert to map for database', () {
      final map = testModel.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Matemáticas');
      expect(map['color'], '#FF5733');
      expect(map['icon'], 'calculate');
      expect(map['is_default'], 1);
      expect(map['created_at'], testDate.toIso8601String());
    });

    test('should create from database map', () {
      final map = {
        'id': 1,
        'name': 'Matemáticas',
        'color': '#FF5733',
        'icon': 'calculate',
        'is_default': 1,
        'created_at': testDate.toIso8601String(),
      };

      final model = SubjectModel.fromMap(map);

      expect(model.id, 1);
      expect(model.name, 'Matemáticas');
      expect(model.color, '#FF5733');
      expect(model.icon, 'calculate');
      expect(model.isDefault, true);
      expect(model.createdAt, testDate);
    });

    test('should handle null optional fields in toMap', () {
      final modelWithoutOptionals = SubjectModel(
        name: 'Lengua',
        createdAt: testDate,
      );

      final map = modelWithoutOptionals.toMap();

      expect(map.containsKey('id'), false);
      expect(map.containsKey('color'), false);
      expect(map.containsKey('icon'), false);
      expect(map['is_default'], 0);
    });

    test('should handle null optional fields in fromMap', () {
      final map = {
        'id': 2,
        'name': 'Lengua',
        'is_default': 0,
        'created_at': testDate.toIso8601String(),
      };

      final model = SubjectModel.fromMap(map);

      expect(model.id, 2);
      expect(model.name, 'Lengua');
      expect(model.color, null);
      expect(model.icon, null);
      expect(model.isDefault, false);
    });
  });
}
