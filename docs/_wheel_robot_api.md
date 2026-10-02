# wheel_robot API 使用文档

本文件描述 `wheel_robot` 类对外暴露的全部接口：公共属性、构造函数、getter、配置方法、控制方法、仿真方法以及运动学换算工具。类内部的状态方程与推导见项目根目录下的 [fundamental.md](../fundamental.md)。

文中**项目根目录**指代包含 `plants`、`config`、`utils`、`tests` 和 `docs` 的文件夹，其内部布局为：

这个文件夹本身叫什么、放在哪块盘都可以。类内部用 `mfilename('fullpath')` 定位项目根目录，再读取 `config` 中的默认参数。保留各子目录的相对布局即可整体改名或搬家；`wheel_robot.m` 的文件名必须与类名一致。

```text
<项目根目录>/
├── plants/wheel_robot.m          本类
├── config/wheel_robot.yaml       默认物理参数
├── utils/load_wheel_params.m     参数读取
├── utils/export_wheel_params.m   参数模板导出
├── tests/                       自检与仿真循环
└── docs/wheel_robot_api.md       本文档
```

## 1. 模型与约定

`wheel_robot` 是一个**差速驱动、左右两轮**的平面机器人仿真对象，两轮均为一阶转速响应（电机时间常数），采用平面纯滚动假设并忽略侧滑。

使用时请牢记以下全局约定：

- 参考点是**驱动轴中点**，不是车体几何中心。`axleOffset` 仅用于图形显示。
- 航向角 `theta` 从世界坐标系 x 轴起算，**逆时针为正**。
- 两轮正转都对应车体前进；**右轮**转速高于左轮时车体向左（逆时针，`omega > 0`）转，反之向右（顺时针）。
- 成对参数（轮半径、时间常数、限速等）的排列顺序**始终是先左后右**。
- 单位：长度 `m`、时间 `s`、角度 `rad`、角速度 `rad/s`。
- 本类继承自 `handle`，赋值给另一个变量后两个变量引用同一个对象；需要多机器人仿真时请分别构造实例。
- 只有 `Metadata` 是公共属性。`Params`、`States`、`Cmd`、`Config` 都是 private，必须通过下面的方法读写。

标准用法是一个「指令保持 + 定步长积分」的循环：`sendCmd` 写入目标轮速，`step` 沿连续状态推进，`get*` 读取结果。

## 2. 快速开始

```matlab
% 在 MATLAB 中把类目录加入搜索路径（尖括号部分换成你本机的实际目录）
addpath(fullfile('<项目根目录>', 'plants'));

robot = wheel_robot();                 % 参数来自 config/wheel_robot.yaml
robot.setWarnOnSaturation(false);      % 关闭限幅提示（可选）

dt = 1e-3;
robot.sendCmd(5, 5);                   % 左右轮目标角速度 [rad/s]
for k = 1:1000
    robot.step(dt, (k-1)*dt);          % 推进 1 s
end

robot.getPose()      % 3x1 [x; y; theta]
robot.getVel()       % 2x1 [v; omega]
```

> 注意：若自定义参数中的 `motorTimeConstant` 包含 `0`，构造时会发出一次 `wheel_robot:ZeroMotorTimeConstant` 警告，并将对应元素按 `1e-3 s` 处理。内置默认配置采用非零时间常数，不会触发该警告。

## 3. 构造函数

```matlab
obj = wheel_robot(Params, ini_states, Metadata)
```

三个入参都可以省略或传 `[]`：

| 参数 | 是否必填 | 缺省值 | 说明 |
| --- | --- | --- | --- |
| `Params` | 否 | `load_wheel_params()` 的结果 | 标量结构体，物理参数，字段见第 10 节 |
| `ini_states` | 否 | `zeros(7,1)` | 7 元素实数行/列向量，有限，顺序见第 11 节；整数会被转成 `double` |
| `Metadata` | 否 | `struct()` 补默认字段 | 标量结构体，纯描述信息，见第 4 节 |

构造行为细节：

