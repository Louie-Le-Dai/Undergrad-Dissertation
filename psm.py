import numpy as np
import matplotlib.pyplot as plt


# 设置支持中文的字体
plt.rcParams['font.sans-serif'] = ['SimHei']  # 使用黑体
plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题
plt.rcParams["font.family"] = "Times New Roman"  # 设置全局字体为 Times New Roman

# 模拟数据
x_labels = ["pre_3", "pre_2", "pre_1", "current", "post_1", "post_2", "post_3", "post_4", "post_5"]
x = np.arange(len(x_labels))  # x 轴数值索引

# 模拟政策效应估计值 (ATE)
y = np.array([-0.02, -0.015, 0.00, 0.025, 0.015, 0.023, 0.025, 0.028, 0.019])  

# 模拟误差棒（标准误）
yerr = np.array([0.025, 0.02, 0.00, 0.020, 0.020, 0.020, 0.021, 0.021, 0.026])  

# 创建图形
fig, ax = plt.subplots(figsize=(6, 4), dpi=500)

# 画误差棒图
ax.errorbar(x, y, yerr=yerr, fmt='o', color='black', ecolor='black', capsize=4, linestyle='-', markerfacecolor='white')

# 添加参考线
ax.axhline(y=0, color='gray', linestyle='dashed')  # 横轴零线
ax.axvline(x=3, color='gray', linestyle='dashed')  # 事件发生时间点

ax.set_xticks(x)
ax.set_xticklabels(x_labels)

# 设定标签和标题
ax.set_xlabel("Year")
ax.set_ylabel("ATE")

ax.spines['right'].set_visible(False)  # 隐藏右边框
ax.spines['top'].set_visible(False)  # 隐藏上边框

# 显示图形
plt.show()
