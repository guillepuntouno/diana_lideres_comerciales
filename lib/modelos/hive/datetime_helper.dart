/// Helper para parsing de DateTime en modelos Hive
class DateTimeHelper {
  /// Parser robusto de fechas desde múltiples formatos
  /// Retorna DateTime válido o null si no se puede parsear
  static DateTime? parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }

    if (dateValue is DateTime) return dateValue;
    return null;
  }

  /// Parser que garantiza un DateTime válido
  /// Retorna DateTime válido o DateTime.now() como fallback
  static DateTime parseDateTimeWithFallback(dynamic dateValue) {
    return parseDateTime(dateValue) ?? DateTime.now();
  }

  /// Formatea DateTime para JSON
  static String? formatForJson(DateTime? dateTime) {
    return dateTime?.toIso8601String();
  }
}