- `Params` 中的成对字段允许写成标量（左右相同），构造函数会扩展为 `2x1`；向量统一转成列向量；**额外的自定义字段会被保留**。
- `motorTimeConstant` 中为 `0` 的元素会被警告后替换为 `1e-3`，其余正值原样保留。
- 初始轮速原样保留，`maxWheelSpeed` 只约束 `sendCmd` 写入的目标值。构造后目标轮速默认是 `0`，所以**非零初始轮速会自然衰减到零**。
- 默认参数通过项目内的 `utils/load_wheel_params.m` 读取 `config/wheel_robot.yaml`，构造函数会临时把 `utils` 加入搜索路径并在结束时移除。请保持 `plants`、`utils`、`config` 三者的相对位置不变，或者自己传入 `Params` 结构体。

常见构造方式：

```matlab
% 全默认
robot = wheel_robot();

% 默认参数 + 自定义初始状态（车头朝 +y，已带 2 rad/s 左右轮速）
robot = wheel_robot([], [0; 0; pi/2; 0; 2; 0; 2]);

% 读 YAML 后局部改写，再传入
params = load_wheel_params();
params.wheelRadius       = [0.08; 0.12];
params.motorTimeConstant = [0.1; 0.2];
params.maxWheelSpeed     = [3.5; 5.5];
robot = wheel_robot(params, zeros(7,1));

% 指定另一份配置文件
params = load_wheel_params("my_robot.yaml");   % 相对当前目录或写绝对路径
robot  = wheel_robot(params);
```

如果需要创建自己的 YAML 配置文件，不必寻找或修改工具箱安装目录。可将内置标准模板导出到当前工作目录：

```matlab
file_path = export_wheel_params();   % 生成当前目录下的 wheel_robot.yaml
edit(file_path);                     % 修改导出的副本

params = load_wheel_params(file_path);
robot  = wheel_robot(params);
```

也可以指定导出位置：

```matlab
file_path = export_wheel_params("config/my_robot.yaml");
```

导出函数会保留模板中的中文注释和字段顺序。若目标已经存在，函数会报错且不会覆盖原文件。

### 3.1 `reset(ini_states)`

复位已有对象，适合重复实验和参数扫描。`ini_states` 可省略或传 `[]`，此时使用七维零状态；也可传入符合第 11 节顺序的七元素行向量或列向量。

```matlab
robot.reset();                                  % 零状态、零指令
robot.reset([1; 2; pi/2; 0; 0; 0; 0]);         % 指定新状态、零指令
```

`reset` 会清零当前保持的左右轮速指令，但会保留 `Params`、`Metadata` 和全部 `Config` 设置。因此，复位后若要继续运动，需要重新调用 `sendCmd`。

## 4. 公共属性：`Metadata`

描述信息结构体，**不参与任何计算**，可自由增删字段。构造时会自动补齐缺失的三个默认字段：

| 字段 | 默认值 | 含义 |
| --- | --- | --- |
| `Name` | `'wheel_robot'` | 对象名称 |
| `Number` | `[]` | 对象编号 |
| `Description` | `'none'` | 对象说明 |

```matlab
robot.Metadata.Number = 3;
robot.Metadata.color  = 'red';    % 允许自定义字段
```

## 5. 状态读取接口

全部为只读，返回的都是**副本**，修改返回值不会影响对象内部状态。

| 方法 | 返回值 | 单位 | 含义 |
| --- | --- | --- | --- |
| `getStates()` | `7x1` | 见第 11 节 | 完整七维状态，排列顺序与构造函数的 `ini_states` 相同 |
| `getCmd()` | `2x1` `[cmd_L; cmd_R]` | `rad/s` | 当前保持的限幅后左右轮目标角速度 |
| `getPose()` | `3x1` `[px; py; theta]` | `m, m, rad` | 驱动轴中点的世界位姿 |
| `getVel()` | `2x1` `[v; omega]` | `m/s, rad/s` | 车体前向线速度与偏航角速度 |
| `getPoseDot()` | `3x1` `[px_dot; py_dot; theta_dot]` | `m/s, m/s, rad/s` | 世界坐标系下的瞬时位姿变化率 |
| `getWheelSpeed()` | `2x1` `[Omega_L; Omega_R]` | `rad/s` | 左右轮**实际**角速度 |
| `getWheelAngle()` | `2x1` `[alpha_L; alpha_R]` | `rad` | 左右轮累计转角 |
| `getParams()` | `struct` | — | 对象实际采用的物理参数副本 |

使用要点：

