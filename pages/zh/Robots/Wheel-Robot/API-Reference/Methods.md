# 差速轮式机器人方法 {#wheel-robot-methods}

> **提示：** 带 `'*'` 的小节表示私有项。

## 1. 初始化 {#1-initialization}

通过构造函数创建具有独立物理参数、初始状态和元数据的机器人。通过 `reset()` 重置已有机器人，而不改变参数或仿真配置；两种操作均不推进仿真时间。

### `rpm.wheel_robot(Params, Ini_States, Metadata)` {#rpm-wheel-robot}

使用给定参数、初始状态和元数据创建差速机器人。参数省略或为 `[]` 时，分别使用随附 YAML 参数、七个零状态和默认元数据。初始轮速不会被限幅或受 `maxWheelSpeed` 限制。两个保持指令从零开始，因此非零初始轮速在未发送新目标时会衰减。每次构造调用创建独立的 `handle` 对象。

- **参数：**
    - `Params` （可选）
        - 类型： 包含全部七个必需参数字段的标量 `struct`，或 `[]`
        - 另见： [<u>属性 `Params`</u>](Properties.md#3-params)
    - `Ini_States` （可选）
        - 类型： 有限实数的七元素数值行向量或列向量，或 `[]`；规范为 `7x1 double`
        - 顺序与单位： `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`，单位为 `[m; m; rad; rad; rad/s; rad; rad/s]`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states)
    - `Metadata` （可选）
        - 类型： 标量 `struct`，或 `[]`；缺失的默认字段会补齐，但不校验各字段类型
        - 另见： [<u>属性 `Metadata`</u>](Properties.md#1-metadata)
- **返回值：**
    - `obj`
        - 类型： `rpm.wheel_robot` 句柄对象
- **另见：** [<u>方法 `reset()`</u>](#resetini_states), [<u>方法 `getParams()`</u>](#getparams)
- **用法：**
    ```matlab
    % Use default parameters
    robot = rpm.wheel_robot();
    ```

    ```matlab
    % Use custom parameters; left and right values may differ
    Params = rpm.load_wheel_params();
    Params.wheelRadius = [0.08; 0.12];
    robot = rpm.wheel_robot(Params);
    ```

    ```matlab
    % Use initial states and metadata; wheel angles and speeds are interleaved
    Ini_States = [10; -10; -pi/2; 0; 2; 0; 2];
    Metadata = struct('Name', 'WheelBot', 'Number', '001', ...
                      'Description', 'My differential-drive robot.');
    robot = rpm.wheel_robot([], Ini_States, Metadata);
    ```

### `reset(ini_states)` {#resetini_states}

将机器人重置为给定状态；`ini_states` 省略或为 `[]` 时使用零状态。成功重置会清除两个保持轮速指令和步长警告标记，保留参数、元数据及配置。维度非法或包含非有限值、复数的输入会在改变对象前被拒绝；有限的初始轮速即使超过指令边界也会保留。

- **参数：**
    - `ini_states` （可选）
        - 类型： 有限实数的七元素数值行向量或列向量，或 `[]`；规范为 `7x1 double`
        - 顺序与单位： `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`，单位为 `[m; m; rad; rad; rad/s; rad; rad/s]`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states)
- **返回值：** 无
- **另见：** [<u>属性 `Cmd`</u>](Properties.md#4-cmd), [<u>属性 `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive), [<u>方法 `rpm.wheel_robot()`</u>](#rpm-wheel-robot)
- **用法：**
    ```matlab
    robot = rpm.wheel_robot();
    robot.sendCmd(4, 6);
    robot.step(0.005);
    robot.reset(); % Zero states and zero held commands
    robot.reset([1, -1, pi/2, 0, 2, 0, 2]); % Or custom initial states
    ```

## 2. `Get` {#2-get}

### `getStates` {#getstates}

返回当前七个动态状态 `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`。前三项描述驱动轴中点的世界系位姿，后四项为交错排列的实际车轮转角和转速，而非指令目标。读取或修改返回向量不会改变机器人。

- **参数：** 无
- **返回值：**
    - `states`
        - 类型： `7x1 double`
        - 顺序与单位： `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`，单位为 `[m; m; rad; rad; rad/s; rad; rad/s]`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states)
- **用法：**
    ```matlab
    states = robot.getStates();
    x = states(1); y = states(2); theta = states(3);
    alpha_L = states(4); Omega_L = states(5);
    alpha_R = states(6); Omega_R = states(7);
    fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', x, y, theta);
    fprintf('Left wheel: angle=%f rad, speed=%f rad/s\n', alpha_L, Omega_L);
    fprintf('Right wheel: angle=%f rad, speed=%f rad/s\n', alpha_R, Omega_R);
    ```

### `getCmd` {#getcmd}

返回当前保持的限幅后左右轮速目标。后续 `step()` 使用这些目标，直到下一次 `sendCmd()` 或 `reset()`；它们可能与实际轮速不同。虽然私有 `Cmd` 属性是结构体，此方法返回数值列向量。

- **参数：** 无
- **返回值：**
    - `cmd`
        - 类型： `2x1 double`
        - 顺序与单位： `[left_wheel_cmd; right_wheel_cmd]`，单位均为 `rad/s`
        - 另见： [<u>属性 `Cmd`</u>](Properties.md#4-cmd), [<u>方法 `getWheelSpeed()`</u>](#getwheelspeed)
- **用法：**
    ```matlab
    cmd = robot.getCmd();
    fprintf('Held command: left=%f rad/s, right=%f rad/s\n', cmd(1), cmd(2));
    ```

### `getPose` {#getpose}

返回驱动轴中点当前在世界坐标系中的位姿。航向角从世界 x 轴起逆时针计量，默认持续累积；启用航向角归一化后，每次 `step()` 将其归一化到 `[-pi, pi)`。车体的显示偏移不改变该参考点。

- **参数：** 无
- **返回值：**
    - `pose`
        - 类型： `3x1 double`
        - 顺序与单位： `[x; y; theta]`，单位为 `[m; m; rad]`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states), [<u>属性 `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **用法：**
    ```matlab
    pose = robot.getPose();
    fprintf('Robot pose: x=%f m, y=%f m, theta=%f rad\n', ...
            pose(1), pose(2), pose(3));
    ```

### `getVel` {#getvel}

由实际轮速而非目标指令计算驱动轴中点的瞬时车体速度。前进速度带符号，正横摆角速度表示逆时针转动：`v = (r_L * Omega_L + r_R * Omega_R) / 2`，`omega = (r_R * Omega_R - r_L * Omega_L) / trackWidth`。模型支持倒车和原地旋转。

- **参数：** 无
- **返回值：**
    - `velocity`
        - 类型： `2x1 double`
        - 顺序与单位： `[v; omega]`，单位为 `[m/s; rad/s]`
        - 另见： [<u>方法 `getWheelSpeed()`</u>](#getwheelspeed), [<u>方法 `wheel2body()`</u>](#wheel2bodywheel_speed), [<u>方法 `getPoseDot()`</u>](#getposedot)
- **用法：**
    ```matlab
    velocity = robot.getVel();
    fprintf('Body velocity: v=%f m/s, omega=%f rad/s\n', ...
            velocity(1), velocity(2));
    ```

### `getPoseDot` {#getposedot}

返回世界坐标系下的瞬时位姿导数 `[v*cos(theta); v*sin(theta); omega]`。横摆角速度是物理角速度，不包含航向角归一化导致的数值跳变。此方法只读取当前状态，不推进仿真。

- **参数：** 无
- **返回值：**
    - `pos_derivative`
        - 类型： `3x1 double`
        - 顺序与单位： `[x_dot; y_dot; theta_dot]`，单位为 `[m/s; m/s; rad/s]`
        - 另见： [<u>方法 `getPose()`</u>](#getpose), [<u>方法 `getVel()`</u>](#getvel)
- **用法：**
    ```matlab
    pose_derivative = robot.getPoseDot();
    fprintf('Pose derivative: x_dot=%f m/s, y_dot=%f m/s, theta_dot=%f rad/s\n', ...
            pose_derivative(1), pose_derivative(2), pose_derivative(3));
    ```

### `getWheelSpeed` {#getwheelspeed}

返回左右车轮的实际角速度，正值表示向前滚动。各轮速通过自身一阶响应跟踪保持目标，因此不一定等于 `getCmd()`。此方法读取状态 `5`、`7`，不对其限幅。

- **参数：** 无
- **返回值：**
    - `wheel_speed`
        - 类型： `2x1 double`
        - 顺序与单位： `[left_wheel_speed; right_wheel_speed]`，单位均为 `rad/s`
        - 另见： [<u>属性 `States(5)` / `States(7)`</u>](Properties.md#states5-states7), [<u>方法 `getCmd()`</u>](#getcmd), [<u>属性 `Params.motorTimeConstant`</u>](Properties.md#paramsmotortimeconstant)
- **用法：**
    ```matlab
    wheel_speed = robot.getWheelSpeed();
    fprintf('Actual wheel speeds: left=%f rad/s, right=%f rad/s\n', ...
            wheel_speed(1), wheel_speed(2));
    ```

### `getWheelAngle` {#getwheelangle}

返回左右车轮由实际轮速积分得到的累计转角，正值表示向前滚动。与可选的航向角归一化不同，车轮转角永远不会按 `2*pi` 归一化，因此完整转圈数可用于里程计或编码器式计算。

- **参数：** 无
- **返回值：**
    - `wheel_angle`
        - 类型： `2x1 double`
        - 顺序与单位： `[left_wheel_angle; right_wheel_angle]`，单位均为 `rad`
        - 另见： [<u>属性 `States(4)` / `States(6)`</u>](Properties.md#states4-states6), [<u>方法 `getWheelSpeed()`</u>](#getwheelspeed)
- **用法：**
    ```matlab
    wheel_angle = robot.getWheelAngle();
    fprintf('Accumulated wheel angles: left=%f rad, right=%f rad\n', ...
            wheel_angle(1), wheel_angle(2));
    ```

### `getParams` {#getparams}

返回机器人当前使用的物理及显示参数副本。返回值包含数值规范化结果、成对车轮标量输入的展开结果，以及构造函数替换后的零时间常数。修改副本不改变机器人；如需使用其他参数，请创建新对象。轮速指令上限位于 `params.maxWheelSpeed`；该类没有单独的 `getCmdLimits()` 方法。

- **参数：** 无
- **返回值：**
    - `params`
        - 类型： 标量 `struct`
        - 另见： [<u>属性 `Params`</u>](Properties.md#3-params), [<u>属性 `Params.maxWheelSpeed`</u>](Properties.md#paramsmaxwheelspeed)
- **用法：**
    ```matlab
    params = robot.getParams();
    fprintf('Wheel radii: left=%f m, right=%f m\n', ...
            params.wheelRadius(1), params.wheelRadius(2));
    fprintf('Command limits: left=+/- %f rad/s, right=+/- %f rad/s\n', ...
            params.maxWheelSpeed(1), params.maxWheelSpeed(2));
    fprintf('Body size: length=%f m, width=%f m, height=%f m\n', ...
            params.bodySize(1), params.bodySize(2), params.bodySize(3));
    ```

## 3. `Set` {#3-set}

### `setSolutionMethod(solution_method)` {#setsolutionmethodsolution_method}

选择后续 `step()` 使用的固定步长积分方法。名称不区分大小写，保存为 `'euler'` 或 `'RK4'`。成功设置会清除步长警告标记，不改变状态或指令；非法输入触发 `wheel_robot:InvalidSolutionMethod`，配置保持不变。

- **参数：**
    - `solution_method`
        - 类型： 字符行向量或字符串标量
        - 可选值： `'euler'`, `'RK4'` （不区分大小写）；拒绝 missing 字符串
        - 另见： [<u>属性 `Config.solution_method`</u>](Properties.md#configsolution_method)
- **返回值：** 无
- **另见：** [<u>方法 `step()`</u>](#stepdt-t), [<u>属性 `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive)
- **用法：**
    ```matlab
    robot.setSolutionMethod('euler');
    robot.setSolutionMethod('RK4'); % Switch back to the default method
    ```

### `setWrapHeading(wrap_heading)` {#setwrapheadingwrap_heading}

启用或禁用每次完整积分步结束后的航向角归一化。启用时不会立即改变当前航向；后续积分步将其映射到 `[-pi, pi)`。归一化会丢弃完整转圈数，之后禁用此选项也无法恢复。 累计车轮转角不受影响。

- **参数：**
    - `wrap_heading`
        - 类型： `logical` 标量
        - 可选值： `true` 或 `false` （不接受数值 `1` 和 `0`）
        - 另见： [<u>属性 `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **返回值：** 无
- **另见：** [<u>方法 `step()`</u>](#stepdt-t), [<u>方法 `getPose()`</u>](#getpose), [<u>方法 `getWheelAngle()`</u>](#getwheelangle)
- **用法：**
    ```matlab
    robot.setWrapHeading(true);  % Wrap heading after subsequent steps
    robot.setWrapHeading(false); % Preserve accumulated heading thereafter
    ```

### `setWarnOnSaturation(warn_on_saturation)` {#setwarnonsaturationwarn_on_saturation}

控制每次指令限幅时是否发出 `wheel_robot:CommandSaturated`。禁用该警告不会禁用限幅，也不会抑制独立的零时间常数和大步长警告。此方法仅修改该配置选项。 状态和保持目标不变。

- **参数：**
    - `warn_on_saturation`
        - 类型： `logical` 标量
        - 可选值： `true` 或 `false` （不接受数值 `1` 和 `0`）
        - 另见： [<u>属性 `Config.warn_on_saturation`</u>](Properties.md#configwarn_on_saturation)
- **返回值：** 无
- **另见：** [<u>方法 `sendCmd()`</u>](#sendcmdleft_wheel_cmd-right_wheel_cmd)
- **用法：**
    ```matlab
    robot.setWarnOnSaturation(false); % Suppress command-clipping warnings
    robot.setWarnOnSaturation(true);  % Enable them again
    ```

## 4. `Send` {#4-send}

### `sendCmd(left_wheel_cmd, right_wheel_cmd)` {#sendcmdleft_wheel_cmd-right_wheel_cmd}

发送并保持左右轮速目标，正值表示向前滚动。各输入转换为 `double`，并独立限幅到对应的 `[-maxWheelSpeed(i), maxWheelSpeed(i)]`。此调用只更新保持指令，不改变实际轮速、转角或位姿。之后每次 `step()` 均使用这些目标，直到下一次发送或重置；零目标产生一阶减速，而非瞬时停车。

- **参数：**
    - `left_wheel_cmd`
        - 类型： 有限实数数值标量
        - 单位： `rad/s`
    - `right_wheel_cmd`
        - 类型： 有限实数数值标量
        - 单位： `rad/s`
- **返回值：** 无
- **另见：** [<u>属性 `Cmd`</u>](Properties.md#4-cmd), [<u>属性 `Params.maxWheelSpeed`</u>](Properties.md#paramsmaxwheelspeed), [<u>方法 `getCmd()`</u>](#getcmd), [<u>方法 `setWarnOnSaturation()`</u>](#setwarnonsaturationwarn_on_saturation), [<u>方法 `step()`</u>](#stepdt-t)
- **用法：**
    ```matlab
    robot.sendCmd(4, 6); % Set left and right wheel-speed targets
    cmd = robot.getCmd(); % Read the applied targets after clipping
    fprintf('Applied command: left=%f rad/s, right=%f rad/s\n', ...
            cmd(1), cmd(2));
    ```

## 5. 运行 {#5-running}

### `step(dt, t)` {#stepdt-t}

使用保持指令和选定的欧拉法或 RK4 法，将全部七个动态状态推进一个固定步长。RK4 四个阶段使用相同指令和各阶段的中间状态；如启用航向角归一化，则仅在完整积分步结束后进行。方程为自治系统，因此 `t` 不影响结果，模型内部也不维护仿真时钟。此方法不改变 `Cmd`，也不对轮速状态限幅。

建议根据 `getParams()` 返回的实际参数选择 `dt <= 0.1 * min(params.motorTimeConstant)`。进入较大步长范围时会发出一次 `wheel_robot:LargeStepSize`，但不会停止积分或调整 `dt`。对于每个一阶轮速模态，欧拉法的线性稳定条件为 `dt < 2*T_i`，RK4 约为 `dt < 2.785*T_i`；稳定性本身不保证精度。[<u>轮式机器人模型</u>](../Modeling/wheel-robot-model.md)页面为详细理论推导预留，目前尚未编写。

- **参数：**
    - `dt`
        - 类型： 有限、严格为正的实数数值标量
        - 单位： `s`
    - `t` （可选）
        - 类型： 有限实数数值标量，或 `[]`
        - 含义： 本积分步的起始时间，单位为 `s`；省略或为 `[]` 时取 `0`
- **返回值：** 无
- **另见：** [<u>属性 `States`</u>](Properties.md#2-states), [<u>属性 `Config`</u>](Properties.md#5-config), [<u>属性 `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive), [<u>方法 `sendCmd()`</u>](#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>方法 `stateDerivative()`</u>](#statederivativez-u-t)
- **用法：**
    ```matlab
    robot = rpm.wheel_robot();
    params = robot.getParams();
    dt = 0.05 * min(params.motorTimeConstant);
    robot.sendCmd(4, 6);
    for k = 1:100
        t = (k - 1) * dt; % Maintain simulation time externally
        robot.step(dt, t);
    end
    pose = robot.getPose();
    fprintf('Final pose: x=%f m, y=%f m, theta=%f rad\n', ...
            pose(1), pose(2), pose(3));
    ```

## 6. 其他 {#6-other}

### `body2wheel(body_velocity)` {#body2wheelbody_velocity}

将给定的有符号前进速度和逆时针横摆角速度转换为左右车轮角速度。该代数转换仅读取物理参数，不读取或改变当前状态，也不执行限幅。支持原地旋转（`v = 0`、`omega ~= 0`）。设左右轮半径为 $r_L$、$r_R$，轮距为 $L$：

$$
\begin{aligned}
\Omega_L &= \frac{v-\omega L/2}{r_L}, \\
\Omega_R &= \frac{v+\omega L/2}{r_R}.
\end{aligned}
$$

通过 `sendCmd()` 发送结果时，任一轮都可能被独立限幅，从而改变请求的车体速度。实际车体速度还取决于一阶轮速响应。[<u>轮式机器人模型</u>](../Modeling/wheel-robot-model.md)页面为详细理论推导预留，目前尚未编写。

- **参数：**
    - `body_velocity`
        - 类型： 有限实数的二元素数值行向量或列向量
        - 顺序与单位： `[v; omega]`，单位为 `[m/s; rad/s]`
- **返回值：**
    - `wheel_speed`
        - 类型： `2x1 double`
        - 顺序与单位： `[Omega_L; Omega_R]`，单位均为 `rad/s`
- **另见：** [<u>方法 `wheel2body()`</u>](#wheel2bodywheel_speed), [<u>方法 `sendCmd()`</u>](#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>方法 `kin_inv()`</u>](#kin_inv), [<u>属性 `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>属性 `Params.trackWidth`</u>](Properties.md#paramstrackwidth)
- **用法：**
    ```matlab
    wheel_cmd = robot.body2wheel([0.5; 0.2]);
    fprintf('Wheel targets: left=%f rad/s, right=%f rad/s\n', ...
            wheel_cmd(1), wheel_cmd(2));
    robot.sendCmd(wheel_cmd(1), wheel_cmd(2)); % Clipping occurs here
    ```

### `wheel2body(wheel_speed)` {#wheel2bodywheel_speed}

将给定的左右车轮角速度转换为驱动轴中点的有符号前进速度及逆时针横摆角速度。该代数转换仅读取物理参数，不读取机器人的状态或保持指令，也不执行限幅。设左右轮半径为 $r_L$、$r_R$，轮距为 $L$：

$$
\begin{aligned}
v &= \frac{r_L\Omega_L+r_R\Omega_R}{2}, \\
\omega &= \frac{r_R\Omega_R-r_L\Omega_L}{L}.
\end{aligned}
$$

转向方向取决于两轮*线速度*之差；当半径不同时，不能只比较角速度。[<u>轮式机器人模型</u>](../Modeling/wheel-robot-model.md)页面为详细理论推导预留，目前尚未编写。

- **参数：**
    - `wheel_speed`
        - 类型： 有限实数的二元素数值行向量或列向量
        - 顺序与单位： `[Omega_L; Omega_R]`，单位均为 `rad/s`
- **返回值：**
    - `body_velocity`
        - 类型： `2x1 double`
        - 顺序与单位： `[v; omega]`，单位为 `[m/s; rad/s]`
- **另见：** [<u>方法 `body2wheel()`</u>](#body2wheelbody_velocity), [<u>方法 `getVel()`</u>](#getvel), [<u>方法 `kin_fwd()`</u>](#kin_fwd), [<u>属性 `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>属性 `Params.trackWidth`</u>](Properties.md#paramstrackwidth)
- **用法：**
    ```matlab
    body_velocity = robot.wheel2body([4; 6]);
    fprintf('Converted body velocity: v=%f m/s, omega=%f rad/s\n', ...
            body_velocity(1), body_velocity(2));
    ```

## 7.* 私有方法 {#7-private-methods}

### `validateParams(Params)` {#validateparamsparams}

内部方法：校验标量参数结构体，并规范七个必需数值字段。成对车轮参数的标量输入展开为 `2x1` 向量；额外结构体字段予以保留。零电机时间常数替换为 `1e-3` s，并发出 `wheel_robot:ZeroMotorTimeConstant`；缺失或非法字段被拒绝。此方法不读取 YAML，也不校验初始状态。

- **参数：** `Params` — 包含全部必需字段的标量 `struct`
- **返回值：** `Params` — 经校验和规范的标量 `struct`
- **另见：** [<u>属性 `Params`</u>](Properties.md#3-params), [<u>方法 `rpm.wheel_robot()`</u>](#rpm-wheel-robot)

### `stateDerivative(z, u, t)` {#statederivativez-u-t}

内部方法：在当前状态或 RK4 中间状态处，使用保持的轮速指令向量 $u = [\Omega_{L,\mathrm{cmd}}, \Omega_{R,\mathrm{cmd}}]^\mathsf{T}$ 计算七个连续状态导数。$r_L$、$r_R$ 表示轮半径，$L$ 表示轮距，$T_L$、$T_R$ 表示两侧电机时间常数：

$$
\dot z = \begin{bmatrix}
\dfrac{r_L z_5+r_R z_7}{2}\cos z_3 \\[6pt]
\dfrac{r_L z_5+r_R z_7}{2}\sin z_3 \\[6pt]
\dfrac{r_R z_7-r_L z_5}{L} \\[6pt]
z_5 \\[4pt]
\dfrac{u_1-z_5}{T_L} \\[6pt]
z_7 \\[4pt]
\dfrac{u_2-z_7}{T_R}
\end{bmatrix}.
$$

[<u>轮式机器人模型</u>](../Modeling/wheel-robot-model.md)页面为详细理论推导预留，目前尚未编写。

- **参数：** `z` — `7x1` 状态向量；`u` — `2x1` 保持轮速指令，顺序为 `[left; right]`；`t` — 阶段时间，单位为秒（当前未使用）
- **返回值：** `dz` — `7x1 double`，单位为 `[m/s; m/s; rad/s; rad/s; rad/s^2; rad/s; rad/s^2]`
- **另见：** [<u>方法 `step()`</u>](#stepdt-t), [<u>属性 `States`</u>](Properties.md#2-states), [<u>属性 `Cmd`</u>](Properties.md#4-cmd)

### `kin_fwd` {#kin_fwd}

内部方法：构造满足 `[v; omega] = Mr * [Omega_L; Omega_R]` 的 `2x2` 正运动学矩阵。它支持不同轮半径，由校验后的半径及轮距计算，不读取或改变运动状态。对应方程见 `wheel2body()`。

- **参数：** 无
- **返回值：** `Mr` — `2x2 double` 正运动学矩阵
- **另见：** [<u>方法 `wheel2body()`</u>](#wheel2bodywheel_speed), [<u>方法 `kin_inv()`</u>](#kin_inv), [<u>属性 `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>属性 `Params.trackWidth`</u>](Properties.md#paramstrackwidth)

### `kin_inv` {#kin_inv}

内部方法：构造满足 `[Omega_L; Omega_R] = Mr_inv * [v; omega]` 的 `2x2` 解析逆运动学矩阵。它与 `kin_fwd()` 使用相同的车轮顺序和符号约定，不进行数值矩阵求逆或限幅。对应方程见 `body2wheel()`。

- **参数：** 无
- **返回值：** `Mr_inv` — `2x2 double` 逆运动学矩阵
- **另见：** [<u>方法 `body2wheel()`</u>](#body2wheelbody_velocity), [<u>方法 `kin_fwd()`</u>](#kin_fwd), [<u>属性 `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>属性 `Params.trackWidth`</u>](Properties.md#paramstrackwidth)
