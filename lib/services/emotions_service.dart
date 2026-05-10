import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/control_sphere.dart';
import '../models/zato_statement.dart';

class EmotionsService {
  static const String _controlSpheresKey = 'control_spheres';
  static const String _zatoStatementsKey = 'zato_statements';

  Future<List<ControlSphere>> getControlSpheres() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_controlSpheresKey);
    if (saved == null) return [];

    try {
      final data = jsonDecode(saved) as List;
      return data.map((e) => ControlSphere.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveControlSpheres(List<ControlSphere> spheres) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(spheres.map((e) => e.toMap()).toList());
    await prefs.setString(_controlSpheresKey, data);
  }

  Future<void> addControlSphere(ControlSphere sphere) async {
    final spheres = await getControlSpheres();
    spheres.insert(0, sphere);
    await saveControlSpheres(spheres);
  }

  Future<void> updateControlSphere(ControlSphere sphere) async {
    final spheres = await getControlSpheres();
    final index = spheres.indexWhere((s) => s.id == sphere.id);
    if (index != -1) {
      spheres[index] = sphere;
      await saveControlSpheres(spheres);
    }
  }

  Future<void> deleteControlSphere(String id) async {
    final spheres = await getControlSpheres();
    spheres.removeWhere((s) => s.id == id);
    await saveControlSpheres(spheres);
  }

  Future<void> clearControlSpheres() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_controlSpheresKey);
  }

  // ZATO statements
  Future<List<ZatoStatement>> getZatoStatements() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_zatoStatementsKey);
    if (saved == null) return [];

    try {
      final data = jsonDecode(saved) as List;
      return data.map((e) => ZatoStatement.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveZatoStatements(List<ZatoStatement> statements) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(statements.map((e) => e.toMap()).toList());
    await prefs.setString(_zatoStatementsKey, data);
  }

  Future<void> addZatoStatement(ZatoStatement statement) async {
    final statements = await getZatoStatements();
    statements.insert(0, statement);
    await saveZatoStatements(statements);
  }

  Future<void> updateZatoStatement(ZatoStatement statement) async {
    final statements = await getZatoStatements();
    final index = statements.indexWhere((s) => s.id == statement.id);
    if (index != -1) {
      statements[index] = statement;
      await saveZatoStatements(statements);
    }
  }

  Future<void> deleteZatoStatement(String id) async {
    final statements = await getZatoStatements();
    statements.removeWhere((s) => s.id == id);
    await saveZatoStatements(statements);
  }

  Future<void> toggleZatoStarred(String id) async {
    final statements = await getZatoStatements();
    final index = statements.indexWhere((s) => s.id == id);
    if (index != -1) {
      statements[index] = statements[index].copyWith(
        isStarred: !statements[index].isStarred,
      );
      await saveZatoStatements(statements);
    }
  }

  Future<void> clearZatoStatements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_zatoStatementsKey);
  }

  Map<String, int> getControlSphereStats(List<ControlSphere> spheres) {
    int controllable = 0;
    int notControllable = 0;
    Map<String, int> byTag = {};

    for (var sphere in spheres) {
      if (sphere.isControllable) {
        controllable++;
      } else {
        notControllable++;
      }

      byTag[sphere.tag] = (byTag[sphere.tag] ?? 0) + 1;
    }

    return {
      'controllable': controllable,
      'notControllable': notControllable,
      'total': spheres.length,
      ...byTag,
    };
  }

  int getStarredCount(List<ZatoStatement> statements) {
    return statements.where((s) => s.isStarred).length;
  }
}
