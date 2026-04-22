import gymnasium as gym
import pygame
import numpy as np
import random
from gymnasium.spaces import Box, MultiDiscrete

class DuelGameEnv(gym.Env):
    """决斗游戏环境"""
    metadata = {"render_modes": ["human", "rgb_array"], "render_fps": 30}
    
    def __init__(self, render_mode=None, max_steps=3000):
        super().__init__()
        
        # 游戏参数
        self.screen_width = 480
        self.screen_height = 320
        self.player_size = 20
        self.enemy_size = 20
        self.bullet_size = 5
        self.player_speed = 5
        self.enemy_speed = 3
        self.bullet_speed = 7
        self.player_health = 100
        self.enemy_health = 100
        self.max_steps = max_steps
        self.current_step = 0
        
        # 动作空间：[移动, 开火]
        # 移动: 0-静止, 1-上, 2-下, 3-左, 4-右
        # 开火: 0-不操作, 1-普通攻击, 2-特殊攻击
        self.action_space = MultiDiscrete([5, 3])
        
        # 状态空间：4帧灰度图像，大小为84x84
        self.observation_space = Box(low=0, high=255, shape=(4, 84, 84), dtype=np.uint8)
        
        # 渲染模式
        self.render_mode = render_mode
        self.screen = None
        self.clock = None
        
        # 游戏元素
        self.player = None
        self.enemy = None
        self.player_bullets = []
        self.enemy_bullets = []
        self.player_special_cooldown = 0
        self.enemy_special_cooldown = 0
        self.special_cooldown_max = 100
        
        # 奖励相关
        self.reward = 0
        self.done = False
        self.truncated = False
        
        # 帧缓冲区，用于帧堆叠
        self.frame_buffer = []
    
    def reset(self, seed=None, options=None):
        """重置环境"""
        super().reset(seed=seed)
        
        # 初始化游戏元素
        self.player = {
            "pos": np.array([self.screen_width // 4, self.screen_height // 2]),
            "health": self.player_health,
            "direction": np.array([1, 0])  # 初始朝向右
        }
        
        self.enemy = {
            "pos": np.array([3 * self.screen_width // 4, self.screen_height // 2]),
            "health": self.enemy_health,
            "direction": np.array([-1, 0])  # 初始朝向左
        }
        
        self.player_bullets = []
        self.enemy_bullets = []
        self.player_special_cooldown = 0
        self.enemy_special_cooldown = 0
        self.current_step = 0
        self.reward = 0
        self.done = False
        self.truncated = False
        
        # 初始化帧缓冲区
        self.frame_buffer = []
        
        # 渲染初始帧并处理
        obs = self._get_observation()
        
        return obs, {}
    
    def step(self, action):
        """执行一步游戏逻辑"""
        self.reward = 0
        self.current_step += 1
        
        # 处理玩家动作
        self._handle_player_action(action)
        
        # 处理敌人动作（AI控制）
        self._handle_enemy_action()
        
        # 更新子弹
        self._update_bullets()
        
        # 检测碰撞
        self._check_collisions()
        
        # 减少冷却时间
        if self.player_special_cooldown > 0:
            self.player_special_cooldown -= 1
        if self.enemy_special_cooldown > 0:
            self.enemy_special_cooldown -= 1
        
        # 检查终止条件
        if self.player["health"] <= 0:
            self.done = True
            self.reward -= 10.0
        elif self.enemy["health"] <= 0:
            self.done = True
            self.reward += 10.0
        
        if self.current_step >= self.max_steps:
            self.truncated = True
        
        # 获取观察
        obs = self._get_observation()
        
        return obs, self.reward, self.done, self.truncated, {}
    
    def render(self):
        """渲染游戏画面"""
        if self.render_mode is None:
            return
        
        if self.screen is None:
            pygame.init()
            self.screen = pygame.display.set_mode((self.screen_width, self.screen_height))
            pygame.display.set_caption("Duel Game AI")
            self.clock = pygame.time.Clock()
        
        # 填充背景
        self.screen.fill((30, 30, 30))
        
        # 绘制玩家
        pygame.draw.rect(self.screen, (0, 150, 255), 
                        pygame.Rect(self.player["pos"][0] - self.player_size // 2, 
                                   self.player["pos"][1] - self.player_size // 2, 
                                   self.player_size, self.player_size))
        
        # 绘制敌人
        pygame.draw.rect(self.screen, (255, 50, 50), 
                        pygame.Rect(self.enemy["pos"][0] - self.enemy_size // 2, 
                                   self.enemy["pos"][1] - self.enemy_size // 2, 
                                   self.enemy_size, self.enemy_size))
        
        # 绘制子弹
        for bullet in self.player_bullets:
            pygame.draw.circle(self.screen, (0, 255, 0), 
                              (int(bullet["pos"][0]), int(bullet["pos"][1])), 
                              self.bullet_size)
        
        for bullet in self.enemy_bullets:
            pygame.draw.circle(self.screen, (255, 255, 0), 
                              (int(bullet["pos"][0]), int(bullet["pos"][1])), 
                              self.bullet_size)
        
        # 显示生命值
        font = pygame.font.Font(None, 24)
        player_health_text = font.render(f"Player: {self.player['health']}", True, (255, 255, 255))
        enemy_health_text = font.render(f"Enemy: {self.enemy['health']}", True, (255, 255, 255))
        self.screen.blit(player_health_text, (10, 10))
        self.screen.blit(enemy_health_text, (self.screen_width - 100, 10))
        
        # 显示步数和奖励
        step_text = font.render(f"Step: {self.current_step}", True, (255, 255, 255))
        reward_text = font.render(f"Reward: {self.reward:.2f}", True, (255, 255, 255))
        self.screen.blit(step_text, (10, 40))
        self.screen.blit(reward_text, (10, 70))
        
        if self.render_mode == "human":
            pygame.display.flip()
            self.clock.tick(self.metadata["render_fps"])
        
        if self.render_mode == "rgb_array":
            return pygame.surfarray.array3d(self.screen)
    
    def close(self):
        """关闭环境"""
        if self.screen is not None:
            pygame.quit()
            self.screen = None
    
    def _get_observation(self):
        """获取观察（处理后的图像）"""
        # 渲染当前帧
        self.render()
        
        # 获取屏幕像素
        screen_array = pygame.surfarray.array3d(self.screen)
        
        # 转换为灰度图
        gray_array = np.mean(screen_array, axis=2, dtype=np.uint8)
        
        # 调整大小为84x84
        import cv2
        resized_array = cv2.resize(gray_array, (84, 84), interpolation=cv2.INTER_AREA)
        
        # 添加到帧缓冲区
        self.frame_buffer.append(resized_array)
        
        # 保持缓冲区大小为4
        if len(self.frame_buffer) > 4:
            self.frame_buffer.pop(0)
        
        # 如果缓冲区不足4帧，重复填充
        while len(self.frame_buffer) < 4:
            self.frame_buffer.insert(0, np.zeros((84, 84), dtype=np.uint8))
        
        # 堆叠帧
        obs = np.stack(self.frame_buffer, axis=0)
        
        return obs
    
    def _handle_player_action(self, action):
        """处理玩家动作"""
        move_action, fire_action = action
        
        # 处理移动
        directions = {
            0: [0, 0],      # 静止
            1: [0, -1],     # 上
            2: [0, 1],      # 下
            3: [-1, 0],     # 左
            4: [1, 0]       # 右
        }
        
        move_dir = np.array(directions[move_action])
        if np.any(move_dir):
            # 更新位置
            self.player["pos"] = self.player["pos"] + move_dir * self.player_speed
            
            # 更新朝向
            if move_dir[0] != 0:
                self.player["direction"][0] = move_dir[0]
            
            # 边界检查
            self.player["pos"][0] = max(self.player_size // 2, min(self.screen_width - self.player_size // 2, self.player["pos"][0]))
            self.player["pos"][1] = max(self.player_size // 2, min(self.screen_height - self.player_size // 2, self.player["pos"][1]))
        
        # 处理开火
        if fire_action == 1:  # 普通攻击
            # 创建子弹
            bullet = {
                "pos": np.copy(self.player["pos"]),
                "dir": np.copy(self.player["direction"])
            }
            self.player_bullets.append(bullet)
        elif fire_action == 2:  # 特殊攻击
            if self.player_special_cooldown == 0:
                # 发射多方向子弹
                for angle in range(0, 360, 45):
                    rad = np.radians(angle)
                    bullet = {
                        "pos": np.copy(self.player["pos"]),
                        "dir": np.array([np.cos(rad), np.sin(rad)])
                    }
                    self.player_bullets.append(bullet)
                self.player_special_cooldown = self.special_cooldown_max
            else:
                # 无效开火惩罚
                self.reward -= 0.1
    
    def _handle_enemy_action(self):
        """处理敌人动作（AI控制）"""
        # 简单的AI逻辑
        
        # 移动逻辑：向玩家方向移动
        dir_to_player = self.player["pos"] - self.enemy["pos"]
        if np.linalg.norm(dir_to_player) > 0:
            dir_to_player = dir_to_player / np.linalg.norm(dir_to_player)
            # 只在水平方向移动
            move_dir = np.array([dir_to_player[0], 0])
            if np.any(move_dir):
                self.enemy["pos"] = self.enemy["pos"] + move_dir * self.enemy_speed
                
                # 更新朝向
                if move_dir[0] != 0:
                    self.enemy["direction"][0] = move_dir[0]
                
                # 边界检查
                self.enemy["pos"][0] = max(self.enemy_size // 2, min(self.screen_width - self.enemy_size // 2, self.enemy["pos"][0]))
                self.enemy["pos"][1] = max(self.enemy_size // 2, min(self.screen_height - self.enemy_size // 2, self.enemy["pos"][1]))
        
        # 开火逻辑：随机开火
        if random.random() < 0.05:
            # 普通攻击
            bullet = {
                "pos": np.copy(self.enemy["pos"]),
                "dir": np.copy(self.enemy["direction"])
            }
            self.enemy_bullets.append(bullet)
        elif random.random() < 0.01 and self.enemy_special_cooldown == 0:
            # 特殊攻击
            for angle in range(0, 360, 60):
                rad = np.radians(angle)
                bullet = {
                    "pos": np.copy(self.enemy["pos"]),
                    "dir": np.array([np.cos(rad), np.sin(rad)])
                }
                self.enemy_bullets.append(bullet)
            self.enemy_special_cooldown = self.special_cooldown_max
    
    def _update_bullets(self):
        """更新子弹位置"""
        # 更新玩家子弹
        for bullet in self.player_bullets[:]:
            bullet["pos"] = bullet["pos"] + bullet["dir"] * self.bullet_speed
            # 检查是否超出屏幕
            if (bullet["pos"][0] < 0 or bullet["pos"][0] > self.screen_width or
                bullet["pos"][1] < 0 or bullet["pos"][1] > self.screen_height):
                self.player_bullets.remove(bullet)
        
        # 更新敌人子弹
        for bullet in self.enemy_bullets[:]:
            bullet["pos"] = bullet["pos"] + bullet["dir"] * self.bullet_speed
            # 检查是否超出屏幕
            if (bullet["pos"][0] < 0 or bullet["pos"][0] > self.screen_width or
                bullet["pos"][1] < 0 or bullet["pos"][1] > self.screen_height):
                self.enemy_bullets.remove(bullet)
    
    def _check_collisions(self):
        """检查碰撞"""
        # 玩家子弹与敌人碰撞
        for bullet in self.player_bullets[:]:
            distance = np.linalg.norm(bullet["pos"] - self.enemy["pos"])
            if distance < (self.enemy_size // 2 + self.bullet_size):
                # 命中敌人
                self.reward += 1.0
                self.enemy["health"] -= 10
                self.player_bullets.remove(bullet)
        
        # 敌人子弹与玩家碰撞
        for bullet in self.enemy_bullets[:]:
            distance = np.linalg.norm(bullet["pos"] - self.player["pos"])
            if distance < (self.player_size // 2 + self.bullet_size):
                # 玩家被击中
                self.reward -= 1.0
                self.player["health"] -= 10
                self.enemy_bullets.remove(bullet)
        
        # 玩家与敌人碰撞
        distance = np.linalg.norm(self.player["pos"] - self.enemy["pos"])
        if distance < (self.player_size // 2 + self.enemy_size // 2):
            # 双方都受到伤害
            self.reward -= 2.0
            self.player["health"] -= 5
            self.enemy["health"] -= 5