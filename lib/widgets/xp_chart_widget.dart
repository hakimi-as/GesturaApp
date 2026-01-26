import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';

/// Model for daily XP data point
class DailyXPData {
  final DateTime date;
  final int xpEarned;

  DailyXPData({required this.date, required this.xpEarned});

  factory DailyXPData.fromFirestore(Map<String, dynamic> data) {
    return DailyXPData(
      date: (data['date'] as Timestamp).toDate(),
      xpEarned: data['xpEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'xpEarned': xpEarned,
    };
  }
}

/// XP Progress Chart Widget - Shows XP earned over the last 7 days
class XPProgressChart extends StatefulWidget {
  final String userId;
  final int totalXP;
  final int currentStreak;

  const XPProgressChart({
    super.key,
    required this.userId,
    required this.totalXP,
    required this.currentStreak,
  });

  @override
  State<XPProgressChart> createState() => _XPProgressChartState();
}

class _XPProgressChartState extends State<XPProgressChart> {
  List<DailyXPData> _weeklyData = [];
  bool _isLoading = true;
  int _weeklyTotal = 0;
  int _maxXP = 100; // Default max for Y axis

  @override
  void initState() {
    super.initState();
    _loadWeeklyXPData();
  }

  Future<void> _loadWeeklyXPData() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 6));
      
      // Query Firestore for daily XP records
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('daily_xp')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(weekAgo.year, weekAgo.month, weekAgo.day)
          ))
          .orderBy('date')
          .get();

      // Create a map of existing data
      final Map<String, int> xpByDate = {};
      for (var doc in snapshot.docs) {
        final data = DailyXPData.fromFirestore(doc.data());
        final dateKey = DateFormat('yyyy-MM-dd').format(data.date);
        xpByDate[dateKey] = data.xpEarned;
      }

      // Fill in all 7 days (including days with 0 XP)
      List<DailyXPData> weekData = [];
      int total = 0;
      int maxVal = 50; // Minimum Y axis

      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final xp = xpByDate[dateKey] ?? 0;
        
        weekData.add(DailyXPData(date: date, xpEarned: xp));
        total += xp;
        if (xp > maxVal) maxVal = xp;
      }

      setState(() {
        _weeklyData = weekData;
        _weeklyTotal = total;
        _maxXP = ((maxVal / 50).ceil() * 50) + 50; // Round up to nearest 50 + buffer
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading XP data: $e');
      // Generate empty data for 7 days
      final now = DateTime.now();
      List<DailyXPData> emptyData = [];
      for (int i = 6; i >= 0; i--) {
        emptyData.add(DailyXPData(
          date: now.subtract(Duration(days: i)),
          xpEarned: 0,
        ));
      }
      setState(() {
        _weeklyData = emptyData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📈', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'XP Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Last 7 days',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Stats row
          Row(
            children: [
              _buildMiniStat('⭐', '$_weeklyTotal', 'This Week'),
              const SizedBox(width: 16),
              _buildMiniStat('🔥', '${widget.currentStreak}', 'Streak'),
              const SizedBox(width: 16),
              _buildMiniStat('🏆', '${widget.totalXP}', 'Total XP'),
            ],
          ),
          const SizedBox(height: 20),
          
          // Chart
          SizedBox(
            height: 180,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: context.bgElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: context.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_weeklyData.isEmpty) {
      return Center(
        child: Text(
          'No XP data yet',
          style: TextStyle(color: context.textMuted),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (_maxXP / 4).ceilToDouble(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: context.borderColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (_maxXP / 4).ceilToDouble(),
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _weeklyData.length) {
                  return const SizedBox();
                }
                final date = _weeklyData[index].date;
                final dayName = DateFormat('E').format(date); // Mon, Tue, etc.
                final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
                
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    dayName,
                    style: TextStyle(
                      color: isToday ? AppColors.primary : context.textMuted,
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: _maxXP.toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: _weeklyData.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.xpEarned.toDouble(),
              );
            }).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isToday = index == _weeklyData.length - 1;
                return FlDotCirclePainter(
                  radius: isToday ? 6 : 4,
                  color: isToday ? const Color(0xFF8B5CF6) : const Color(0xFF6366F1),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withAlpha(50),
                  const Color(0xFF8B5CF6).withAlpha(10),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: context.bgCard,
            tooltipRoundedRadius: 8,
            tooltipBorder: BorderSide(color: context.borderColor),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= _weeklyData.length) {
                  return null;
                }
                final data = _weeklyData[index];
                final dateStr = DateFormat('MMM d').format(data.date);
                return LineTooltipItem(
                  '$dateStr\n',
                  TextStyle(
                    color: context.textMuted,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: '${data.xpEarned} XP',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// Service to track daily XP
class DailyXPService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Record XP earned for today
  Future<void> recordDailyXP(String userId, int xpEarned) async {
    final today = DateTime.now();
    final dateKey = DateFormat('yyyy-MM-dd').format(today);
    
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_xp')
        .doc(dateKey);

    // Use transaction to safely increment
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      
      if (doc.exists) {
        final currentXP = doc.data()?['xpEarned'] ?? 0;
        transaction.update(docRef, {
          'xpEarned': currentXP + xpEarned,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.set(docRef, {
          'date': Timestamp.fromDate(DateTime(today.year, today.month, today.day)),
          'xpEarned': xpEarned,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Get weekly XP data
  Future<List<DailyXPData>> getWeeklyXP(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_xp')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(weekAgo.year, weekAgo.month, weekAgo.day)
        ))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => DailyXPData.fromFirestore(doc.data()))
        .toList();
  }
}