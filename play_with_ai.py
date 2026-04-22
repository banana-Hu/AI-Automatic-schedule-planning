import pygame
import numpy as np
from stable_baselines3 import PPO
from game_ai import DuelGameEnv

class HumanPlayer:
    """人类玩家控制"""
    def __init__(self):
        self.keys = {
            pygame.K_UP: False,
            pygame.K_DOWN: False,
            pygame.K_LEFT: False,
            pygame.K_RIGHT: False,
            pygame.K_z: False,
            pygame.K_x: False
        }
    
    def update(self):
        """更新按键状态"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return False
            elif event.type == pygame.KEYDOWN:
                if event.key in self.keys:
                    self.keys[event.key] = True
            elif event.type == pygame.KEYUP:
                if event.key in self.keys:
                    self.keys[event.key] = False
        return True
    
    def get_action(self):
        """获取动作"""
        # 移动动作
        move_action = 0  # 静止
        if self.keys[pygame.K_UP]:
            move_action = 1  # 上
        elif self.keys[pygame.K_DOWN]:
            move_action = 2  # 下
        elif self.keys[pygame.K_LEFT]:
            move_action = 3  # 左
        elif self.keys[pygame.K_RIGHT]:
            move_action = 4  # 右
        
        # 开火动作
        fire_action = 0  # 不操作
        if self.keys[pygame.K_z]:
            fire_action = 1  # 普通攻击
        elif self.keys[pygame.K_x]:
            fire_action = 2  # 特殊攻击
        
        return [move_action, fire_action]

def main():
    """主函数"""
    # 初始化 pygame
    pygame.init()
    
    # 创建环境
    env = DuelGameEnv(render_mode="human")
    
    # 加载训练好的模型
    try:
        model = PPO.load("game_models/duel_game_final")
        print("已加载训练好的模型")
    except Exception as e:
        print(f"未找到训练好的模型，使用内置AI: {e}")
        model = None
    
    # 创建人类玩家
    human = HumanPlayer()
    
    # 重置环境
    obs, _ = env.reset()
    
    done = False
    total_reward = 0
    clock = pygame.time.Clock()
    
    while not done:
        # 更新人类玩家输入
        if not human.update():
            break
        
        # 获取人类玩家动作
        human_action = human.get_action()
        
        # 执行动作
        obs, reward, done, truncated, _ = env.step(human_action)
        total_reward += reward
        
        # 渲染游戏画面
        env.render()
        
        # 控制帧率
        clock.tick(30)
        
        # 检查是否截断
        if truncated:
            break
    
    print(f"游戏结束，总奖励: {total_reward}")
    # 等待用户关闭窗口
    while True:
        if not human.update():
            break
        clock.tick(30)
    env.close()

if __name__ == "__main__":
    main()