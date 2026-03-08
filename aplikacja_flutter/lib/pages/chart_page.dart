import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../student_service.dart';

class ChartPage extends StatefulWidget {
  final StudentService service;

  const ChartPage({super.key, required this.service});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<String> _students = [];
  String? _selectedStudent;
  List<ProgressPoint> _progress = [];
  bool _isLoadingStudents = true;
  bool _isLoadingProgress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoadingStudents = true;
      _error = null;
    });
    try {
      final students = await widget.service.getStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedStudent = students.isNotEmpty ? students.first : null;
      });
      if (_selectedStudent != null) {
        await _loadProgress(_selectedStudent!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się pobrać listy uczniów.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _loadProgress(String username) async {
    setState(() {
      _isLoadingProgress = true;
      _error = null;
    });
    try {
      final progress = await widget.service.getProgress(username);
      if (!mounted) return;
      setState(() {
        _progress = progress;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Nie udało się pobrać logów ucznia.';
        _progress = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingProgress = false;
      });
    }
  }

  String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  Widget _buildChart() {
    if (_progress.isEmpty) {
      return const Center(
        child: Text('Brak danych do wykresu dla wybranego ucznia.'),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _progress.length; i++) {
      spots.add(FlSpot(i.toDouble(), _progress[i].score.toDouble()));
    }

    final minY = _progress
        .map((e) => e.score)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final maxY = _progress
        .map((e) => e.score)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_progress.length - 1).toDouble(),
        minY: minY - 1,
        maxY: maxY + 1,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black12, width: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= _progress.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    _shortDate(_progress[index].date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            barWidth: 3,
            color: Colors.blue,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      appBar: AppBar(title: const Text('Wykres postępu ucznia')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900 || orientation == Orientation.landscape;
          final selector = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoadingStudents)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  value: _selectedStudent,
                  decoration: const InputDecoration(
                    labelText: 'Wybierz ucznia',
                    border: OutlineInputBorder(),
                  ),
                  items: _students
                      .map(
                        (student) => DropdownMenuItem<String>(
                          value: student,
                          child: Text(student),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedStudent = value;
                    });
                    _loadProgress(value);
                  },
                ),
              const SizedBox(height: 12),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (_isLoadingProgress) const LinearProgressIndicator(),
            ],
          );

          final chartArea = Column(
            children: [
              Expanded(child: _buildChart()),
              const SizedBox(height: 8),
              const Text(
                'Punktacja: poprawna odpowiedź +1, błędna -1 (wynik skumulowany).',
                textAlign: TextAlign.center,
              ),
            ],
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? Row(
                        children: [
                          SizedBox(width: 320, child: selector),
                          const SizedBox(width: 16),
                          Expanded(child: chartArea),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          selector,
                          const SizedBox(height: 12),
                          Expanded(child: chartArea),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