- `getVel` / `getWheelSpeed` 反映的是**实际状态**，由于一阶响应，它们通常与 `getCmd` 返回的目标值不同。
- `getCmd` 返回 `sendCmd` 限幅后实际写入的指令，不一定等于控制器最初发出的越界值。
- `getVel` 由实际轮速换算而来：`v = (r_L*Omega_L + r_R*Omega_R)/2`，`omega = (r_R*Omega_R - r_L*Omega_L)/trackWidth`。
- `getPoseDot` 中的 `theta_dot` 是物理角速度，**不包含**航向角归一化时跨越 ±pi 的数值跳变，适合做速度和轨迹绘制。
- `getWheelAngle` 不做 `mod 2*pi`，里程/编码器类计算可直接使用。
- `getPose` 中 `theta` 默认累加不归一化，是否归一化由 `setWrapHeading` 决定（见第 7 节）。
- `getParams` 返回的是构造函数**规范化之后**的值（`2x1` 列向量、零时间常数已替换），可用于渲染和记录。

```matlab
pose  = robot.getPose();
state = robot.getStates();
cmd   = robot.getCmd();
speed = robot.getWheelSpeed();
v     = robot.getVel();                       % [m/s; rad/s]
pose_dot = robot.getPoseDot();
plot(pose_dot(1), pose_dot(2))                % 世界系下的速度分量
```

## 6. 控制接口：`sendCmd`

```matlab
obj.sendCmd(left_wheel_cmd, right_wheel_cmd)
```

- 两个入参均为有限实数标量，单位 `rad/s`，顺序先左后右。
- 各轮按自己的 `maxWheelSpeed` 做**对称限幅**（`±maxWheelSpeed`），整数入参会先转 `double`，限幅过程不取整。
- 调用只更新内部保持的目标指令，**不会立即改变实际轮速或位姿**，需要配合 `step` 才生效。
- **零阶保持**：在下一次 `sendCmd` 之前，每一次 `step` 都复用最近保存的指令。控制更新时刻完全由外部循环安排。
- 发生限幅时是否警告由 `Config.warn_on_saturation` 决定（默认开），警告 ID 为 `wheel_robot:CommandSaturated`。

```matlab
obj.sendCmd(2, 4);           % 差速前进并向左偏（右轮更快，omega > 0）
obj.sendCmd(0, 0);           % 目标轮速归零，实际轮速按时间常数衰减
obj.sendCmd(100, -100);      % 越界：触发限幅警告，实际保存 ±maxWheelSpeed
```

## 7. 配置接口

这三个方法是唯一修改求解配置 (`Config`) 的入口，配置对**后续**的 `step` 生效，不会回溯修改已有状态。

### 7.1 `setSolutionMethod(solution_method)`

设置后续 `step` 使用的定步长积分方法。接受字符行向量或字符串标量，**不区分大小写**：

| 取值 | 含义 |
| --- | --- |
| `'euler'` | 显式欧拉 |
| `'RK4'` | 经典四阶 Runge-Kutta（默认值） |

输入非法时抛出 `wheel_robot:InvalidSolutionMethod` 并保持原配置不变。

```matlab
robot.setSolutionMethod('euler');
robot.setSolutionMethod("RK4");
```

### 7.2 `setWrapHeading(wrap_heading)`

是否在每个完整积分步结束后把 `theta` 归一化到 `[-pi, pi)`。只接受**逻辑标量** `true`/`false`（默认 `false`），传 `1` 这类数值会被拒绝。

归一化会**丢失累计圈数**，之后再关掉也补不回来。若既要连续角度又要显示用主值区间，建议保持关闭并在外部用 `mod` 自行处理。

### 7.3 `setWarnOnSaturation(warn_on_saturation)`

`sendCmd` 发生限幅时是否发出警告。只接受逻辑标量（默认 `true`）。关闭警告**不影响限幅本身**，也不会改变当前保持的指令。

```matlab
robot.setWrapHeading(true);
robot.setWarnOnSaturation(false);   % 等价于 warning('off','wheel_robot:CommandSaturated')
```

## 8. 仿真接口：`step`

```matlab
obj.step(dt)
obj.step(dt, t)
```

