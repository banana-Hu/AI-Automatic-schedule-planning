import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models/event.dart';
import '../controllers/scheduler_service.dart';
import '../theme/app_theme.dart';
import 'detail_page.dart';

/// 小狐狸 AI 助手组件
class FoxAssistant extends StatelessWidget {
  final double size;
  final bool isTalking;

  const FoxAssistant({
    super.key,
    this.size = 48,
    this.isTalking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 狐狸身体（圆形头像）
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.foxOrange, AppTheme.foxDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.foxOrange.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 脸部
              Positioned(
                top: size * 0.2,
                child: Container(
                  width: size * 0.5,
                  height: size * 0.4,
                  decoration: BoxDecoration(
                    color: AppTheme.foxLight,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(size * 0.3),
                      bottomRight: Radius.circular(size * 0.3),
                    ),
                  ),
                ),
              ),
              // 左耳
              Positioned(
                top: 0,
                left: size * 0.1,
                child: _buildEar(size * 0.3, true),
              ),
              // 右耳
              Positioned(
                top: 0,
                right: size * 0.1,
                child: _buildEar(size * 0.3, false),
              ),
              // 左眼
              Positioned(
                top: size * 0.35,
                left: size * 0.22,
                child: Container(
                  width: size * 0.08,
                  height: size * 0.1,
                  decoration: const BoxDecoration(
                    color: AppTheme.textBrown,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 右眼
              Positioned(
                top: size * 0.35,
                right: size * 0.22,
                child: Container(
                  width: size * 0.08,
                  height: size * 0.1,
                  decoration: const BoxDecoration(
                    color: AppTheme.textBrown,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // 鼻子
              Positioned(
                bottom: size * 0.28,
                child: Container(
                  width: size * 0.12,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    color: AppTheme.textBrown,
                    borderRadius: BorderRadius.circular(size * 0.04),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 对话气泡
        if (isTalking)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.accentPink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPink.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEar(double earSize, bool isLeft) {
    return CustomPaint(
      size: Size(earSize, earSize * 1.2),
      painter: _EarPainter(isLeft: isLeft),
    );
  }
}

class _EarPainter extends CustomPainter {
  final bool isLeft;

  _EarPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.foxOrange
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = AppTheme.foxLight
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // 内部三角形
    final innerPath = Path()
      ..moveTo(size.width / 2, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.15)
      ..lineTo(size.width * 0.8, size.height * 0.15)
      ..close();

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 可爱的加载动画
class CuteLoadingIndicator extends StatefulWidget {
  final double size;

  const CuteLoadingIndicator({super.key, this.size = 60});

  @override
  State<CuteLoadingIndicator> createState() => _CuteLoadingIndicatorState();
}

class _CuteLoadingIndicatorState extends State<CuteLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -_bounceAnimation.value),
              child: const FoxAssistant(size: 56, isTalking: true),
            ),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(
                color: AppTheme.textLightBrown,
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }
}

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
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '检测到过期任务，已自动顺延并提升优先级',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppTheme.accentPeach,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
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
      appBar: _buildAppBar(),
      body: _loading
          ? Center(child: CuteLoadingIndicator(size: 60))
          : _events.isEmpty
              ? _buildEmptyState()
              : _buildEventList(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _events.isNotEmpty ? _buildFAB() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryCream,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FoxAssistant(size: 36),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded, color: AppTheme.accentPeach, size: 20),
                SizedBox(width: 8),
                Text(
                  '我的日程',
                  style: TextStyle(
                    color: AppTheme.textBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI 助手对话气泡
            Container(
              padding: const EdgeInsets.all(24),
              decoration: CuteCardDecoration.aiBubble(),
              child: Column(
                children: [
                  const FoxAssistant(size: 80),
                  const SizedBox(height: 16),
                  Text(
                    '嗨！我是你的日程小助手~',
                    style: TextStyle(
                      color: AppTheme.textBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 用户气泡
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: CuteCardDecoration.userBubble(),
              child: const Text(
                '今天有什么计划吗？',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/input').then((_) => _load());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加第一条日程'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPeach,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
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
            child: _CuteEventCard(
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

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == 0;
    return InkWell(
      onTap: () {
        if (index == 1) {
          Navigator.pushNamed(context, '/input').then((_) => _load());
        } else if (index == 2) {
          Navigator.pushNamed(context, '/settings');
        }
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentPeach.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentPeach : AppTheme.textLightBrown,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentPeach : AppTheme.textLightBrown,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/input').then((_) => _load());
      },
      backgroundColor: AppTheme.accentPeach,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }
}

class _CuteEventCard extends StatefulWidget {
  final Event event;
  final DateTime start;
  final DateTime end;
  final bool isCompleting;
  final Function(bool) onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _CuteEventCard({
    required this.event,
    required this.start,
    required this.end,
    required this.isCompleting,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_CuteEventCard> createState() => _CuteEventCardState();
}

class _CuteEventCardState extends State<_CuteEventCard>
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

    return Dismissible(
      key: Key('event_${e.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.dividerColor.withOpacity(0.3)
                    : priorityColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: isCompleted
                      ? AppTheme.dividerColor
                      : priorityColor.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Stack(
                  children: [
                    // 左侧彩色边条
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              priorityColor,
                              priorityColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    // 内容
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 完成按钮
                          GestureDetector(
                            onTap: () => _handleComplete(!isCompleted),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? AppTheme.accentPeach
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCompleted
                                      ? AppTheme.accentPeach
                                      : AppTheme.textLightBrown,
                                  width: 2.5,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 详情
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 标题
                                Stack(
                                  children: [
                                    Text(
                                      e.title,
                                      style: TextStyle(
                                        fontSize: 17,
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
                                ),
                                const SizedBox(height: 8),
                                // 时间信息
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      icon: Icons.access_time_rounded,
                                      text: '${_formatTime(widget.start)} - ${_formatTime(widget.end)}',
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      icon: Icons.timer_outlined,
                                      text: '${e.durationMin}分钟',
                                      color: priorityColor,
                                    ),
                                  ],
                                ),
                                if (e.focusTime != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 16,
                                        color: AppTheme.accentPeach,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '专注 ${e.focusTime} 分钟',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.accentPeach,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // 优先级标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: Text(
                              Event.getPriorityText(e.priority),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final chipColor = color ?? AppTheme.textLightBrown;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
