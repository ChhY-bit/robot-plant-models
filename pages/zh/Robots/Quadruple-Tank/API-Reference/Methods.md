# 四水箱容器方法 {#quadruple-tank-methods}

> **提示：** 带 `'*'` 的小节表示私有方法。

## 1. 初始化 {#1-initialization}

### `rpm.quadruple_tank(Params, Ini_States)` {#rpm-quadruple-tank}

创建具有独立物理参数和液位的新 `handle` 对象。水泵输入与扰动从零开始。参数省略或为 `[]` 时，分别使用随附 YAML 参数和四个零液位。构造过程不推进时间。

- **参数：**
    - `Params`（可选）：包含全部 19 个[物理参数字段](Properties.md#2-physical-parameters)的标量结构体，或 `[]`。除阀门分配比外，其余字段须为有限实数正数值标量；阀门分配比须为 `[0, 1]` 内的有限实数数值标量。
    - `Ini_States`（可选）：四元素有限、实数、非负数值行向量或列向量，或 `[]`；顺序为 `[x1; x2; x3; x4]`，单位为 m，统一转换为 `4x1 double`。初始水位须不超过对应 `TankHeight`，允许等于箱高。
- **返回值：** `obj`，`rpm.quadruple_tank` handle 对象。
- **另见：** [参数加载器](Utils.md#rpm-utils-load-quadruple-tank-params)、[液位](Properties.md#1-water-levels)。
- **用法：**

    ```matlab
    tank = rpm.quadruple_tank();
    params = rpm.utils.load_quadruple_tank_params();
    params.gamma_1 = 0.3;
    tank = rpm.quadruple_tank(params, [0.1, 0.1, 0.1, 0.1]);
    ```

缺少必需字段会抛出 `quadruple_tank:MissingParameter`；非法形状、类型及取值范围由 MATLAB 属性校验拒绝。参数保存于私有 `Params` 结构体，字段名与 YAML 一致。初始水位超出箱高时报 `quadruple_tank:InvalidInitialState`。通过 `reset()` 可重新开始。

### `reset(Ini_States)` {#resetini_states}

复位水位，并清零水泵输入与保持的扰动，保留 `Params`，包括当前阀门分配比。

- **参数：** `Ini_States`（可选）：四元素有限实数行或列向量，顺序为 `[x1; x2; x3; x4]`，单位 m。省略或传 `[]` 时归零。各水位必须在 `[0, 对应箱高]` 内，允许边界；超限报错，不自动截断。
- **返回值：** 无。
- **行为：** 与构造函数共用 `validateInitialStates()`。检查通过后才更新对象；非法输入不会改变原有水位、输入或扰动。
- **用法：**

```matlab
tank.reset([0.1; 0.2; 0.3; 0.4]);
tank.reset();
```

## 2. 水泵输入 {#2-pump-inputs}

### `send(u1, u2)` {#sendu1-u2}

替换两个保持的水泵流量。设置值在后续积分步中持续有效。两个输入均检查通过后才会更新任一属性，因此调用被拒绝时会保留原输入。

- **参数：** `u1`、`u2`：有限、实数、非负数值标量，单位为 `m^3/s`；存储为 `double`。
- **返回值：** 无。
- **另见：** [水泵输入](Properties.md#3-pump-inputs)、[积分](#stepdt-t)。
- **用法：**

    ```matlab
    tank.send(1e-5, 2e-5);
    tank.step(0.01, 0);
    tank.send(0, 0); % Stop both pumps; existing water can still drain
    ```

此方法调用 `validateAndLimitInput()` 校验输入并规范为 double。负流量被拒绝；超过对应 `PumpMaxFlow_1/2` 的输入限幅至最大值。不进行积分，没有水泵电压换算或一阶执行器响应。

## 3. 阀门设置 {#3-valve-settings}

### `setValve(gamma_1, gamma_2)` {#setvalvegamma_1-gamma_2}

替换后续积分使用的阀门分配比。两个值均校验通过后才会更新任一属性；液位与水泵输入保持不变。

- **参数：** `gamma_1`、`gamma_2`：`[0, 1]` 内的有限实数数值标量，允许端点；存储为 `double`。
- **返回值：** 无。
- **另见：** [物理参数](Properties.md#2-physical-parameters)、[流路连接](../Modeling/quadruple-tank-model.md#1-flow-connections)。
- **用法：**

    ```matlab
    tank.setValve(0.3, 0.7);
    tank.setValve(1, 1); % Both pumps feed only their lower tanks
    ```

`gamma_1` 表示水泵 1 分配给水箱 1 的比例，其余流向水箱 4。`gamma_2` 表示水泵 2 分配给水箱 2 的比例，其余流向水箱 3。设置比例不会立即改变液位。

## 4. 扰动 {#4-disturbance}

### `addDisturbance(d)` {#adddisturbanced}

设置保持的附加液位变化率扰动。虽然方法名包含 `add`，每次调用都会**替换**向量，而非与原来存储的值累加。扰动持续有效，直到再次替换。

- **参数：** `d`：四元素有限实数数值行向量或列向量，顺序为 `[d1; d2; d3; d4]`，单位为 `m/s`；统一转换为 `4x1 double`。允许正数、负数及零。
- **返回值：** 无。
- **另见：** [扰动属性](Properties.md#4-disturbance)、[状态方程](../Modeling/quadruple-tank-model.md#2-state-equations)。
- **用法：**

    ```matlab
    tank.addDisturbance([1e-4, -1e-4, 0, 0]);
    tank.step(0.01, 0);
    tank.addDisturbance(zeros(4, 1)); % Cancel the disturbance
    ```

向量直接加到 `dz`，不除以面积。在一个积分步及其所有 RK4 阶段中，扰动保持不变。如需分段常值扰动，应在受影响的每个积分步之前设置新值。调用被拒绝时，原扰动保持不变。

## 5. 积分 {#5-integration}

### `step(dt, t)` {#stepdt-t}

使用保持的水泵输入、当前阀门分配比和保持的扰动，以经典四阶 Runge–Kutta（RK4）推进四个液位一个积分步。方法直接更新对象，不返回状态向量；调用后读取 `tank.x1` 至 `tank.x4`。

- **参数：**
    - `dt`：必须为正的有限实数数值标量积分间隔，单位为 s。
    - `t`：必须为有限实数数值标量步起始时间，单位为 s。`dt` 和 `t` 均须提供，没有默认时间参数。
- **返回值：** 无。
- **另见：** [液位](Properties.md#1-water-levels)、[边界处理](../Modeling/quadruple-tank-model.md#3-numerical-integration)。
- **用法：**

    ```matlab
    dt = 0.01;
    for k = 1:1000
        tank.step(dt, (k - 1) * dt);
    end
    levels = [tank.x1; tank.x2; tank.x3; tank.x4];
    ```

`validateStepArguments()` 在积分前校验 `dt` 和 `t` 并转换为 double；校验失败时水位不变。不存储或累加仿真时钟。各阶段时间会传给 `stateDerivative`，但当前导数不显式使用时间。

每次计算导数时，先将传入液位截断在零以上，再计算平方根。最终结果由 `limitStates()` 截断至 `[0, 对应箱高]`，RK4 中间阶段仍可能超过箱高。这可避免合法物理输入下对负液位开平方，但不能保证空箱附近的积分精度或严格体积守恒，必要时应减小步长。未实现自适应步长或显式溢流模型，步末上限截断不追踪多余水量的去向。

## 6.* 内部方法 {#6-internal-methods}

### `validateParams(Params)` {#validateparamsparams}

要求输入为标量结构体并包含全部 19 个物理字段，校验标量类型与范围，将必需值转换为 `double`。即使传入手动构造的结构体，构造函数也会调用此方法。该私有辅助方法不加载文件，也不修改已有对象的参数。

### `stateDerivative(z, u, t)` {#statederivativez-u-t}

根据 `z = [x1; x2; x3; x4]`、`u = [u1; u2]`、物理参数及保持的扰动，计算单位为 `m/s` 的 `4x1` 液位导数。计算流量前将 `z` 截断在零以上，最后叠加扰动，不修改对象存储的液位。参数 `t` 当前未使用。另见[状态方程](../Modeling/quadruple-tank-model.md#2-state-equations)。


以下辅助函数只返回校验或限幅结果，不修改对象属性。

### `validateStepArguments(dt, t)` {#validatestepargumentsdt-t}

校验正步长和有限实数起始时间，规范为 double 标量。

### `validateInitialStates(Ini_States)` {#validateinitialstatesini_states}

校验四元素初始水位及各自箱高上限，规范为 4x1 double。构造函数通过 reset 共用此检查。

### `validateAndLimitInput(u1, u2)` {#validateandlimitinputu1-u2}

先校验两个非负有限实数标量，再按各泵最大流量限幅并转换为 double。

### `validateValve(gamma_1, gamma_2)` {#validatevalvegamma_1-gamma_2}

校验两个分配比在 [0, 1] 内并转换为 double 标量。

### `validateDisturbance(d)` {#validatedisturbanced}

校验四元素有限实数扰动，允许正负，规范为 4x1 double。

### `limitStates(States)` {#limitstatesstates}

将内部积分结果逐元素截断至 [0, 对应箱高]，不用于初始水位校验。
