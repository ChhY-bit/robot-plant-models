---
title: 机器人
sidebar: false
aside: false
prev: false
next: false
---

# 机器人模型 {#robot-models}

探索 MATLAB 仿真模型：每类模型具有自己的状态布局、执行器动态和指令接口。选择模型以查阅其 API。

<ModelCards />

另提供[四水箱容器](Quadruple-Tank/API-Reference/Introduction.md)：具有四个液位状态、两个水泵输入、可调阀门及附加扰动的被控对象。文档包含[属性](Quadruple-Tank/API-Reference/Properties.md)、[方法](Quadruple-Tank/API-Reference/Methods.md)、[参数工具函数](Quadruple-Tank/API-Reference/Utils.md)及[模型方程](Quadruple-Tank/Modeling/quadruple-tank-model.md)。

## 当前提供哪些内容？ {#what-is-available}

已有模型提供简介、属性和方法参考。四水箱方程已记录；机器人模型理论页面仍为后续详细推导预留，并标记为编写中。

这些是仿真用的被控对象模型，而非硬件驱动。指令用于设置机器人执行器目标或水箱水泵流量，仿真通过显式调用积分步进方法推进。
