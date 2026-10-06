# 差速轮式机器人属性 {#wheel-robot-properties}

> **提示：** 带 `'*'` 的小节表示**私有**属性或方法。

## 1. `Metadata` {#1-metadata}

轮式机器人的基本信息，以公开结构体保存。这些字段不影响仿真，可以添加自定义字段；可通过构造函数的 `Metadata` 参数传入，也可通过 `robot.Metadata` 修改。构造函数要求标量结构体，并补齐缺失的默认字段，但不校验各个元数据字段的类型或内容。

### `Metadata.Name` {#metadataname}

用于在显示、日志或应用代码中识别机器人的描述性名称，不改变模型行为。

- **类型：** 用户自定义；通常与默认值一样使用 `char`。
- **默认值：** `'wheel_robot'`
- **另见：** [<u>方法 `rpm.wheel_robot()`</u>](Methods.md#rpm-wheel-robot)
- **用法：**
    ```matlab
    robot.Metadata.Name = 'WheelBot';
    ```

### `Metadata.Number` {#metadatanumber}

用于在多机器人应用中区分机器人的可选标识。模型不会自动分配或校验该标识，也不会在计算中使用它。

- **类型：** 用户自定义，例如 `char` 或数值标量（默认的 `[]` 是空 `double` 数组）。
- **默认值：** `[]`
- **另见：** [<u>方法 `rpm.wheel_robot()`</u>](Methods.md#rpm-wheel-robot)
- **用法：**
    ```matlab
    robot.Metadata.Number = '001';
    ```

### `Metadata.Description` {#metadatadescription}

自由填写的机器人说明，例如用途、硬件或配置。这是描述性元数据，不参与模型计算。

- **类型：** 用户自定义；通常与默认值一样使用 `char`。
- **默认值：** `'none'`
- **另见：** [<u>方法 `rpm.wheel_robot()`</u>](Methods.md#rpm-wheel-robot)
- **用法：**
    ```matlab
    robot.Metadata.Description = 'A two-wheel differential-drive robot.';
    ```

## 2.* `States` {#2-states}

向量顺序为 `[x; y; theta; left_wheel_angle; left_wheel_speed; right_wheel_angle; right_wheel_speed]`，对应理论记号 $[x, y, \theta, \alpha_L, \Omega_L, \alpha_R, \Omega_R]^\mathsf{T}$。

轮式机器人的动态状态，以私有 `7x1 double` 向量保存。通过构造函数的 `Ini_States` 参数或 `reset(ini_states)` 初始化，通过 `getStates()` 或各个读取方法获取。接受七元素、有限实数的数值行向量和列向量，并转换为 double 列向量。`step()` 对全部七个状态积分，包括车轮转角及一阶轮速响应。

每个车轮的转角和转速交错排列：索引 `4`、`5` 属于左轮，`6`、`7` 属于右轮。拼接 `[pose; wheel_angles; wheel_speeds]` 不符合此布局，应使用 `[pose; wheel_angles(1); wheel_speeds(1); wheel_angles(2); wheel_speeds(2)]`。

### `States(1)` `States(2)` {#states1-states2}

驱动轴中点在*世界坐标系*中的 x、y 位置，单位为米（m）。显示参数 `Params.axleOffset` 不改变位姿参考点。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `getPose()`</u>](Methods.md#getpose), [<u>方法 `getStates()`</u>](Methods.md#getstates)，以及 [<u>方法 `getPoseDot()`</u>](Methods.md#getposedot)

### `States(3)` {#states3}

*世界坐标系*中的航向角，单位为弧度（rad），从世界 x 轴起逆时针计量。默认持续累积、不归一化；启用 `Config.wrap_heading` 后，`step()` 会在积分结束时将其映射到 `[-pi, pi)`。构造函数及重置输入不会立即归一化。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `getPose()`</u>](Methods.md#getpose), [<u>方法 `setWrapHeading()`</u>](Methods.md#setwrapheadingwrap_heading)，以及 [<u>方法 `step()`</u>](Methods.md#stepdt-t)

### `States(4)` `States(6)` {#states4-states6}

分别为左右车轮的累计转角，单位为弧度（rad）。正向旋转表示向前滚动。各转角由实际轮速而非指令目标积分得到，永远不会按 `2*pi` 归一化，即使启用了航向角归一化。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `getWheelAngle()`</u>](Methods.md#getwheelangle), [<u>方法 `getWheelSpeed()`</u>](Methods.md#getwheelspeed)，以及 [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativez-u-t)

### `States(5)` `States(7)` {#states5-states7}

分别为左右车轮的实际角速度，单位为 rad/s。正值表示向前滚动。各轮通过对应 `motorTimeConstant` 的一阶响应跟踪各自保持的指令，因此可能与 `Cmd` 不同。

构造函数和 `reset()` 接受任何有限实数的初始轮速，包括超出 `Params.maxWheelSpeed` 的值。它们不会因轮速越界而拒绝或限幅；该参数仅限制指令目标。保持指令从零开始，因此非零初始轮速在未发送新目标时会衰减到零。积分后也不会单独对状态限幅。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `getWheelSpeed()`</u>](Methods.md#getwheelspeed), [<u>方法 `getVel()`</u>](Methods.md#getvel), [<u>方法 `reset()`</u>](Methods.md#resetini_states)，以及 [<u>方法 `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd)

## 3.* `Params` {#3-params}

轮式机器人的物理及显示参数，以私有标量结构体保存。下列七个字段均为必需字段，每个字段都对应大小写完全一致的顶层 YAML 键。例如，YAML 的 `wheelRadius: [0.10, 0.12]` 加载后成为 MATLAB 的 `params.wheelRadius = [0.10; 0.12]`；YAML 文件不包含外层 `Params:` 键。

构造函数的 `Params` 参数省略或为 `[]` 时，`rpm.utils.load_wheel_params()` 会读取项目的 `+rpm/config/wheel_robot.yaml`。如需使用自定义文件，调用 `rpm.utils.load_wheel_params(file_path)` 并将返回的结构体传入构造函数；也可手动创建包含全部七个字段的标量结构体。缺失字段会报错，不会从默认 YAML 中逐项补齐。

`wheelRadius`、`motorTimeConstant`、`maxWheelSpeed` 和 `wheelWidth` 可以使用标量表示两轮相同的数值，也可使用二元素行向量或列向量指定 `[left; right]`。加载函数和构造函数将这些字段规范为 `2x1 double` 向量，将 `bodySize` 规范为 `3x1 double` 向量，其余必需字段规范为 double 标量。加载函数保留零时间常数；构造函数会警告，并仅将零元素替换为 `1e-3` s。下文的**默认值**来自随附的 YAML 模板，而非构造函数中逐字段硬编码的默认值。

参数在构造时复制到对象中。之后修改 YAML 文件、原结构体或 `getParams()` 返回的副本，不会更新已有机器人。要应用新的物理参数，请创建新对象；`reset()` 保留原参数。手动传入结构体的额外字段会由构造函数保留，但 `rpm.utils.load_wheel_params()` 只返回七个已识别字段。YAML 参数文件不配置 `Metadata`、`States`、`Cmd` 或 `Config`。

例如，先导出模板，编辑数值，再加载：

```matlab
rpm.utils.export_wheel_params('my_wheel.yaml'); % Refuses to overwrite an existing file.
% Edit my_wheel.yaml before loading it.
params = rpm.utils.load_wheel_params('my_wheel.yaml');
params.wheelRadius = [0.08; 0.12]; % Optional in-memory override; does not edit the YAML.
robot = rpm.wheel_robot(params);
actual_params = robot.getParams();
```

自定义 YAML 应保持支持的扁平数值格式：`key: number` 或 `key: [number, ...]`。没有 `readyaml` 时，内置备用读取器不支持嵌套 YAML 或数值后的行内注释；请将注释单独写成一行。 自定义相对路径以 MATLAB 当前工作目录为基准解析。

### `Params.wheelRadius` {#paramswheelradius}

左右车轮的有效滚动半径，单位为米（m）。对应的线速度为 `r_L * Omega_L` 和 `r_R * Omega_R`。支持不同半径；只有有效半径也相等时，相同角速度才会产生直线运动。

- **类型：** `2x1 double` （接受标量或二元素行/列向量输入）
- **默认值：** `[0.10; 0.10]`
- **约束：** 两个有限、严格为正的实数元素。
- **YAML 键：** `wheelRadius`
- **另见：** [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativez-u-t), [<u>方法 `wheel2body()`</u>](Methods.md#wheel2bodywheel_speed)，以及 [<u>方法 `body2wheel()`</u>](Methods.md#body2wheelbody_velocity)

### `Params.trackWidth` {#paramstrackwidth}

左右车轮中心线之间的横向距离，单位为米（m）。它将车轮线速度差与驱动轴中点的横摆角速度关联起来：`omega = (r_R * Omega_R - r_L * Omega_L) / trackWidth`。

- **类型：** `double` 标量
- **默认值：** `0.45`
- **约束：** 有限实数，且严格为正。
- **YAML 键：** `trackWidth`
- **另见：** [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativez-u-t), [<u>方法 `kin_fwd()`</u>](Methods.md#kin_fwd)，以及 [<u>方法 `kin_inv()`</u>](Methods.md#kin_inv)

### `Params.motorTimeConstant` {#paramsmotortimeconstant}

左右轮速响应的时间常数，单位为秒（s）：`dOmega_i/dt = (Omega_i_cmd - Omega_i) / T_i`。数值越小，响应越快。对于恒定目标，连续模型经过一个时间常数后可消除约 63.2% 的初始速度误差。两侧时间常数不同时，即使指令对应的稳态线速度相等，也可能在过渡阶段发生转向。

- **类型：** `2x1 double` （接受标量或二元素行/列向量输入）
- **默认值：** `[0.15; 0.15]`
- **约束：** 两个有限非负实数元素。加载函数接受零值，但构造函数会发出 `wheel_robot:ZeroMotorTimeConstant`，并仅将零元素替换为 `1e-3` s，以近似理想执行器。
- **YAML 键：** `motorTimeConstant`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams), [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativez-u-t),，以及以下方法中的步长警告检查：[<u>方法 `step()`</u>](Methods.md#stepdt-t)

### `Params.maxWheelSpeed` {#paramsmaxwheelspeed}

左右车轮的最大目标角速度绝对值，单位为 rad/s，指车轮端而非减速器前电机轴的速度。`sendCmd()` 对各目标独立限幅到其对称范围。这是指令上限，而非实际状态的保证边界：初始轮速只要求是有限实数，数值积分也不对轮速状态限幅。

- **类型：** `2x1 double` （接受标量或二元素行/列向量输入）
- **默认值：** `[20.0; 20.0]`
- **约束：** 两个有限、严格为正的实数元素。
- **YAML 键：** `maxWheelSpeed`
- **另见：** [<u>方法 `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>方法 `getParams()`</u>](Methods.md#getparams)，以及 [<u>方法 `getWheelSpeed()`</u>](Methods.md#getwheelspeed)

### `Params.bodySize` {#paramsbodysize}

不包含车轮的主体包围盒尺寸，单位为米（m），顺序为 `[length; width; height]`。这是显示几何参数，不影响当前运动方程。

- **类型：** `3x1 double` （接受三元素行向量或列向量输入）
- **默认值：** `[0.60; 0.40; 0.20]`
- **约束：** 三个有限、严格为正的实数元素。
- **YAML 键：** `bodySize`；YAML 中写为 `bodySize: [0.60, 0.40, 0.20]`，并规范为列向量。
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams) 和 [<u>方法 `getParams()`</u>](Methods.md#getparams)，用于外部渲染或几何计算

### `Params.wheelWidth` {#paramswheelwidth}

左右车轮沿轮轴方向的宽度，单位为米（m）。这是显示几何参数，不影响轮速或位姿方程。

- **类型：** `2x1 double` （接受标量或二元素行/列向量输入）
- **默认值：** `[0.05; 0.05]`
- **约束：** 两个有限、严格为正的实数元素。
- **YAML 键：** `wheelWidth`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams) 和 [<u>方法 `getParams()`</u>](Methods.md#getparams)，用于外部渲染或几何计算

### `Params.axleOffset` {#paramsaxleoffset}

驱动轴中点相对车体几何中心、沿车体前进轴的有符号纵向偏移，单位为米（m）。正值表示驱动轴位于车体中心前方，负值表示位于后方。此显示几何参数用于确定车体相对位姿参考点的位置，不改变运动方程使用的参考点。

- **类型：** `double` 标量
- **默认值：** `0.0`
- **约束：** 任意有限实数标量；允许正值、负值和零。
- **YAML 键：** `axleOffset`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams) 和 [<u>方法 `getParams()`</u>](Methods.md#getparams)，用于外部渲染或几何计算

## 4.* `Cmd` {#4-cmd}

保存最近一次限幅后左右轮速指令的私有标量结构体，字段为 `left` 和 `right`。`getCmd()` 将其值以向量 `[left_wheel_cmd; right_wheel_cmd]` 返回，对应理论记号 $[\Omega_{L,\mathrm{cmd}}, \Omega_{R,\mathrm{cmd}}]^\mathsf{T}$。

`sendCmd()` 更新该结构体，每次 `step()` 都使用相同的保持值，直到下一次发送或重置。构造函数和 `reset()` 将两个字段初始化为零，即使初始轮速非零。发送指令只改变目标，不立即改变实际状态或位姿。

### `Cmd.left` `Cmd.right` {#cmdleft-cmdright}

分别为左右车轮的目标角速度，单位为 rad/s，正值表示向前滚动。各输入独立限幅到 `[-Params.maxWheelSpeed(i), Params.maxWheelSpeed(i)]`；实际轮速通过各自一阶响应逐渐接近保持目标。

- **类型：** `double` ，每个字段均为标量
- **默认值：** `0` ，每个字段均适用
- **另见：** [<u>方法 `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>方法 `getCmd()`</u>](Methods.md#getcmd)，以及 [<u>方法 `step()`</u>](Methods.md#stepdt-t)

## 5.* `Config` {#5-config}

私有仿真配置结构体，由构造函数初始化并在 `reset()` 时保留。通过下列公开设置方法修改。这些选项不从物理参数 YAML 文件中读取。

### `Config.solution_method` {#configsolution_method}

`step()` 推进全部七个状态时使用的固定步长积分方法。`'euler'` 表示显式欧拉法，`'RK4'` 表示经典四阶 Runge-Kutta 法。`setSolutionMethod()` 接受字符行向量或字符串标量，不区分大小写，并保存规范拼写。成功调用会清除步长警告标记，不改变状态或保持指令。

- **类型：** `char`
- **默认值：** `'RK4'`
- **另见：** [<u>方法 `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method) 和 [<u>方法 `step()`</u>](Methods.md#stepdt-t)

### `Config.wrap_heading` {#configwrap_heading}

是否在每次完整积分步结束后，将航向角归一化到 `[-pi, pi)`。`false` 保留累计航向，`true` 丢弃完整转圈数。设置该选项不会立即改变航向；之后禁用它也不会恢复已丢弃的转圈数。 两个车轮的转角不受影响，始终持续累积、不归一化。

- **类型：** `logical` 标量
- **默认值：** `false`
- **另见：** [<u>方法 `setWrapHeading()`</u>](Methods.md#setwrapheadingwrap_heading), [<u>方法 `step()`</u>](Methods.md#stepdt-t)，以及 [<u>方法 `getWheelAngle()`</u>](Methods.md#getwheelangle)

### `Config.warn_on_saturation` {#configwarn_on_saturation}

`sendCmd()` 对一个或两个越界目标限幅时，是否每次都发出 `wheel_robot:CommandSaturated` 警告。禁用此选项仅抑制该警告，仍会执行限幅，零时间常数和大步长警告不受影响。

- **类型：** `logical` 标量
- **默认值：** `true`
- **另见：** [<u>方法 `setWarnOnSaturation()`</u>](Methods.md#setwarnonsaturationwarn_on_saturation) 和 [<u>方法 `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd)

## 6.* `StepSizeWarningActive` {#6-stepsizewarningactive}

用于避免连续大步长调用重复警告的私有标记。`step()` 计算 `ratio = max(dt ./ Params.motorTimeConstant)`。当 `ratio > 0.1` 时，仅在该标记原为 `false` 时发出 `wheel_robot:LargeStepSize`，随后置为 `true`。之后处于警告范围的步长保持静默，即使步长值发生变化。执行 `ratio <= 0.1` 的一步会清除标记，允许后续大步长再次发出警告。

- **类型：** `logical` 标量
- **默认值：** `false`
- **另见：** [<u>方法 `step()`</u>](Methods.md#stepdt-t)检查并更新它；[<u>方法 `reset()`</u>](Methods.md#resetini_states)和成功执行的 [<u>方法 `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method)会清除它。构造函数通过以下方法初始化它：[<u>方法 `reset()`</u>](Methods.md#resetini_states).

---
