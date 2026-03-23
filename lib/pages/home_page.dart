import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/event.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Event> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = AppState.of(context).repo;
    await repo.archiveExpired();
    final list = await repo.listActive();
    if (mounted) {
      setState(() {
        _events = list;
        _loading = false;
      });
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final repo = AppState.of(context).repo;
    await repo.delete(event.id!);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日程已删除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日程')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('暂无日程'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _events.length,
                    itemBuilder: (context, i) {
                      final e = _events[i];
                      final start =
                          DateTime.fromMillisecondsSinceEpoch(e.startAt);
                      final end = start.add(Duration(minutes: e.durationMin));
                      return Dismissible(
                        key: ValueKey(e.id),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('删除确认'),
                                content: Text('确定要删除"${e.title}"吗？'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('删除'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await _deleteEvent(e);
                              return true;
                            }
                          }
                          return false;
                        },
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Event.getPriorityColor(e.priority),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(e.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_formatTime(start)} - ${_formatTime(end)} · ${e.durationMin}分钟',
                                ),
                                Text(
                                  '优先级: ${Event.getPriorityText(e.priority)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: e.focusTime != null
                                ? const Icon(Icons.timer)
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailPage(event: e),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/input').then((_) => _load());
          } else if (index == 2) {
            Navigator.pushNamed(context, '/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '日程'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: '输入'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }

  String _formatTime(DateTime d) {
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