- `dt`：正的有限实数标量，仿真步长 `[s]`，由外部提供。
- `t`：本步起始时刻 `[s]`，可省略或传 `[]`（按 `0` 处理）。当前模型不显含时间，**`t` 不影响积分结果，类内部也不会累计时间**，请自行维护时间轴。
- `step` 只更新 7 维状态，**不修改** `Cmd`；`RK4` 的四个中间求值都使用同一个保持指令。
- 启用 `wrap_heading` 时，只在整步积分完成后归一化航向角。

步长选择（对应一阶衰减模态的线性稳定条件，须对左右轮**分别**满足）：

```text
euler:  dt < 2 * motorTimeConstant
RK4:    dt < 2.785 * motorTimeConstant
```

数值稳定不等于精度足够，工程上一般取 `dt <= 0.1 * min(motorTimeConstant)`；`motorTimeConstant = 1e-3` 时建议 `dt <= 1e-4`。

当 `max(dt./motorTimeConstant) > 0.1` 时，`step` 会发出 `wheel_robot:LargeStepSize` 警告。只在步长比值从安全区间进入警告区间时提示一次，连续使用相同大步长不会在每一步重复刷屏；先恢复安全步长、调用 `reset` 或更改积分方法后，再次进入警告区间会重新提示。

## 9. 运动学换算工具

两个方法都只做纯计算，**不读取也不修改**对象状态，且**不做限幅**（限幅发生在 `sendCmd` 内部）。左右顺序与正方向和模型完全一致。

```matlab
wheel_speed = obj.body2wheel(body_velocity)   % [v; omega] -> 2x1 [Omega_L; Omega_R]
body_velocity = obj.wheel2body(wheel_speed)   % [Omega_L; Omega_R] -> 2x1 [v; omega]
```

- 入参接受 2 元素行向量或列向量，实数有限；输出恒为 `2x1`。
- 换算使用当前物理参数（支持左右轮半径不同）：

```text
wheel2body: v = (r_L*Omega_L + r_R*Omega_R)/2
            omega = (r_R*Omega_R - r_L*Omega_L)/L

body2wheel: Omega_L = (v - omega*L/2)/r_L
            Omega_R = (v + omega*L/2)/r_R
```

典型用法：控制器输出车体速度指令后换算成轮速再下发。

```matlab
v_cmd     = 0.8;                       % m/s
omega_cmd = 0.5;                       % rad/s
wheel_cmd = robot.body2wheel([v_cmd; omega_cmd]);
robot.sendCmd(wheel_cmd(1), wheel_cmd(2));
```

## 10. 物理参数结构体 `Params`

自定义 `Params` 时必须包含下列字段。校验失败会抛出 `wheel_robot:MissingParameter` 或 MATLAB 的参数校验错误。

| 字段 | 维度 | 单位 | 约束 | 说明 |
| --- | --- | --- | --- | --- |
| `wheelRadius` | `2x1`（可写标量） | `m` | 正数 | 左右轮有效滚动半径 |
| `trackWidth` | 标量 | `m` | 正数 | 轮距，左右轮中心线横向距离 |
| `motorTimeConstant` | `2x1`（可写标量） | `s` | 非负 | 左右轮转速一阶响应时间常数，`0` 会被替换为 `1e-3` 并警告 |
| `maxWheelSpeed` | `2x1`（可写标量） | `rad/s` | 正数 | 左右轮目标角速度绝对值上限，仅约束 `sendCmd` |
| `bodySize` | `3x1` | `m` | 正数 | 主体长、宽、高（不含轮） |
| `wheelWidth` | `2x1`（可写标量） | `m` | 正数 | 左右轮沿车轴方向的宽度 |
| `axleOffset` | 标量 | `m` | 任意有限值 | 驱动轴中点相对主体中心的前向偏移，正值表示在前方 |

`bodySize`、`wheelWidth`、`axleOffset` 是几何显示参数，当前**不参与运动方程**；参与动力学与运动学的是前四个字段。

默认值来自 [config/wheel_robot.yaml](../config/wheel_robot.yaml)：`wheelRadius = [0.10, 0.10]`、`trackWidth = 0.45`、`motorTimeConstant = [0.15, 0.15]`、`maxWheelSpeed = [20, 20]`、`bodySize = [0.60, 0.40, 0.20]`、`wheelWidth = [0.05, 0.05]`、`axleOffset = 0`。

