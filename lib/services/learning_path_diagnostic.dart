import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Diagnostic tool to check your Firestore structure
/// Run: await LearningPathDiagnostic.checkStructure();
class LearningPathDiagnostic {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check and print the structure of your categories and lessons
  static Future<void> checkStructure() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 DIAGNOSING YOUR FIRESTORE STRUCTURE');
    debugPrint('═══════════════════════════════════════════════════════');

    // Check categories
    debugPrint('\n📁 CATEGORIES COLLECTION:');
    final categoriesSnapshot = await _db.collection('categories').limit(2).get();
    
    if (categoriesSnapshot.docs.isEmpty) {
      debugPrint('   ❌ No categories found!');
      return;
    }

    for (var doc in categoriesSnapshot.docs) {
      debugPrint('   📄 Document ID: ${doc.id}');
      debugPrint('   📋 Fields: ${doc.data().keys.toList()}');
      doc.data().forEach((key, value) {
        debugPrint('      • $key: $value');
      });
      debugPrint('');
    }

    // Check lessons
    debugPrint('\n📚 LESSONS COLLECTION:');
    final lessonsSnapshot = await _db.collection('lessons').limit(3).get();
    
    if (lessonsSnapshot.docs.isEmpty) {
      debugPrint('   ❌ No lessons found!');
      return;
    }

    for (var doc in lessonsSnapshot.docs) {
      debugPrint('   📄 Document ID: ${doc.id}');
      debugPrint('   📋 Fields: ${doc.data().keys.toList()}');
      doc.data().forEach((key, value) {
        // Truncate long values
        final displayValue = value.toString().length > 50 
            ? '${value.toString().substring(0, 50)}...' 
            : value;
        debugPrint('      • $key: $displayValue');
      });
      debugPrint('');
    }

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('✅ DIAGNOSIS COMPLETE - Check the field names above!');
    debugPrint('═══════════════════════════════════════════════════════');
  }
}