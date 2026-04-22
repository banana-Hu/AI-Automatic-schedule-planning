import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models/event.dart';
import '../controllers/scheduler_service.dart';
import '../theme/app_theme.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Event> _events = [];
  bool _loading = true;
  final Set<int> _completingIds = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final repo = AppState.of(context).repo;
      final hasRescheduled = await SchedulerService.checkAndReschedule(repo);
      await _load();
      if (hasRescheduled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('检测到过期任务，已自动顺延并提升优先级'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppTheme.textBrown,
          ),
        );
      }
    } catch (e) {
      print('初始化错误: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _events = [];
        });
      }
    }
  }

  Future<void> _load() async {
    try {
      final repo = AppState.of(context).repo;
      await repo.archiveExpired();
      final list = await repo.listActive();
      if (mounted) {
        setState(() {
          _events = list;
          _loading = false;
        });
      }
    } catch (e) {
      print('加载错误: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _events = [];
        });
      }
    }
  }

  Future<void> _deleteEvent(Event event) async {
    try {
      final repo = AppState.of(context).repo;
      await repo.delete(event.id!);
      await _load();
    } catch (e) {
      print('删除错误: $e');
    }
  }

  Future<void> _toggleCompleted(Event event, bool isCompleted) async {
    if (_completingIds.contains(event.id)) return;
    
    _completingIds.add(event.id!);
    
    try {
      final repo = AppState.of(context).repo;
      await repo.update(event.id!, {'is_completed': isCompleted ? 1 : 0});
      
      if (isCompleted && mounted) {
        HapticFeedback.mediumImpact();
      }
      
      await _load();
    } catch (e) {
      print('更新错误: $e');
    } finally {
      _completingIds.remove(event.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCream,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCream,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.book_rounded, color: AppTheme.accentPeach, size: 24),
              SizedBox(width: 8),
              Text(
                '我的日程',
                style: TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor.withOpacity(0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: AppTheme.accentPeach,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '正在加载...',
                    style: TextStyle(
                      color: AppTheme.textLightBrown,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : _events.isEmpty
              ? _buildEmptyState()
              : _buildEventList(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.calendar_today_rounded, '日程'),
                _buildNavItem(1, Icons.edit_rounded, '写日记'),
                _buildNavItem(2, Icons.settings_rounded, '设置'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return InkWell(
      onTap: () {
        if (index == 1) {
          Navigator.pushNamed(context, '/input').then((_) => _load());
        } else if (index == 2) {
          Navigator.pushNamed(context, '/settings');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: index == 0 ? AppTheme.accentPeach.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: index == 0 ? AppTheme.accentPeach : AppTheme.textLightBrown,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: index == 0 ? AppTheme.accentPeach : AppTheme.textLightBrown,
                fontSize: 12,
                fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor.withOpacity(0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 64,
              color: AppTheme.accentPeach,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '今天想记录些什么呢？',
            style: TextStyle(
              color: AppTheme.textBrown,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '点击下方"写日记"开始添加日程',
            style: TextStyle(
              color: AppTheme.textLightBrown,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 48),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/input').then((_) => _load());
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('添加第一条日程'),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppTheme.cardBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accentPeach,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 100),
        itemCount: _events.length,
        itemBuilder: (context, i) {
          final e = _events[i];
          final start = DateTime.fromMillisecondsSinceEpoch(e.startAt);
          final end = start.add(Duration(minutes: e.durationMin));
          final isCompleting = _completingIds.contains(e.id);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: _DiaryEventCard(
              event: e,
              start: start,
              end: end,
              isCompleting: isCompleting,
              onToggleComplete: (value) => _toggleCompleted(e, value),
              onDelete: () => _deleteEvent(e),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPage(event: e),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DiaryEventCard extends StatefulWidget {
  final Event event;
  final DateTime start;
  final DateTime end;
  final bool isCompleting;
  final Function(bool) onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _DiaryEventCard({
    required this.event,
    required this.start,
    required this.end,
    required this.isCompleting,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_DiaryEventCard> createState() => _DiaryEventCardState();
}

class _DiaryEventCardState extends State<_DiaryEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _strikeAnimation;
  late Animation<double> _fadeAnimation;
  bool _showDelete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _strikeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 1, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleComplete(bool value) {
    if (value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    widget.onToggleComplete(value);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final isCompleted = e.isCompleted;
    final priorityColor = AppTheme.warmPastelColors[e.priority % 6];

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
          setState(() => _showDelete = true);
        } else if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
          setState(() => _showDelete = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(_showDelete ? -60 : 0, 0, 0),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.dividerColor.withOpacity(0.3)
                          : priorityColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompleted
                            ? AppTheme.dividerColor
                            : priorityColor.withOpacity(0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor.withOpacity(isCompleted ? 0.05 : 0.1),
                          blurRadius: isCompleted ? 4 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: priorityColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _handleComplete(!isCompleted),
                                  child: AnimatedBuilder(
                                    animation: _strikeAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? AppTheme.accentPeach
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isCompleted
                                                ? AppTheme.accentPeach
                                                : AppTheme.textLightBrown,
                                            width: 2,
                                          ),
                                        ),
                                        child: isCompleted
                                            ? const Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                                color: Colors.white,
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _strikeAnimation,
                                        builder: (context, child) {
                                          return Stack(
                                            children: [
                                              Text(
                                                e.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color.lerp(
                                                    AppTheme.textBrown,
                                                    AppTheme.textLightBrown,
                                                    _fadeAnimation.value,
                                                  ),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (_strikeAnimation.value > 0)
                                                Positioned.fill(
                                                  child: LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      return Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          width: constraints.maxWidth *
                                                              _strikeAnimation.value,
                                                          height: 2,
                                                          color: AppTheme.textLightBrown,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: isCompleted
                                                ? AppTheme.textLightBrown.withOpacity(0.5)
                                                : AppTheme.textLightBrown,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_formatTime(widget.start)} - ${_formatTime(widget.end)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isCompleted
                                                  ? AppTheme.textLightBrown.withOpacity(0.5)
                                                  : AppTheme.textLightBrown,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: priorityColor.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${e.durationMin}分钟',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isCompleted
                                                    ? AppTheme.textLightBrown.withOpacity(0.5)
                                                    : AppTheme.textLightBrown,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (e.focusTime != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.timer_rounded,
                                              size: 14,
                                              color: isCompleted
                                                  ? AppTheme.accentPeach.withOpacity(0.5)
                                                  : AppTheme.accentPeach,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '专注 ${e.focusTime} 分钟',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isCompleted
                                                    ? AppTheme.accentPeach.withOpacity(0.5)
                                                    : AppTheme.accentPeach,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppTheme.textLightBrown.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
