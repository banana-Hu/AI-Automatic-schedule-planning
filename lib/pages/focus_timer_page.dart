import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/event.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';

class FocusTimerPage extends StatefulWidget {
  final Event event;

  const FocusTimerPage({super.key, required this.event});

  @override
  State<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends State<FocusTimerPage>
    with SingleTickerProviderStateMixin {
  int _focusTime = 25;
  int _remainingTime = 25 * 60;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.event.focusTime != null) {
      _focusTime = widget.event.focusTime!;
      _remainingTime = _focusTime * 60;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    _pulseController.repeat(reverse: true);
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          timer.cancel();
          _pulseController.stop();
          _isRunning = false;
          _showCompletionDialog();
        }
      });
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _pulseController.stop();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingTime = _focusTime * 60;
    });
    _timer?.cancel();
  }

  void _showCompletionDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentMint.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  color: AppTheme.accentMint,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '🎉 专注完成！',
                style: TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '你完成了 $_focusTime 分钟的专注时间\n继续保持哦~',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textLightBrown,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPeach,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const Text(
                    '太棒了！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.warmPastelColors[widget.event.priority % 6];
    final progress = _remainingTime / (_focusTime * 60);

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_rounded, color: AppTheme.accentPeach, size: 18),
              const SizedBox(width: 8),
              const Text(
                '专注计时器',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 任务信息卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: priorityColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            color: AppTheme.textBrown,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Text(
                            Event.getPriorityText(widget.event.priority),
                            style: TextStyle(
                              color: AppTheme.textBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 计时器圆圈
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: _isRunning
                            ? AppTheme.accentPeach.withOpacity(0.2 + _pulseController.value * 0.2)
                            : AppTheme.shadowColor.withOpacity(0.1),
                        blurRadius: _isRunning ? 30 + _pulseController.value * 10 : 20,
                        spreadRadius: _isRunning ? _pulseController.value * 5 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 进度环
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: AppTheme.dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isRunning
                                ? AppTheme.accentPeach
                                : _isPaused
                                    ? AppTheme.accentLavender
                                    : AppTheme.textLightBrown,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // 时间显示
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remainingTime),
                            style: const TextStyle(
                              color: AppTheme.textBrown,
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isRunning
                                ? '🔥 专注中...'
                                : _isPaused
                                    ? '⏸️ 已暂停'
                                    : '☀️ 准备开始',
                            style: TextStyle(
                              color: AppTheme.textLightBrown,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning && !_isPaused)
                  _buildControlButton(
                    icon: Icons.play_arrow_rounded,
                    label: '开始',
                    color: AppTheme.accentPeach,
                    onPressed: _startTimer,
                  ),
                if (_isRunning)
                  _buildControlButton(
                    icon: Icons.pause_rounded,
                    label: '暂停',
                    color: AppTheme.accentLavender,
                    onPressed: _pauseTimer,
                  ),
                if (_isPaused)
                  _buildControlButton(
                    icon: Icons.play_arrow_rounded,
                    label: '继续',
                    color: AppTheme.accentPeach,
                    onPressed: _startTimer,
                  ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.refresh_rounded,
                  label: '重置',
                  color: AppTheme.textLightBrown,
                  onPressed: _resetTimer,
                  isOutlined: true,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 时间调整
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentMint.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppTheme.accentMint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '专注时间',
                        style: TextStyle(
                          color: AppTheme.textBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_focusTime > 5 && !_isRunning) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _focusTime -= 5;
                              _remainingTime = _focusTime * 60;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _isRunning
                                ? AppTheme.dividerColor
                                : AppTheme.accentPeach.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Icon(
                            Icons.remove_rounded,
                            color: _isRunning ? AppTheme.textLightBrown : AppTheme.accentPeach,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBackground,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          '$_focusTime 分钟',
                          style: const TextStyle(
                            color: AppTheme.textBrown,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {
                          if (_focusTime < 120 && !_isRunning) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _focusTime += 5;
                              _remainingTime = _focusTime * 60;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _isRunning
                                ? AppTheme.dividerColor
                                : AppTheme.accentPeach.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: _isRunning ? AppTheme.textLightBrown : AppTheme.accentPeach,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(AppTheme.radiusCircle),
          border: isOutlined ? Border.all(color: color, width: 2) : null,
          boxShadow: isOutlined ? null : AppTheme.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isOutlined ? color : Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isOutlined ? color : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