**参数只能在构造时设定。** `getParams()` 返回的是副本，改它不会作用到对象上；需要换参数请用新 `Params` 重新构造，例如：

```matlab
p = robot.getParams();
p.trackWidth = 0.5;

pose  = robot.getPose();
angle = robot.getWheelAngle();
speed = robot.getWheelSpeed();
z0    = [pose; angle(1); speed(1); angle(2); speed(2)];   % 顺序与 States 一致

robot = wheel_robot(p, z0);
```

## 11. 状态向量布局

`ini_states` 以及内部 `States` 均为 7 维，顺序固定：

| 索引 | 名称 | 单位 | 对应读取方法 |
| --- | --- | --- | --- |
| 1 | `px` | `m` | `getPose` 第 1 个元素 |
| 2 | `py` | `m` | `getPose` 第 2 个元素 |
| 3 | `theta` | `rad` | `getPose` 第 3 个元素 |
| 4 | `left_wheel_angle` | `rad` | `getWheelAngle` 第 1 个元素 |
| 5 | `left_wheel_speed` | `rad/s` | `getWheelSpeed` 第 1 个元素 |
| 6 | `right_wheel_angle` | `rad` | `getWheelAngle` 第 2 个元素 |
| 7 | `right_wheel_speed` | `rad/s` | `getWheelSpeed` 第 2 个元素 |

即「先位姿 3 项，再按左轮（角、速）、右轮（角、速）排列」。轮角累计不归一化；航向角是否归一化取决于 `wrap_heading`。

拼接 7 维状态时**不能**直接写 `[getPose(); getWheelAngle(); getWheelSpeed()]`，那样会把左右轮角连在一起、再跟上两个轮速，与 `States` 的交错顺序不符。请按 `angle(1); speed(1); angle(2); speed(2)` 交错排列，或像 `tests/test_wheel_loop.m` 那样用索引写入 `z([4, 6]) = angle` 与 `z([5, 7]) = speed`。

## 12. 完整示例：控制周期与仿真步长解耦

下面的写法与 `tests/test_wheel_loop.m` 一致：外层按 `dt` 推进仿真，每隔 `control_period` 重新下发一次指令。

```matlab
% 类目录入路径；utils 目录只有需要直接调用 load_wheel_params 时才加
addpath(fullfile('<项目根目录>', 'plants'));
addpath(fullfile('<项目根目录>', 'utils'));

dt              = 1e-4;      % 仿真步长 [s]
simulation_time = 5;         % 仿真时长 [s]
control_period  = 0.1;       % 控制周期 [s]
n_steps     = round(simulation_time / dt);
n_ctrl_step = round(control_period / dt);

robot = wheel_robot();
time  = (0:n_steps) * dt;
log   = zeros(7, n_steps + 1);
log(:, 1) = robot.getStates();

for k = 1:n_steps
    t = (k - 1) * dt;
    if mod(k - 1, n_ctrl_step) == 0
        % 简单的车体速度指令 -> 轮速指令
        wheel_cmd = robot.body2wheel([0.5; 0.3 * sin(0.5 * t)]);
        robot.sendCmd(wheel_cmd(1), wheel_cmd(2));
    end
    robot.step(dt, t);
    log(:, k + 1) = robot.getStates();
end

figure;
plot(log(1, :), log(2, :), 'LineWidth', 1.2); grid on; axis equal;
xlabel('x [m]'); ylabel('y [m]'); title(robot.Metadata.Name);
```

读取一轮完整状态快照的推荐写法：

```matlab
snapshot.pose        = robot.getPose();
snapshot.velocity    = robot.getVel();
snapshot.poseDot     = robot.getPoseDot();
snapshot.wheelSpeed  = robot.getWheelSpeed();
snapshot.wheelAngle  = robot.getWheelAngle();
```

## 13. 错误与警告速查

