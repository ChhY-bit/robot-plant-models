# 四水箱容器属性 {#quadruple-tank-properties}

> **提示：** 带 `'*'` 的小节表示私有属性。液位可公开读取，写入权限为私有。

## 1. 液位 {#1-water-levels}

### `x1`, `x2`, `x3`, `x4` {#water-levels}

分别表示水箱 1 至 4 的当前液位。水箱 1 和 2 位于下层；水箱 3 向水箱 1 排水，水箱 4 向水箱 2 排水。积分过程中的状态顺序为 `[x1; x2; x3; x4]`；对象没有单独存储的 `States` 属性。

- **类型：** 四个 `double` 标量，单位为 m。
- **默认值：** 每个液位均为 `0`。
- **约束：** 初始液位必须为有限、实数、非负数值。构造函数接受四元素行向量或列向量，赋值前统一转换为 double 列向量。
- **访问：** 通过 `tank.x1` 至 `tank.x4` 读取；外部不能直接赋值。`step()` 更新液位，并将最终结果截断在零以上。未配置液位上限。
- **另见：** [构造函数](Methods.md#rpm-quadruple-tank)、[积分](Methods.md#stepdt-t)。
- **用法：**

    ```matlab
    tank = rpm.quadruple_tank([], [0.1; 0.2; 0.3; 0.4]);
    levels = [tank.x1; tank.x2; tank.x3; tank.x4];
    output = [tank.x1; tank.x2];
    ```

## 2.* 物理参数 {#2-physical-parameters}

构造函数接受包含以下 11 个区分大小写字段的标量 `Params` 结构体。它会校验这些字段、将必需值转换为 `double`，再映射到各个私有属性。对象没有单独存储的 `Params` 属性，也没有公开的参数读取方法。结构体中的额外字段不会存入对象。

| YAML / `Params` 字段 | 私有属性 | 随附默认值 | 单位 | 约束 |
| --- | --- | --- | --- | --- |
| `TankArea_1` | `A1` | `2.8e-3` | m² | 正标量 |
| `TankArea_2` | `A2` | `3.2e-3` | m² | 正标量 |
| `TankArea_3` | `A3` | `2.8e-3` | m² | 正标量 |
| `TankArea_4` | `A4` | `3.2e-3` | m² | 正标量 |
| `HoleArea_1` | `a1` | `7.1e-6` | m² | 正标量 |
| `HoleArea_2` | `a2` | `5.7e-6` | m² | 正标量 |
| `HoleArea_3` | `a3` | `7.1e-6` | m² | 正标量 |
| `HoleArea_4` | `a4` | `5.7e-6` | m² | 正标量 |
| `g` | `g` | `9.81` | m/s² | 正标量 |
| `gamma_1` | `gamma_1` | `0.5` | 无量纲 | `[0, 1]` 内的标量 |
| `gamma_2` | `gamma_2` | `0.5` | 无量纲 | `[0, 1]` 内的标量 |

所有必需值均须为有限实数数值。`A1` 至 `A4` 为水箱截面积，`a1` 至 `a4` 为出水孔面积。默认值来自 `+rpm/config/quadruple_tank.yaml`。传入自定义结构体时，缺少字段会报错，不会逐项从默认文件补齐。

水泵 1 将 `gamma_1` 比例的流量送入水箱 1，将剩余 `1-gamma_1` 送入水箱 4。水泵 2 将 `gamma_2` 比例的流量送入水箱 2，将剩余 `1-gamma_2` 送入水箱 3。构造后可通过 [setValve](Methods.md#setvalvegamma_1-gamma_2) 修改分配比。其他物理参数在对象生命周期内固定；修改原始结构体或 YAML 文件不会更新已有对象。

```matlab
params = rpm.utils.load_quadruple_tank_params();
params.TankArea_1 = 3e-3;
tank = rpm.quadruple_tank(params);
tank.setValve(0.3, 0.7);
```

## 3.* 水泵输入 {#3-pump-inputs}

### `u1`, `u2` {#pump-inputs}

- **类型：** 两个 `double` 标量，单位为 `m^3/s`。
- **默认值：** 均为 `0`。
- **约束：** 有限、实数、非负数值标量。
- **行为：** 通过 [send](Methods.md#sendu1-u2) 设置，两个值保持到下一次成功调用。输入直接作为流量使用，没有水泵执行器动态或流量上限。两个输入均校验通过后才会更新属性。

## 4.* 扰动 {#4-disturbance}

### `disturbance`

- **类型：** `4x1 double`，顺序为 `[d1; d2; d3; d4]`，单位为 `m/s`。
- **默认值：** `[0; 0; 0; 0]`。
- **约束：** 四个有限实数数值元素，允许正数、负数及零。行向量会统一转换为列向量。
- **行为：** [addDisturbance](Methods.md#adddisturbanced) 替换当前保持的向量。扰动在每个 RK4 阶段直接加到四个液位导数上，并保持到下一次替换，不除以水箱面积。正值增大液位变化率，负值减小液位变化率。液位仍受零边界截断约束。

```matlab
tank.addDisturbance([1e-4; -1e-4; 0; 0]);
tank.addDisturbance(zeros(4, 1)); % Clear the held disturbance
```
