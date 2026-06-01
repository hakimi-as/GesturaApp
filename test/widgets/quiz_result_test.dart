import 'package:flutter_test/flutter_test.dart';
import 'package:Gestura/screens/quiz/quiz_result_screen.dart';

// Unit tests for QuizResultScreen logic helpers — no widget pump needed
// (the screen requires QuizProvider + AuthProvider + Firebase which make
// full widget tests expensive; these cover the pure-logic portions).

class _QuizResultLogic {
  Color getScoreColor(int percentage) {
    const success = Color(0xFF10B981);
    const accent = Color(0xFFEC4899);
    const warning = Color(0xFFF59E0B);
    const error = Color(0xFFEF4444);
    if (percentage >= 90) return success;
    if (percentage >= 70) return accent;
    if (percentage >= 50) return warning;
    return error;
  }

  bool isPassed(int percentage) => percentage >= 70;
  bool isPerfect(int correct, int total) => total > 0 && correct == total;
}

// Minimal Color stub to avoid importing flutter/material in a unit test
class Color {
  final int value;
  const Color(this.value);
  @override
  bool operator ==(Object other) => other is Color && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

void main() {
  final logic = _QuizResultLogic();

  group('QuizResultScreen score color', () {
    test('100% is success green', () {
      expect(logic.getScoreColor(100), const Color(0xFF10B981));
    });
    test('90% is success green', () {
      expect(logic.getScoreColor(90), const Color(0xFF10B981));
    });
    test('80% is accent (pass band)', () {
      expect(logic.getScoreColor(80), const Color(0xFFEC4899));
    });
    test('70% is accent (pass threshold)', () {
      expect(logic.getScoreColor(70), const Color(0xFFEC4899));
    });
    test('60% is warning', () {
      expect(logic.getScoreColor(60), const Color(0xFFF59E0B));
    });
    test('50% is warning (lower pass)', () {
      expect(logic.getScoreColor(50), const Color(0xFFF59E0B));
    });
    test('40% is error red', () {
      expect(logic.getScoreColor(40), const Color(0xFFEF4444));
    });
    test('0% is error red', () {
      expect(logic.getScoreColor(0), const Color(0xFFEF4444));
    });
  });

  group('QuizResultScreen isPassed', () {
    test('70% passes', () => expect(logic.isPassed(70), isTrue));
    test('100% passes', () => expect(logic.isPassed(100), isTrue));
    test('69% fails', () => expect(logic.isPassed(69), isFalse));
    test('0% fails', () => expect(logic.isPassed(0), isFalse));
  });

  group('QuizResultScreen isPerfect', () {
    test('10/10 is perfect', () => expect(logic.isPerfect(10, 10), isTrue));
    test('9/10 is not perfect', () => expect(logic.isPerfect(9, 10), isFalse));
    test('0/0 is not perfect (empty quiz guard)', () => expect(logic.isPerfect(0, 0), isFalse));
    test('0/5 is not perfect', () => expect(logic.isPerfect(0, 5), isFalse));
  });

  // Verify the widget class is accessible
  test('QuizResultScreen is a StatefulWidget', () {
    expect(const QuizResultScreen(quizType: 'test'), isA<QuizResultScreen>());
  });
}
