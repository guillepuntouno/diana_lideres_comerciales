import 'package:hive/hive.dart';

class CatalogoDiasService {
  static const _boxName = 'catalogoDiasVisita';

  static Future<Box> openBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    final box = await Hive.openBox(_boxName);
    if (box.isEmpty) {
      await box.addAll(_seed);
    }
    return box;
  }

  static final List<Map<String, dynamic>> _seed = [
    {
      "dia": "Lunes",
      "codes": {"01": "L01", "02": "L02", "03": "L03"},
      "desc": {
        "01": "Lunes (Semanal)",
        "02": "Lunes (Quincenal 1)",
        "03": "Lunes (Quincenal 2)"
      }
    },
    {
      "dia": "Martes",
      "codes": {"01": "M01", "02": "M02", "03": "M03"},
      "desc": {
        "01": "Martes (Semanal)",
        "02": "Martes (Quincenal 1)",
        "03": "Martes (Quincenal 2)"
      }
    },
    {
      "dia": "Miércoles",
      "codes": {"01": "W01", "02": "W02", "03": "W03"},
      "desc": {
        "01": "Miércoles (Semanal)",
        "02": "Miércoles (Quincenal 1)",
        "03": "Miércoles (Quincenal 2)"
      }
    },
    {
      "dia": "Jueves",
      "codes": {"01": "J01", "02": "J02", "03": "J03"},
      "desc": {
        "01": "Jueves (Semanal)",
        "02": "Jueves (Quincenal 1)",
        "03": "Jueves (Quincenal 2)"
      }
    },
    {
      "dia": "Viernes",
      "codes": {"01": "V01", "02": "V02", "03": "V03"},
      "desc": {
        "01": "Viernes (Semanal)",
        "02": "Viernes (Quincenal 1)",
        "03": "Viernes (Quincenal 2)"
      }
    },
    {
      "dia": "Sábado",
      "codes": {"01": "S01", "02": "S02", "03": "S03"},
      "desc": {
        "01": "Sábado (Semanal)",
        "02": "Sábado (Quincenal 1)",
        "03": "Sábado (Quincenal 2)"
      }
    },
    {
      "dia": "Domingo",
      "codes": {"01": "D01", "02": "D02", "03": "D03"},
      "desc": {
        "01": "Domingo (Semanal)",
        "02": "Domingo (Quincenal 1)",
        "03": "Domingo (Quincenal 2)"
      }
    }
  ];
}