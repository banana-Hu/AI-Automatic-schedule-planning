import 'package:flutter/material.dart';
import '../data/event_repo.dart';
import '../models/event.dart';

class SchedulerService {
  static Future<void> checkAndReschedule(BuildContext context, EventRepo repo) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // 查询所有过期未完成的任务（未归档且开始时间小于当前时间）
      final expiredEvents = await repo.listInRange(0, now);
      
      if (expiredEvents.isEmpty) {
        return;
      }
      
      // 获取当前时间后的所有活跃日程
      final futureEvents = await repo.listActive();
      // 按开始时间排序
      futureEvents.sort((a, b) => a.startAt.compareTo(b.startAt));
      
      bool hasRescheduled = false;
      
      for (final event in expiredEvents) {
        // 计算任务结束时间
        final eventEndTime = event.startAt + event.durationMin * 60 * 1000;
        
        // 只处理未归档且确实过期的任务
        if (!event.isArchived && eventEndTime < now) {
          // 优先级升级：priority = min(5, priority + 1)
          final newPriority = event.priority < 5 ? event.priority + 1 : 5;
          
          // 查找第一个足以容纳该过期任务时长的空隙
          final gapStartTime = _findFirstAvailableGap(futureEvents, event.durationMin, now);
          
          if (gapStartTime != null) {
            // 更新任务信息
            final updates = {
              'start_at': gapStartTime,
              'priority': newPriority,
              'delay_count': event.delayCount + 1,
            };
            
            // 如果是第一次延迟，记录原始开始时间
            if (event.originalStartAt == null) {
              updates['original_start_at'] = event.startAt;
            }
            
            // 保存改动
            await repo.update(event.id!, updates);
            hasRescheduled = true;
          }
        }
      }
      
      // 如果有任务被顺延，显示提醒
      if (hasRescheduled && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('检测到过期任务，已自动顺延并提升优先级'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Scheduler error: $e');
    }
  }
  
  /// 查找第一个可用的时间空隙
  static int? _findFirstAvailableGap(List<Event> futureEvents, int durationMin, int currentTime) {
    final durationMs = durationMin * 60 * 1000;
    
    // 检查当前时间到第一个事件之间的空隙
    if (futureEvents.isEmpty) {
      // 如果没有未来事件，从当前时间开始
      return currentTime;
    }
    
    // 检查当前时间到第一个事件的空隙
    final firstEvent = futureEvents.first;
    if (firstEvent.startAt - currentTime >= durationMs) {
      return currentTime;
    }
    
    // 检查事件之间的空隙
    for (int i = 0; i < futureEvents.length - 1; i++) {
      final currentEvent = futureEvents[i];
      final nextEvent = futureEvents[i + 1];
      
      final currentEndTime = currentEvent.startAt + currentEvent.durationMin * 60 * 1000;
      final gapDuration = nextEvent.startAt - currentEndTime;
      
      if (gapDuration >= durationMs) {
        return currentEndTime;
      }
    }
    
    // 如果没有找到空隙，安排在最后一个事件之后
    final lastEvent = futureEvents.last;
    final lastEndTime = lastEvent.startAt + lastEvent.durationMin * 60 * 1000;
    return lastEndTime;
  }
}
