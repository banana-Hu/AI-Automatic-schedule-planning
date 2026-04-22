import os
import numpy as np
import torch
from stable_baselines3 import PPO
from stable_baselines3.common.vec_env import DummyVecEnv
from game_ai import DuelGameEnv

# 训练参数
TRAINING_TIMESTEPS = 1000000  # 训练步数
LEARNING_RATE = 3e-4  # 学习率
BATCH_SIZE = 64  # 批量大小
GAMMA = 0.99  # 折扣因子
N_EPOCHS = 4  # 每个批次的训练轮数
CLIP_RANGE = 0.2  # PPO 裁剪范围
SAVE_INTERVAL = 100000  # 保存模型的间隔

# 模型保存目录
MODEL_DIR = "game_models"
if not os.path.exists(MODEL_DIR):
    os.makedirs(MODEL_DIR)

def make_env():
    """创建环境"""
    def _init():
        env = DuelGameEnv(render_mode=None)  # 无头渲染，用于训练
        return env
    return _init

def main():
    """主函数"""
    print("开始训练决斗游戏AI...")
    
    # 创建环境
    env = DummyVecEnv([make_env()])
    
    # 检查是否有可用的 GPU
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"使用设备: {device}")
    
    # 创建 PPO 模型，使用 CNN 策略
    model = PPO(
        "CnnPolicy",
        env,
        learning_rate=LEARNING_RATE,
        n_steps=2048,
        batch_size=BATCH_SIZE,
        n_epochs=N_EPOCHS,
        gamma=GAMMA,
        clip_range=CLIP_RANGE,
        verbose=1,
        device=device
    )
    
    # 开始训练
    print(f"开始训练，总步数: {TRAINING_TIMESTEPS}")
    model.learn(
        total_timesteps=TRAINING_TIMESTEPS,
        callback=lambda locals_, globals_: save_model(model, locals_['self'].num_timesteps)
    )
    
    # 保存最终模型
    model.save(os.path.join(MODEL_DIR, "duel_game_final"))
    print("训练完成，模型已保存")
    
    # 关闭环境
    env.close()

def save_model(model, timesteps):
    """保存模型"""
    if timesteps % SAVE_INTERVAL == 0:
        model_path = os.path.join(MODEL_DIR, f"duel_game_{timesteps}")
        model.save(model_path)
        print(f"模型已保存到: {model_path}")

if __name__ == "__main__":
    main()