# 阿克曼机器人属性 {#ackermann-robot-properties}

> **提示：** 带 `'*'` 的小节表示**私有**属性或方法。

## 1. `Metadata` {#1-metadata}

阿克曼机器人的基本信息，以公开结构体保存。这些字段不影响仿真，可以添加自定义字段；可通过构造函数的 `Metadata` 参数传入，也可通过 `robot.Metadata` 修改。

### `Metadata.Name` {#metadataname}

用于在显示、日志或应用代码中识别机器人的描述性名称，不改变模型行为。

- **类型：** `char`
- **默认值：** `'ackermann_robot'`
- **另见：** [<u>方法 `rpm.ackermann_robot()`</u>](Methods.md#rpm-ackermann-robot)
- **用法：**
    ```matlab
    robot.Metadata.Name = 'AckerBot';
    ```

### `Metadata.Number` {#metadatanumber}

用于在多机器人应用中区分机器人的可选标识。模型不会自动分配或校验该标识，也不会在计算中使用它。

- **类型：** 用户自定义，例如 `char`（默认的 `[]` 是空 `double` 数组）。
- **默认值：** `[]`
- **另见：** [<u>方法 `rpm.ackermann_robot()`</u>](Methods.md#rpm-ackermann-robot)
- **用法：**
    ```matlab
    robot.Metadata.Number = '0';
    ```

### `Metadata.Description` {#metadatadescription}

自由填写的机器人说明，例如用途、硬件或配置。这是描述性元数据，不参与模型计算。

- **类型：** `char`
- **默认值：** `'none'`
- **另见：** [<u>方法 `rpm.ackermann_robot()`</u>](Methods.md#rpm-ackermann-robot)
- **用法：**
    ```matlab
    robot.Metadata.Description = 'AckerBot is a robot with ackermann steering.';
    ```

## 2.* `States` {#2-states}

向量顺序为 `[x; y; theta; delta; Omega]`，对应理论记号 $[x, y, \theta, \delta, \Omega]^\mathsf{T}$。

阿克曼机器人的动态状态，以私有 `5x1 double` 向量保存。通过构造函数的 `Ini_States` 参数或 `reset(ini_states)` 初始化，通过 `getStates()` 或各个读取方法获取。接受五元素行向量和列向量，并转换为列向量。`step()` 对这些状态积分；实际前轮转角和四轮转速由它们计算，而非独立积分。

### `States(1)` `States(2)` {#states1-states2}

后轴中点在*世界坐标系*中的 x、y 位置，单位为米（m）。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `getPose()`</u>](Methods.md#getpose)

### `States(3)` {#states3}

*世界坐标系*中的航向角，单位为弧度（rad），从世界 x 轴起逆时针计量。默认持续累积、不归一化；启用 `Config.wrap_heading` 后，`step()` 会在积分结束时将其映射到 `[-pi, pi)`。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `getPose()`</u>](Methods.md#getpose)

### `States(4)` `States(5)` {#states4-states5}

分别为*车体坐标系*下的实际虚拟前轮转角（rad）和虚拟车轮角速度（rad/s）。正值表示左转和前进。二者通过一阶惯性执行器响应跟踪保持指令，因此可能与 `Cmd` 不同。构造函数和 `reset()` 要求初始转角满足 `abs(delta) < atan(2*wheelBase/trackWidth)`，且两个初始执行器状态均位于 `getCmdLimits()` 返回的对称保守瞬态边界内（含边界）。越界会触发 `ackermann_robot:InvalidInitialState`，而非自动限幅；执行器范围错误会报告允许的转角和轮速范围。失败的 `reset()` 保留原状态及保持指令。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `getVirtualSteeringAngle()`</u>](Methods.md#getvirtualsteeringangle) 和 [<u>方法 `getVirtualWheelSpeed()`</u>](Methods.md#getvirtualwheelspeed)

## 3.* `Params` {#3-params}

阿克曼机器人的物理及显示参数，以私有标量结构体保存。下列十个字段均为必需字段，每个字段都对应大小写完全一致的顶层 YAML 键。例如，YAML 中的 `wheelRadius: 0.1` 加载后成为 MATLAB 的 `params.wheelRadius = 0.1`；YAML 文件不包含外层 `Params:` 键。

构造函数的 `Params` 参数省略或为 `[]` 时，`rpm.utils.load_ackermann_params()` 会读取项目的 `+rpm/config/ackermann_robot.yaml`。如需使用自定义文件，调用 `rpm.utils.load_ackermann_params(file_path)` 并将返回的结构体传入构造函数；也可手动创建包含全部十个字段的结构体。缺失字段会报错，不会从默认 YAML 中逐项补齐。

加载函数和构造函数会校验参数，并将数值规范为 `double` 标量或列向量。加载函数保留零时间常数；构造函数会警告并将其替换为 `1e-3` s。下文的**默认值**来自随附的 YAML 模板，而非构造函数中逐字段硬编码的默认值。

参数在构造时复制到对象中。之后修改 YAML 文件或原结构体不会更新已有机器人。`getParams()` 返回当前实际参数的副本，包含替换后的时间常数；修改该副本也不会改变机器人。要应用新的物理参数，请创建新对象。`reset()` 保留原参数。YAML 参数文件不配置 `Metadata`、`States`、`Cmd` 或 `Config`。

例如，先导出模板，编辑数值，再加载：

```matlab
rpm.utils.export_ackermann_params('my_ackermann.yaml'); % Refuses to overwrite an existing file.
% Edit my_ackermann.yaml before loading it.
params = rpm.utils.load_ackermann_params('my_ackermann.yaml');
params.wheelRadius = 0.12; % Optional in-memory override; does not edit the YAML.
robot = rpm.ackermann_robot(params);
actual_params = robot.getParams();
```

自定义 YAML 应保持支持的扁平数值格式：`key: number` 或 `key: [number, ...]`。没有 `readyaml` 时，内置备用读取器不支持嵌套 YAML 或数值后的行内注释；请将注释单独写成一行。

<!-- TODO: Add the parameter illustration 和 its relative image link when the asset is available. -->

### `Params.wheelRadius` {#paramswheelradius}

四个车轮共用的有效滚动半径，单位为米（m）。它将虚拟车轮角速度转换为后轴中点的前进速度：`v = wheelRadius * Omega`。

- **类型：** `double` 标量
- **默认值：** `0.1`
- **约束：** 有限实数，且严格为正。
- **YAML 键：** `wheelRadius`
- **另见：** [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativezut), [<u>方法 `virtual2body()`</u>](Methods.md#virtual2bodyvirtual_state)，以及 [<u>方法 `body2virtual()`</u>](Methods.md#body2virtualbody_velocity)；也由以下方法间接使用：[<u>方法 `getVel()`</u>](Methods.md#getvel) 和 [<u>方法 `getPoseDot()`</u>](Methods.md#getposedot).

### `Params.wheelBase` {#paramswheelbase}

前后轴中心线之间的纵向距离，单位为米（m）。它决定单轨模型中的横摆角速度，并参与阿克曼几何映射和虚拟指令限幅计算。

- **类型：** `double` 标量
- **默认值：** `0.60`
- **约束：** 有限实数，且严格为正。
- **YAML 键：** `wheelBase`
- **另见：** [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativezut), [<u>方法 `virtual2body()`</u>](Methods.md#virtual2bodyvirtual_state), [<u>方法 `body2virtual()`</u>](Methods.md#body2virtualbody_velocity), [<u>方法 `physicalWheelMap()`</u>](Methods.md#physicalwheelmapz), [<u>方法 `commandLimits()`</u>](Methods.md#commandlimits)，以及 [<u>方法 `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

### `Params.trackWidth` {#paramstrackwidth}

左右车轮中心线之间的横向距离，单位为米（m），前后轴共用。它决定左右实际转角和轮速之间的差异。

- **类型：** `double` 标量
- **默认值：** `0.45`
- **约束：** 有限实数，且严格为正。
- **YAML 键：** `trackWidth`
- **另见：** [<u>方法 `physicalWheelMap()`</u>](Methods.md#physicalwheelmapz), [<u>方法 `commandLimits()`</u>](Methods.md#commandlimits)，以及 [<u>方法 `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

### `Params.wheelTimeConstant` {#paramswheeltimeconstant}

虚拟轮速执行器的时间常数，单位为秒（s）：`dOmega/dt = (Omega_c - Omega) / wheelTimeConstant`。数值越小，响应越快。对于恒定目标，连续模型经过一个时间常数后可消除约 63.2% 的初始速度误差。

- **类型：** `double` 标量
- **默认值：** `0.2`
- **约束：** 有限非负实数。加载函数接受 `0`，但构造函数会发出 `ackermann_robot:ZeroTimeConstant`，并将其替换为 `1e-3` s，以近似理想执行器。
- **YAML 键：** `wheelTimeConstant`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams), [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativezut),，以及以下方法中的步长警告检查：[<u>方法 `step()`</u>](Methods.md#stepdt-t).

### `Params.steeringTimeConstant` {#paramssteeringtimeconstant}

虚拟转向执行器的时间常数，单位为秒（s）：`ddelta/dt = (delta_c - delta) / steeringTimeConstant`。数值越小，转向响应越快。对于恒定目标，连续模型经过一个时间常数后可消除约 63.2% 的初始转角误差。

- **类型：** `double` 标量
- **默认值：** `0.1`
- **约束：** 有限非负实数。加载函数接受 `0`，但构造函数会发出 `ackermann_robot:ZeroTimeConstant`，并将其替换为 `1e-3` s。
- **YAML 键：** `steeringTimeConstant`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams), [<u>方法 `stateDerivative()`</u>](Methods.md#statederivativezut),，以及以下方法中的步长警告检查：[<u>方法 `step()`</u>](Methods.md#stepdt-t).

### `Params.maxPhysicalWheelSpeed` {#paramsmaxphysicalwheelspeed}

任一实际车轮允许的最大角速度绝对值，单位为 rad/s，指车轮端而非减速器前电机轴的速度。模型在允许的转角范围内，将它转换为与当前转角无关的保守虚拟轮速指令上限，不对四个实际轮速分别限幅。

- **类型：** `double` 标量
- **默认值：** `20.0`
- **约束：** 有限实数，且严格为正。
- **YAML 键：** `maxPhysicalWheelSpeed`
- **另见：** [<u>方法 `commandLimits()`</u>](Methods.md#commandlimits)，被以下方法调用：[<u>方法 `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>方法 `getCmdLimits()`</u>](Methods.md#getcmdlimits)，以及 [<u>方法 `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

### `Params.maxPhysicalSteeringAngle` {#paramsmaxphysicalsteeringangle}

任一实际前轮允许的最大转角绝对值，单位为弧度（rad）。模型通过阿克曼几何将其转换为对称虚拟转角指令上限，通常小于实际转角上限；实际前轮转角不分别限幅。

- **类型：** `double` 标量
- **默认值：** `0.61086524` （约 35 度）
- **约束：** 有限实数，且严格位于 `0` 与 `pi/2` 之间。
- **YAML 键：** `maxPhysicalSteeringAngle`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams) 和 [<u>方法 `commandLimits()`</u>](Methods.md#commandlimits)；后者被以下方法调用：[<u>方法 `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>方法 `getCmdLimits()`</u>](Methods.md#getcmdlimits)，以及 [<u>方法 `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

上述两个物理上限决定 `getCmdLimits()` 返回的保守瞬态边界。`sendCmd()` 将目标限幅到该边界；构造函数和 `reset()` 要求初始虚拟转角和轮速已满足相同边界（含边界）。非法初始状态会被拒绝，而非限幅。这个矩形范围是保守的：即使初始状态对应的瞬时实际车轮量满足物理上限，也可能被拒绝。在合法初始状态和有界指令下，连续一阶执行器模型保持在矩形范围内；数值仿真仍需采用合适的积分步长和方法。

### `Params.bodySize` {#paramsbodysize}

不包含车轮的主体包围盒尺寸，单位为米（m），顺序为 `[length; width; height]`。这是显示几何参数，不影响当前运动方程。

- **类型：** `double`, `3x1` 列向量 （接受三元素行向量或列向量输入）
- **默认值：** `[0.70; 0.40; 0.20]`
- **约束：** 三个有限、严格为正的实数元素。
- **YAML 键：** `bodySize`；YAML 中写为 `bodySize: [0.70, 0.40, 0.20]`，并规范为列向量。
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams) 和 [<u>方法 `getParams()`</u>](Methods.md#getparams)，用于外部渲染或几何计算；当前运动方程不使用该参数。

### `Params.wheelWidth` {#paramswheelwidth}

四个车轮沿轮轴方向的共用宽度，单位为米（m）。这是显示几何参数，不影响轮速或转向计算。

- **类型：** `double` 标量
- **默认值：** `0.05`
- **约束：** 有限实数，且严格为正。
- **YAML 键：** `wheelWidth`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams) 和 [<u>方法 `getParams()`</u>](Methods.md#getparams)，用于外部渲染或几何计算；当前运动方程不使用该参数。

### `Params.rearAxleOffset` {#paramsrearaxleoffset}

后轴中点相对车体几何中心、沿车体前进轴的有符号纵向偏移，单位为米（m）。正值表示后轴位于车体中心前方，负值表示位于后方。此显示几何参数用于确定车体相对位姿参考点的位置，不改变运动方程使用的参考点。

- **类型：** `double` 标量
- **默认值：** `-0.30`
- **约束：** 任意有限实数标量；允许正值、负值和零。
- **YAML 键：** `rearAxleOffset`
- **另见：** [<u>方法 `validateParams()`</u>](Methods.md#validateparamsparams) 和 [<u>方法 `getParams()`</u>](Methods.md#getparams)，用于外部渲染或几何计算；当前运动方程不使用该参数。


## 4.* `Cmd` {#4-cmd}

向量顺序为 `[steering_angle_cmd; wheel_speed_cmd]`，对应理论记号 $[\delta_c, \Omega_c]^\mathsf{T}$。

保存最近一次限幅后虚拟执行器指令的私有 `2x1 double` 向量。`sendCmd()` 更新它，`getCmd()` 读取它；每次 `step()` 都使用相同的保持值，直到下一次发送或重置。构造函数和 `reset()` 将其初始化为零，即使初始执行器状态非零。发送指令只改变目标，不立即改变实际状态或位姿。

### `Cmd(1)` `Cmd(2)` {#cmd1-cmd2}

分别为虚拟转角目标（rad）和虚拟轮速目标（rad/s），正值表示左转和前进。各输入独立限幅到 `getCmdLimits()` 返回的对称边界；实际执行器状态通过一阶动态逐渐接近保持目标。

- **类型：** `double`
- **默认值：** `0`
- **另见：** [<u>方法 `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>方法 `getCmd()`</u>](Methods.md#getcmd) 和 [<u>方法 `step()`</u>](Methods.md#stepdt-t)

## 5.* `Config` {#5-config}

私有仿真配置结构体，由构造函数初始化并在 `reset()` 时保留。通过下列公开设置方法修改。这些选项不从物理参数 YAML 文件中读取。

### `Config.solution_method` {#configsolution_method}

`step()` 推进全部五个状态时使用的固定步长积分方法。`'euler'` 表示显式欧拉法，`'RK4'` 表示经典四阶 Runge-Kutta 法。`setSolutionMethod()` 接受字符行向量或字符串标量，不区分大小写，并保存规范拼写。修改方法会清除步长警告标记，不改变状态或保持指令。

- **类型：** `char`
- **默认值：** `'RK4'`
- **另见：** [<u>方法 `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method) 和 [<u>方法 `step()`</u>](Methods.md#stepdt-t).

### `Config.wrap_heading` {#configwrap_heading}

是否在每次完整积分步结束后，将航向角归一化到 `[-pi, pi)`。`false` 保留累计航向，`true` 丢弃完整转圈数。设置该选项不会立即改变航向；之后禁用它也不会恢复已丢弃的转圈数。

- **类型：** `logical` 标量
- **默认值：** `false`
- **另见：** [<u>方法 `setWrapHeading()`</u>](Methods.md#setwrapheadingwrap_heading) 和 [<u>方法 `step()`</u>](Methods.md#stepdt-t).

### `Config.warn_on_saturation` {#configwarn_on_saturation}

`sendCmd()` 对越界指令限幅时，是否每次都发出 `ackermann_robot:CommandSaturated` 警告。禁用此选项仅抑制该警告，仍会执行限幅，零时间常数和大步长警告不受影响。

- **类型：** `logical` 标量
- **默认值：** `true`
- **另见：** [<u>方法 `setWarnOnSaturation()`</u>](Methods.md#setwarnonsaturationwarn_on_saturation) 和 [<u>方法 `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd).

## 6.* `StepSizeWarningActive` {#6-stepsizewarningactive}

用于避免连续大步长调用重复警告的私有标记。`step()` 计算 `ratio = max(dt ./ [steeringTimeConstant; wheelTimeConstant])`。当 `ratio > 0.1` 时，仅在该标记原为 `false` 时发出 `ackermann_robot:LargeStepSize`，随后置为 `true`。之后处于相同警告范围的步长保持静默，即使步长值发生变化。执行 `ratio <= 0.1` 的一步会清除标记，允许后续大步长再次发出警告。

- **类型：** `logical` 标量
- **默认值：** `false`
- **另见：** [<u>方法 `step()`</u>](Methods.md#stepdt-t)检查并更新它；[<u>方法 `reset()`</u>](Methods.md#resetini_states)和成功执行的 [<u>方法 `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method)会清除它。构造函数通过以下方法初始化它：[<u>方法 `reset()`</u>](Methods.md#resetini_states).

---
