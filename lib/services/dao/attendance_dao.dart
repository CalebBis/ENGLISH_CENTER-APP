import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class AttendanceDao {
  // -----------------------------------------------------------------------
  // Calculate attendance rate (presents / total) for a given period.
  // -----------------------------------------------------------------------
  Future<double> getAttendanceRate({DateTime? from, DateTime? to}) async {
    final db = await DatabaseHelper.instance.database;
    
    // Default to last 30 days if no dates provided
    final endDate = to ?? DateTime.now();
    final startDate = from ?? endDate.subtract(const Duration(days: 30));
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END) as presents
      FROM attendance
      WHERE date >= ? AND date <= ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    
    if (result.isNotEmpty) {
      final total = result.first['total'] as int? ?? 0;
      final presents = result.first['presents'] as int? ?? 0;
      
      if (total > 0) {
        return (presents / total) * 100;
      }
    }
    
    return 0.0;
  }
}
