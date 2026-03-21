import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/deepseek_client.dart';
import '../services/prompt_builder.dart';
import '../services/json_extract.dart';
import '../services/auto_schedule.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final _textController = TextEditingController();
  bool _loading = false;

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
        const SnackBar(content: Text('请输入内容')),
      );
      return;
    }
    final apiKey = AppState.of(context).apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置 API Key')),
      );
      return;
    }
    setState(() => _loading = true);
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
      );
      if (events.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未能解析出有效日程，请重试或修改输入')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存 ${events.length} 条日程')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Parse/save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('输入'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              enabled: !_loading,
              decoration: const InputDecoration(
                hintText: '输入或粘贴日程文本…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _parseAndSave,
              child: _loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('解析并保存'),
            ),
          ],
        ),
      ),
    );
  }
}