| ID | 类型 | 触发条件 | 处理建议 |
| --- | --- | --- | --- |
| `wheel_robot:InvalidSolutionMethod` | error | `setSolutionMethod` 入参非字符向量/字符串标量、为 `missing`、或不是 `euler`/`RK4` | 原配置保持不变，修正取值后重设 |
| `wheel_robot:UnknownSolutionMethod` | error | 内部配置被改成未知值 | 重新调用 `setSolutionMethod` |
| `wheel_robot:MissingParameter` | error | `Params` 缺少必需字段 | 补齐字段或改用 `load_wheel_params()` |
| `wheel_robot:ZeroMotorTimeConstant` | warning | 传入（或默认配置含）`motorTimeConstant = 0` | 该轮按 `1e-3 s` 计算，`dt` 需相应变小 |
| `wheel_robot:CommandSaturated` | warning | `sendCmd` 目标轮速超出 `±maxWheelSpeed` | 用 `setWarnOnSaturation(false)` 静音，或减小指令 |
| `wheel_robot:LargeStepSize` | warning | `max(dt./motorTimeConstant) > 0.1` | 减小 `dt`，或不要将时间常数设为 `0` 后依赖 `1e-3 s` 近似值 |
| `wheel_robot:ParameterFileNotFound` | error | `load_wheel_params` 找不到 yaml | 检查路径或显式传入文件路径 |
| `wheel_robot:TemplateFileNotFound` | error | `export_wheel_params` 找不到随工具箱安装的内置模板 | 检查安装包是否完整 |
| `wheel_robot:ExportTargetExists` | error | `export_wheel_params` 的目标文件或目录已经存在 | 更换文件名，或自行确认后删除旧文件 |
| `wheel_robot:ExportFailed` | error | 模板复制失败，例如父目录不存在或无写入权限 | 检查目标目录及其写入权限 |

其余入参校验（维度、非有限、非正 `dt`、数值型 `wrap_heading` 等）由 MATLAB `validateattributes` 抛出，错误信息中会带上出错参数名。

## 14. API 一览

| 分类 | 接口 | 一句话说明 |
| --- | --- | --- |
| 构造 | `wheel_robot(Params, ini_states, Metadata)` | 创建并初始化机器人，三个入参可省略 |
| 复位 | `reset([ini_states])` | 保留参数和配置，复位状态并清零保持指令 |
| 参数 | `load_wheel_params([file_path])` | 获取默认参数结构体，或读取指定 YAML |
| 参数 | `export_wheel_params([file_path])` | 将内置 YAML 模板导出到当前目录或指定位置 |
| 属性 | `Metadata` | 描述信息结构体，可自由读写 |
| 读取 | `getStates` / `getCmd` | 完整七维状态、当前保持的限幅后轮速指令 |
| 读取 | `getPose` / `getVel` / `getPoseDot` | 位姿、车体速度、位姿变化率 |
| 读取 | `getWheelSpeed` / `getWheelAngle` | 左右轮实际角速度、累计转角 |
| 读取 | `getParams` | 当前生效的物理参数副本 |
| 配置 | `setSolutionMethod` | 选 `euler` 或 `RK4` |
| 配置 | `setWrapHeading` | 航向角是否归一化到 `[-pi, pi)` |
| 配置 | `setWarnOnSaturation` | 限幅时是否警告 |
| 控制 | `sendCmd` | 限幅并保存左右轮目标角速度（零阶保持） |
| 仿真 | `step` | 用保持指令把状态推进一个 `dt` |
| 工具 | `body2wheel` / `wheel2body` | 车体速度与左右轮速互转，不限幅 |

## 15. 使用注意事项

- `sendCmd` 之后必须调用 `step` 才会运动；只 `step` 不 `sendCmd` 时目标轮速为 `0`，实际轮速会衰减。
- 想让轨迹连续可微，请保证 `dt` 足够小，并让控制周期是 `dt` 的整数倍。
- 类不保存仿真时钟，`step` 的 `t` 只做校验、不影响结果，需要时自己维护。
- 状态、参数、配置都不能直接改写；使用 `reset` 重设状态，物理参数变化时重新构造对象，求解配置通过对应的 `set*` 方法修改。
- `handle` 语义下，同一实例传给多个函数后它们操作的是同一个机器人。
- 航向角默认累加，画极坐标或取主值时需要自行 `mod` 或开启 `setWrapHeading(true)`。
- 拼 7 维状态时记住轮角与轮速是**左右交错**的（第 11 节），这是最常见的初始化错误。
- 回归自检可运行 `tests/test_wheel_robot.m`（接口行为）和 `tests/test_wheel_loop.m`（含绘图的长时仿真循环）。
