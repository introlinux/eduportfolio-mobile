import 'package:eduportfolio/core/utils/file_naming_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileNamingUtils', () {
    group('removeAccents', () {
      test('sustituye á, é, í, ó, ú minúsculas', () {
        expect(FileNamingUtils.removeAccents('áéíóú'), equals('aeiou'));
      });

      test('sustituye Á, É, Í, Ó, Ú mayúsculas', () {
        expect(FileNamingUtils.removeAccents('ÁÉÍÓÚ'), equals('AEIOU'));
      });

      test('sustituye ñ y Ñ', () {
        expect(FileNamingUtils.removeAccents('ñÑ'), equals('nN'));
      });

      test('sustituye ü minúscula', () {
        expect(FileNamingUtils.removeAccents('ü'), equals('u'));
      });

      test('no modifica texto sin acentos', () {
        expect(FileNamingUtils.removeAccents('Matematicas'), equals('Matematicas'));
      });

      test('devuelve cadena vacía para entrada vacía', () {
        expect(FileNamingUtils.removeAccents(''), equals(''));
      });

      test('ejemplo de uso: Matemáticas', () {
        expect(FileNamingUtils.removeAccents('Matemáticas'), equals('Matematicas'));
      });

      test('ejemplo de uso: Inglés', () {
        expect(FileNamingUtils.removeAccents('Inglés'), equals('Ingles'));
      });
    });

    group('generateSubjectId', () {
      test('retorna primeras 3 letras en mayúsculas para nombre largo', () {
        expect(FileNamingUtils.generateSubjectId('Matematicas'), equals('MAT'));
      });

      test('retorna primeras 3 letras en mayúsculas para Lengua', () {
        expect(FileNamingUtils.generateSubjectId('Lengua'), equals('LEN'));
      });

      test('retorna primeras 3 letras en mayúsculas para Inglés (con acento)', () {
        expect(FileNamingUtils.generateSubjectId('Inglés'), equals('ING'));
      });

      test('rellena con X si el nombre tiene 2 caracteres', () {
        expect(FileNamingUtils.generateSubjectId('Ed'), equals('EDX'));
      });

      test('rellena con XX si el nombre tiene 1 carácter', () {
        expect(FileNamingUtils.generateSubjectId('E'), equals('EXX'));
      });

      test('retorna XXX para cadena vacía', () {
        expect(FileNamingUtils.generateSubjectId(''), equals('XXX'));
      });

      test('elimina acentos antes de extraer las letras', () {
        expect(FileNamingUtils.generateSubjectId('Ártistica'), equals('ART'));
      });

      test('Matemáticas → MAT', () {
        expect(FileNamingUtils.generateSubjectId('Matemáticas'), equals('MAT'));
      });

      test('Ciencias → CIE', () {
        expect(FileNamingUtils.generateSubjectId('Ciencias'), equals('CIE'));
      });
    });

    group('normalizeStudentName', () {
      test('sustituye espacios por guiones', () {
        expect(FileNamingUtils.normalizeStudentName('Juan Garcia'), equals('Juan-Garcia'));
      });

      test('elimina acentos', () {
        expect(
          FileNamingUtils.normalizeStudentName('María López Pérez'),
          equals('Maria-Lopez-Perez'),
        );
      });

      test('combinado: acentos y espacios', () {
        expect(
          FileNamingUtils.normalizeStudentName('José Ángel Martínez'),
          equals('Jose-Angel-Martinez'),
        );
      });

      test('sin cambios si no hay acentos ni espacios', () {
        expect(
          FileNamingUtils.normalizeStudentName('JuanGarcia'),
          equals('JuanGarcia'),
        );
      });

      test('nombre con tres partes', () {
        expect(
          FileNamingUtils.normalizeStudentName('Ana María Sánchez López'),
          equals('Ana-Maria-Sanchez-Lopez'),
        );
      });
    });
  });
}
