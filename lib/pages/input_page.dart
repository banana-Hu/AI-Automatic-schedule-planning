import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models/event.dart';
import '../services/deepseek_client.dart';
import '../services/prompt_builder.dart';
import '../services/json_extract.dart';
import '../services/auto_schedule.dart';
import '../theme/app_theme.dart';
import 'goal_planner_page.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final _textController = TextEditingController();
  bool _loading = false;
  int _priority = 0;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _textController.text = args;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _parseAndSave() async {
    final raw = _textController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('请输入一些内容再保存哦~'),
            ],
          ),
          backgroundColor: AppTheme.textBrown,
        ),
      );
      return;
    }
    final apiKey = AppState.of(context).apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.key_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('需要先配置 API Key 才能使用哦'),
            ],
          ),
          backgroundColor: AppTheme.accentPeach,
          action: SnackBarAction(
            label: '去设置',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    HapticFeedback.lightImpact();
    try {
      final client = DeepSeekClient(apiKey: apiKey);
      final system = systemPrompt();
      final user = userPrompt(raw, DateTime.now());
      final response = await client.chat(system, user);
      debugPrint('DeepSeek raw: $response');
      final json = extractJsonObject(response);
      final rawList = extractEventsList(json);
      final createdAt = DateTime.now().millisecondsSinceEpoch;
      var events = parseEventsFromLlm(
        rawList,
        createdAt: createdAt,
        sourceText: raw,
        llmRaw: response,
      )
          .map((e) => Event(
                id: e.id,
                startAt: e.startAt,
                durationMin: e.durationMin,
                title: e.title,
                createdAt: e.createdAt,
                sourceText: e.sourceText,
                llmRaw: e.llmRaw,
                priority: _priority,
              ))
          .toList();
      if (events.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.sentiment_dissatisfied_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('没能理解呢，换种方式描述试试？'),
                ],
              ),
              backgroundColor: AppTheme.textBrown,
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      final repo = AppState.of(context).repo;
      final existing = await repo.listAll();
      events = linearReschedule(existing, events);
      for (final e in events) {
        await repo.insert(e);
      }
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text('已添加 ${events.length} 条日程~'),
              ],
            ),
            backgroundColor: AppTheme.accentMint,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Parse/save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('出错了: $e')),
              ],
            ),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textBrown,
            ),
          ),
        ),
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
              Icon(Icons.edit_rounded, color: AppTheme.accentPeach, size: 20),
              SizedBox(width: 8),
              Text(
                '写日记',
                style: TextStyle(
                  color: AppTheme.textBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPeach.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: AppTheme.accentPeach,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '今天想做什么？',
                        style: TextStyle(
                          color: AppTheme.textBrown,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryCream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: 8,
                      enabled: !_loading,
                      style: const TextStyle(
                        color: AppTheme.textBrown,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: '比如：\n明天上午9点开会\n下午3点去健身房\n晚上8点看书的30页',
                        hintStyle: TextStyle(
                          color: AppTheme.textLightBrown.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLavender.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: AppTheme.accentLavender,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '优先级',
                        style: TextStyle(
                          color: AppTheme.textBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(6, (index) {
                      final isSelected = _priority == index;
                      final color = AppTheme.warmPastelColors[index];
                      return GestureDetector(
                        onTap: _loading
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _priority = index);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.6)
                                : color.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.textBrown.withOpacity(0.3)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.textBrown
                                      : AppTheme.textLightBrown,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ['无', '低', '中低', '中', '中高', '高'][index],
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.textBrown
                                      : AppTheme.textLightBrown,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _parseAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPeach,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                shadowColor: AppTheme.accentPeach.withOpacity(0.4),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_mosaic_rounded),
                        SizedBox(width: 8),
                        Text(
                          'AI 智能解析',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GoalPlannerPage(),
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('目标规划助手'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentLavender,
                side: const BorderSide(
                  color: AppTheme.accentLavender,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
