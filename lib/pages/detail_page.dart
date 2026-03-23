import 'package:flutter/material.dart';
import '../models/event.dart';
import 'focus_timer_page.dart';
import '../app_state.dart';

class DetailPage extends StatefulWidget {
  final Event event;

  const DetailPage({super.key, required this.event});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Event _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _changePriority() async {
    final newPriority = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改优先级'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (index) {
            return GestureDetector(
              onTap: () => Navigator.pop(context, index),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: index == _event.priority
                      ? Event.getPriorityColor(index)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: index == _event.priority
                        ? Colors.black
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Event.getPriorityColor(index),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(Event.getPriorityText(index)),
                  ],
                ),
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (newPriority != null && newPriority != _event.priority) {
      final repo = AppState.of(context).repo;
      await repo.update(_event.id!, {'priority': newPriority});
      setState(() {
        _event = Event(
          id: _event.id,
          startAt: _event.startAt,
          durationMin: _event.durationMin,
          title: _event.title,
          createdAt: _event.createdAt,
          sourceText: _event.sourceText,
          llmRaw: _event.llmRaw,
          isArchived: _event.isArchived,
          priority: newPriority,
          focusTime: _event.focusTime,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('优先级已更新')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(_event.startAt);
    final end = start.add(Duration(minutes: _event.durationMin));

    return Scaffold(
      appBar: AppBar(
        title: const Text('日程详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _changePriority,
            tooltip: '修改优先级',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event.title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '时间',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(start)} ${_formatTime(start)} - ${_formatTime(end)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.timer, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '时长',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_event.durationMin} 分钟',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.flag, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '优先级',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Event.getPriorityText(_event.priority),
                          style: TextStyle(
                            fontSize: 18,
                            color: Event.getPriorityColor(_event.priority),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FocusTimerPage(event: _event),
                  ),
                );
              },
              icon: const Icon(Icons.timer),
              label: const Text('开始专注'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_event.sourceText != null && _event.sourceText!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '原始文本',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _event.sourceText!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_event.llmRaw != null && _event.llmRaw!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.code, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI 响应',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _event.llmRaw!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
