# 四水箱容器属性 {#quadruple-tank-properties}

> **提示：** 带 `'*'` 的小节表示私有属性。液位可公开读取，写入权限为私有。

## 1. 液位 {#1-water-levels}

### `x1`, `x2`, `x3`, `x4` {#water-levels}

分别表示水箱 1 至 4 的当前液位。水箱 1 和 2 位于下层；水箱 3 向水箱 1 排水，水箱 4 向水箱 2 排水。积分过程中的状态顺序为 `[x1; x2; x3; x4]`；对象没有单独存储的 `States` 属性。

- **类型：** 四个 `double` 标量，单位为 m。
- **默认值：** 每个液位均为 `0`。
- **约束：** 构造函数和 `reset()` 接受四元素有限实数行或列向量，各水位须在 `[0, 对应箱高]` 内，允许边界，超限报错，统一转换为 double 列向量。
- **访问：** 通过 `tank.x1` 至 `tank.x4` 读取，外部不能直接赋值。`step()` 将步末水位截断至 `[0, 对应箱高]`；`reset()` 可重新设置水位。
- **另见：** [构造函数](Methods.md#rpm-quadruple-tank)、[积分](Methods.md#stepdt-t)。
- **用法：**

    ```matlab
    tank = rpm.quadruple_tank([], [0.1; 0.2; 0.3; 0.4]);
    levels = [tank.x1; tank.x2; tank.x3; tank.x4];
    output = [tank.x1; tank.x2];
    ```

## 2.* 物理参数 {#2-physical-parameters}

构造函数要求以下 19 个区分大小写的字段。校验后，结构体保存在私有 `Params` 属性中，字段名与 YAML 一致。没有公开的参数读取方法。直接传入结构体时，额外字段会保留但不参与计算。

| 字段 | 含义 | 默认值 | 单位 | 约束 |
| --- | --- | --- | --- | --- |
| `TankArea_1` | 水箱 1 截面积 | `2.8` | m² | 正标量 |
| `TankArea_2` | 水箱 2 截面积 | `3.2` | m² | 正标量 |
| `TankArea_3` | 水箱 3 截面积 | `2.8` | m² | 正标量 |
| `TankArea_4` | 水箱 4 截面积 | `3.2` | m² | 正标量 |
| `HoleArea_1` | 水箱 1 出水孔面积 | `0.71` | m² | 正标量 |
| `HoleArea_2` | 水箱 2 出水孔面积 | `0.57` | m² | 正标量 |
| `HoleArea_3` | 水箱 3 出水孔面积 | `0.71` | m² | 正标量 |
| `HoleArea_4` | 水箱 4 出水孔面积 | `0.57` | m² | 正标量 |
| `g` | 重力加速度 | `9.81` | m/s² | 正标量 |
| `gamma_1` | 泵 1 分配比 | `0.5` | — | `[0, 1]` |
| `gamma_2` | 泵 2 分配比 | `0.5` | — | `[0, 1]` |
| `TankHeight_1` | 水箱 1 高度／水位上限 | `1.2` | m | 正标量 |
| `TankHeight_2` | 水箱 2 高度／水位上限 | `1.5` | m | 正标量 |
| `TankHeight_3` | 水箱 3 高度／水位上限 | `1.2` | m | 正标量 |
| `TankHeight_4` | 水箱 4 高度／水位上限 | `1.5` | m | 正标量 |
| `PumpMaxFlow_1` | 泵 1 分流前最大流量 | `0.05` | m³/s | 正标量 |
| `PumpMaxFlow_2` | 泵 2 分流前最大流量 | `0.05` | m³/s | 正标量 |
| `PumpFlowSpeed_1` | 泵 1 设计流速 | `1.0` | m/s | 正标量 |
| `PumpFlowSpeed_2` | 泵 2 设计流速 | `1.0` | m/s | 正标量 |

所有必需值均为有限实数数值标量，统一转换为 `double`。默认值来自 `+rpm/config/quadruple_tank.yaml`；缺少字段时报错，不逐项补齐。箱高用于初始水位检查和步末限幅；最大流量用于输入限幅。设计流速为最大流量下出口总管的平均流速，用于按 `S = Qmax / v` 推导抽象管道截面积，目前不参与动力学方程。

水泵 1 将 `gamma_1` 比例的流量送入水箱 1，将剩余 `1-gamma_1` 送入水箱 4。水泵 2 将 `gamma_2` 比例的流量送入水箱 2，将剩余 `1-gamma_2` 送入水箱 3。构造后可通过 [setValve](Methods.md#setvalvegamma_1-gamma_2) 修改分配比。其他物理参数在对象生命周期内固定；修改原始结构体或 YAML 文件不会更新已有对象。

```matlab
params = rpm.utils.load_quadruple_tank_params();
params.TankArea_1 = 3.0;
tank = rpm.quadruple_tank(params);
tank.setValve(0.3, 0.7);
```

## 3.* 水泵输入 {#3-pump-inputs}

### `u1`, `u2` {#pump-inputs}

- **类型：** 两个 `double` 标量，单位为 `m^3/s`。
- **默认值：** 均为 `0`。
- **约束：** 有限、实数、非负数值标量。
- **行为：** 通过 [send](Methods.md#sendu1-u2) 设置，两个值保持到下一次成功调用。输入直接作为流量使用，按对应 `PumpMaxFlow` 限幅，不包含水泵执行器动态；`reset()` 将输入清零。两个输入均校验通过后才会更新属性。

## 4.* 扰动 {#4-disturbance}

### `disturbance`

- **类型：** `4x1 double`，顺序为 `[d1; d2; d3; d4]`，单位为 `m/s`。
- **默认值：** `[0; 0; 0; 0]`。
- **约束：** 四个有限实数数值元素，允许正数、负数及零。行向量会统一转换为列向量。
- **行为：** [addDisturbance](Methods.md#adddisturbanced) 替换当前保持的向量。扰动在每个 RK4 阶段直接加到四个液位导数上，并保持到下一次替换，不除以水箱面积。正值增大液位变化率，负值减小液位变化率。液位仍受 `[0, 对应箱高]` 截断约束；`reset()` 清零扰动。

```matlab
tank.addDisturbance([1e-4; -1e-4; 0; 0]);
tank.addDisturbance(zeros(4, 1)); % Clear the held disturbance
```
