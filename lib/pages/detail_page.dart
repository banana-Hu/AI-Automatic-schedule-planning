import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import 'focus_timer_page.dart';
import 'home_page.dart';
import '../app_state.dart';
import '../controllers/scheduler_service.dart';

class DetailPage extends StatefulWidget {
  final Event event;

  const DetailPage({super.key, required this.event});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with SingleTickerProviderStateMixin {
  late Event _event;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _changePriority() async {
    final newPriority = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrioritySelector(
        currentPriority: _event.priority,
      ),
    );

    if (newPriority != null && newPriority != _event.priority) {
      final repo = AppState.of(context).repo;
      await repo.update(_event.id!, {'priority': newPriority});
      HapticFeedback.mediumImpact();
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
          delayCount: _event.delayCount,
          originalStartAt: _event.originalStartAt,
        );
      });
      if (mounted) {
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
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Text('优先级已更新~'),
              ],
            ),
            backgroundColor: AppTheme.accentMint,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  Future<void> _delayEvent() async {
    try {
      final repo = AppState.of(context).repo;
      final now = DateTime.now().millisecondsSinceEpoch;
      final futureEvents = await repo.listActive();
      futureEvents.sort((a, b) => a.startAt.compareTo(b.startAt));

      final gapStartTime = SchedulerService.findFirstAvailableGap(
        futureEvents,
        _event.durationMin,
        now,
      );

      if (gapStartTime != null) {
        final newPriority = _event.priority < 5 ? _event.priority + 1 : 5;
        final updates = {
          'start_at': gapStartTime,
          'priority': newPriority,
          'delay_count': _event.delayCount + 1,
        };

        if (_event.originalStartAt == null) {
          updates['original_start_at'] = _event.startAt;
        }

        await repo.update(_event.id!, updates);
        HapticFeedback.mediumImpact();

        setState(() {
          _event = Event(
            id: _event.id,
            startAt: gapStartTime,
            durationMin: _event.durationMin,
            title: _event.title,
            createdAt: _event.createdAt,
            sourceText: _event.sourceText,
            llmRaw: _event.llmRaw,
            isArchived: _event.isArchived,
            priority: newPriority,
            focusTime: _event.focusTime,
            delayCount: _event.delayCount + 1,
            originalStartAt: _event.originalStartAt ?? _event.startAt,
          );
        });

        if (mounted) {
          final newStart = DateTime.fromMillisecondsSinceEpoch(gapStartTime);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '已延迟到 ${newStart.month}/${newStart.day} ${_formatTime(newStart)}~',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.accentPeach,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('延迟失败，请重试~')),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    return '${d.month}月${d.day}日';
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(_event.startAt);
    final end = start.add(Duration(minutes: _event.durationMin));
    final priorityColor = AppTheme.warmPastelColors[_event.priority % 6];

    return Scaffold(
      backgroundColor: AppTheme.primaryCream,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryCream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textBrown,
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
            boxShadow: AppTheme.softShadow,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, color: AppTheme.accentPeach, size: 18),
              SizedBox(width: 8),
              Text(
                '日程详情',
                style: TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _changePriority,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.flag_rounded,
                color: priorityColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主卡片 - 标题和时间
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [priorityColor.withOpacity(0.3), priorityColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                border: Border.all(color: priorityColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 优先级标签
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              color: AppTheme.textBrown,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Event.getPriorityText(_event.priority),
                              style: TextStyle(
                                color: AppTheme.textBrown,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_event.delayCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPink.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded, size: 12, color: AppTheme.accentPink),
                              const SizedBox(width: 4),
                              Text(
                                '延迟 ${_event.delayCount} 次',
                                style: TextStyle(
                                  color: AppTheme.accentPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 标题
                  Text(
                    _event.title,
                    style: const TextStyle(
                      color: AppTheme.textBrown,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 时间信息
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_animController.value * 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Icon(
                                Icons.access_time_rounded,
                                color: AppTheme.accentPeach,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📅 ${_formatDate(start)}',
                              style: const TextStyle(
                                color: AppTheme.textBrown,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🕐 ${_formatTime(start)} - ${_formatTime(end)}',
                              style: TextStyle(
                                color: AppTheme.textLightBrown,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 时长标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: AppTheme.accentMint,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_event.durationMin} 分钟',
                          style: const TextStyle(
                            color: AppTheme.textBrown,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_event.focusTime != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPeach.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: AppTheme.accentPeach,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '专注 ${_event.focusTime} 分钟',
                            style: TextStyle(
                              color: AppTheme.accentPeach,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FocusTimerPage(event: _event),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPeach,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_arrow_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          '开始专注',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _delayEvent,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentLavender,
                      side: const BorderSide(color: AppTheme.accentLavender, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.schedule_rounded, size: 20),
                        SizedBox(width: 6),
                        Text(
                          '延迟',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 原始文本
            if (_event.sourceText != null && _event.sourceText!.isNotEmpty)
              _buildInfoCard(
                icon: Icons.edit_note_rounded,
                iconColor: AppTheme.accentLavender,
                title: '原始输入',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLavender.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    _event.sourceText!,
                    style: const TextStyle(
                      color: AppTheme.textBrown,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

            if (_event.sourceText != null && _event.sourceText!.isNotEmpty)
              const SizedBox(height: 16),

            // AI 响应
            if (_event.llmRaw != null && _event.llmRaw!.isNotEmpty)
              _buildInfoCard(
                icon: Icons.smart_toy_rounded,
                iconColor: AppTheme.accentMint,
                title: 'AI 解析结果',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    _event.llmRaw!,
                    style: TextStyle(
                      color: AppTheme.textLightBrown,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final int currentPriority;

  const _PrioritySelector({required this.currentPriority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const FoxAssistant(size: 36),
              const SizedBox(width: 12),
              const Text(
                '选择优先级',
                style: TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(6, (index) {
            final color = AppTheme.warmPastelColors[index];
            final isSelected = index == currentPriority;

            return GestureDetector(
              onTap: () => Navigator.pop(context, index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.4) : color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(
                    color: isSelected ? AppTheme.textBrown.withOpacity(0.3) : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected ? AppTheme.softShadow : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: isSelected ? AppTheme.softShadow : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Event.getPriorityText(index),
                            style: const TextStyle(
                              color: AppTheme.textBrown,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ['无需特别关注', '可以稍后处理', '稍微重要', '需要重视', '比较紧急', '非常重要'][index],
                            style: TextStyle(
                              color: AppTheme.textLightBrown,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPeach.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
                        ),
                        child: Text(
                          '当前',
                          style: TextStyle(
                            color: AppTheme.accentPeach,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
