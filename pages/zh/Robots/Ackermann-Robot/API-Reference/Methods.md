# 阿克曼机器人方法 {#ackermann-robot-methods}

> **提示：** 带 `'*'` 的小节表示私有项。

## 1. 初始化 {#1-initialization}

通过构造函数创建具有独立物理参数、初始状态和元数据的机器人。通过 `reset()` 重置已有机器人，而不改变参数或仿真配置；两种操作均不推进仿真时间。

### `rpm.ackermann_robot(Params, Ini_States, Metadata)` {#rpm-ackermann-robot}

使用给定参数、初始状态和元数据创建阿克曼机器人。参数省略或为 `[]` 时，分别使用随附 YAML 参数、五个零状态和默认元数据。初始状态会经过校验而非限幅；两个保持指令从零开始，即使初始执行器状态非零。

- **参数：**
    - `Params` （可选）
        - 类型： `struct`
        - 另见： [<u>属性 `Params`</u>](Properties.md#3-params)
    - `Ini_States` （可选）
        - 类型： `5x1 double`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states)
    - `Metadata` （可选）
        - 类型： `struct`
        - 另见： [<u>属性 `Metadata`</u>](Properties.md#1-metadata)
- **返回值：**
    - `rpm.ackermann_robot`
        - 类型： `object`
- **用法：**
    ```matlab
    % Use default parameters
    robot = rpm.ackermann_robot();
    ```

    ```matlab
    % Use custom parameters
    Params = rpm.utils.load_ackermann_params();   % get default parameters
    Params.maxPhysicalSteeringAngle = 0.5;  % change parameter(s)
    robot = rpm.ackermann_robot(Params);    % use modified parameters
    ```

    ```matlab
    % Use initial states and metadata
    Ini_States = [10; -10; -pi/2; 0; 0];    % custom initial states
    Metadata = struct('Name', 'Robert', 'Number', '001', ...
                      'Description', 'My beloved robot.');   % custom metadata
    robot = rpm.ackermann_robot([], Ini_States, Metadata);
    ```

### `reset(ini_states)` {#resetini_states}

将机器人重置为给定状态；`ini_states` 省略或为 `[]` 时使用零状态。成功重置会清除保持指令和步长警告标记，保留参数、元数据及配置。非法初始状态会被拒绝，不改变机器人，也不会限幅。

- **参数：**
    - `ini_states` （可选）
        - 类型： `5x1 double`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states)
- **返回值：** 无
- **用法：**
    ```matlab
    robot = rpm.ackermann_robot();

    % do something ...
    % ...
    % ...

    robot.reset();    % Reset to zero-states
    robot.reset([1,-1,pi/2,0,0]);   % or custom initial states
    ```

## 2. `Get` {#2-get}

### `getStates` {#getstates}

返回当前五个动态状态 `[x; y; theta; delta; Omega]`，单位为 `[m; m; rad; rad; rad/s]`。前三项描述后轴中点的世界系位姿，后两项为实际虚拟执行器状态而非指令。读取或修改返回向量不会改变机器人。

- **参数：** 无
- **返回值：**
    - `States`
        - 类型： `5x1 double`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states)
- **用法：**
    ```matlab
    states = robot.getStates();
    x = states(1); y = states(2); theta = states(3);
    delta = states(4); Omega = states(5);   % semantics of states
    fprintf('Robot states: x=%f, y=%f, theta=%f, delta=%f, Omega=%f\n',...
            x, y, theta, delta, Omega);
    ```

### `getCmd` {#getcmd}

返回当前保持的限幅后虚拟执行器指令。后续 `step()` 使用这些目标，直到下一次 `sendCmd()` 或 `reset()`；它们可能与实际执行器状态不同。

- **参数：** 无
- **返回值：**
    - `cmd`
        - 类型： `2x1 double`
        - 顺序与单位： `[steering_angle_cmd; wheel_speed_cmd]`，单位为 `[rad; rad/s]`
        - 另见： [<u>属性 `Cmd`</u>](Properties.md#4-cmd), [<u>方法 `getStates`</u>](#getstates)
- **用法：**
    ```matlab
    cmd = robot.getCmd();
    delta_c = cmd(1); Omega_c = cmd(2);
    fprintf('Held command: delta_c=%f rad, Omega_c=%f rad/s\n', ...
            delta_c, Omega_c);
    ```

### `getPose` {#getpose}

返回后轴中点当前在世界坐标系中的位姿。航向角从世界 x 轴起逆时针计量，默认持续累积；启用航向角归一化后，每次 `step()` 将其归一化到 `[-pi, pi)`。

- **参数：** 无
- **返回值：**
    - `pose`
        - 类型： `3x1 double`
        - 顺序与单位： `[x; y; theta]`，单位为 `[m; m; rad]`
        - 另见： [<u>属性 `States`</u>](Properties.md#2-states), [<u>属性 `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **用法：**
    ```matlab
    pose = robot.getPose();
    x = pose(1); y = pose(2); theta = pose(3);
    fprintf('Robot pose: x=%f m, y=%f m, theta=%f rad\n', ...
            x, y, theta);
    ```

### `getVel` {#getvel}

由实际虚拟执行器状态而非指令计算后轴中点的瞬时车体速度。前进速度带符号，正横摆角速度表示逆时针转动：`v = wheelRadius * Omega`，`omega = v * tan(delta) / wheelBase`。

- **参数：** 无
- **返回值：**
    - `velocity`
        - 类型： `2x1 double`
        - 顺序与单位： `[v; omega]`，单位为 `[m/s; rad/s]`
        - 另见： [<u>方法 `getVirtualSteeringAngle`</u>](#getvirtualsteeringangle), [<u>方法 `getVirtualWheelSpeed`</u>](#getvirtualwheelspeed), [<u>方法 `getPoseDot`</u>](#getposedot), [<u>方法 `virtual2body()`</u>](#virtual2bodyvirtual_state)
- **用法：**
    ```matlab
    velocity = robot.getVel();
    v = velocity(1); omega = velocity(2);
    fprintf('Body velocity: v=%f m/s, omega=%f rad/s\n', v, omega);
    ```

### `getPoseDot` {#getposedot}

返回世界坐标系下的瞬时位姿导数 `[v*cos(theta); v*sin(theta); omega]`。横摆角速度是物理角速度，不包含航向角归一化导致的数值跳变。此方法只读取当前状态，不推进仿真。

- **参数：** 无
- **返回值：**
    - `pose_derivative`
        - 类型： `3x1 double`
        - 顺序与单位： `[x_dot; y_dot; theta_dot]`，单位为 `[m/s; m/s; rad/s]`
        - 另见： [<u>方法 `getPose`</u>](#getpose), [<u>方法 `getVel`</u>](#getvel)
- **用法：**
    ```matlab
    pose_derivative = robot.getPoseDot();
    x_dot = pose_derivative(1); y_dot = pose_derivative(2);
    theta_dot = pose_derivative(3);
    fprintf('Pose derivative: x_dot=%f m/s, y_dot=%f m/s, theta_dot=%f rad/s\n', ...
            x_dot, y_dot, theta_dot);
    ```

### `getVirtualSteeringAngle` {#getvirtualsteeringangle}

返回实际虚拟前轮转角，正值表示左转。由于一阶转向响应，该值可能与保持的转向指令不同。

- **参数：** 无
- **返回值：**
    - `delta`
        - 类型： `double` 标量
        - 单位： `rad`
        - 另见： [<u>属性 `States(4)` / `States(5)`</u>](Properties.md#states4-states5), [<u>方法 `getCmd`</u>](#getcmd), [<u>方法 `getPhysicalSteeringAngle`</u>](#getphysicalsteeringangle)
- **用法：**
    ```matlab
    delta = robot.getVirtualSteeringAngle();
    fprintf('Virtual steering angle: delta=%f rad\n', delta);
    ```

### `getVirtualWheelSpeed` {#getvirtualwheelspeed}

返回实际虚拟车轮角速度，正值表示前进。由于一阶轮速响应，该值可能与保持的轮速指令不同。

- **参数：** 无
- **返回值：**
    - `Omega`
        - 类型： `double` 标量
        - 单位： `rad/s`
        - 另见： [<u>属性 `States(4)` / `States(5)`</u>](Properties.md#states4-states5), [<u>方法 `getCmd`</u>](#getcmd), [<u>方法 `getPhysicalWheelSpeed`</u>](#getphysicalwheelspeed)
- **用法：**
    ```matlab
    Omega = robot.getVirtualWheelSpeed();
    fprintf('Virtual wheel speed: Omega=%f rad/s\n', Omega);
    ```

### `getPhysicalSteeringAngle` {#getphysicalsteeringangle}

通过阿克曼几何，由当前虚拟转角计算并返回左右实际前轮转角。正值表示左转。这些转角不是独立动态状态，也不会分别限幅。

- **参数：** 无
- **返回值：**
    - `steering_angles`
        - 类型： `2x1 double`
        - 顺序与单位： `[left_front; right_front]`，单位均为 `rad`
        - 另见： [<u>方法 `getVirtualSteeringAngle`</u>](#getvirtualsteeringangle), [<u>属性 `Params.wheelBase`</u>](Properties.md#paramswheelbase), [<u>属性 `Params.trackWidth`</u>](Properties.md#paramstrackwidth), [<u>方法 `physicalWheelMap()`</u>](#physicalwheelmapz)
- **用法：**
    ```matlab
    steering_angles = robot.getPhysicalSteeringAngle();
    delta_lf = steering_angles(1); delta_rf = steering_angles(2);
    fprintf('Physical steering angles: left_front=%f rad, right_front=%f rad\n', ...
            delta_lf, delta_rf);
    ```

### `getPhysicalWheelSpeed` {#getphysicalwheelspeed}

在纯滚动假设下，由当前虚拟转角和轮速计算并返回全部四个实际车轮角速度。正值表示向前滚动。这些轮速不是独立动态状态，也不会分别限幅。

- **参数：** 无
- **返回值：**
    - `wheel_speeds`
        - 类型： `4x1 double`
        - 顺序与单位： `[left_front; right_front; left_rear; right_rear]`，单位均为 `rad/s`
        - 另见： [<u>方法 `getVirtualSteeringAngle`</u>](#getvirtualsteeringangle), [<u>方法 `getVirtualWheelSpeed`</u>](#getvirtualwheelspeed), [<u>方法 `physicalWheelMap()`</u>](#physicalwheelmapz)
- **用法：**
    ```matlab
    wheel_speeds = robot.getPhysicalWheelSpeed();
    Omega_lf = wheel_speeds(1); Omega_rf = wheel_speeds(2);
    Omega_lr = wheel_speeds(3); Omega_rr = wheel_speeds(4);
    fprintf(['Physical wheel speeds (rad/s): left_front=%f, right_front=%f, ' ...
             'left_rear=%f, right_rear=%f\n'], ...
            Omega_lf, Omega_rf, Omega_lr, Omega_rr);
    ```

### `getParams` {#getparams}

返回机器人当前使用的物理及显示参数副本。返回值包含数值规范化结果和构造函数替换后的零时间常数。修改副本不改变机器人；如需使用其他参数，请创建新对象。

- **参数：** 无
- **返回值：**
    - `params`
        - 类型： 标量 `struct`
        - 另见： [<u>属性 `Params`</u>](Properties.md#3-params)
- **用法：**
    ```matlab
    params = robot.getParams();
    radius = params.wheelRadius;
    body_size = params.bodySize;
    fprintf('Wheel radius: %f m\n', radius);
    fprintf('Body size: length=%f m, width=%f m, height=%f m\n', ...
            body_size(1), body_size(2), body_size(3));
    ```

### `getCmdLimits` {#getcmdlimits}

返回定义对称保守瞬态矩形范围的正虚拟执行器上限。`sendCmd()` 将每个目标限幅到对应 `[-limit, limit]`；构造函数和 `reset()` 要求初始虚拟执行器状态位于相同范围内（含边界）。轮速上限是保守值，与当前转角无关。该方法仅读取参数，不改变状态或指令。

- **参数：** 无
- **返回值：**
    - `limits`
        - 类型： `2x1 double`
        - 顺序与单位： `[virtual_steering_limit; virtual_wheel_speed_limit]`，单位为 `[rad; rad/s]`
        - 另见： [<u>属性 `Params.maxPhysicalSteeringAngle`</u>](Properties.md#paramsmaxphysicalsteeringangle), [<u>属性 `Params.maxPhysicalWheelSpeed`</u>](Properties.md#paramsmaxphysicalwheelspeed), [<u>方法 `reset`</u>](#resetini_states), [<u>方法 `sendCmd()`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>方法 `commandLimits()`</u>](#commandlimits)
- **用法：**
    ```matlab
    limits = robot.getCmdLimits();
    steering_range = [-limits(1), limits(1)];
    wheel_speed_range = [-limits(2), limits(2)];
    fprintf('Virtual steering range: [%f, %f] rad\n', ...
            steering_range(1), steering_range(2));
    fprintf('Virtual wheel-speed range: [%f, %f] rad/s\n', ...
            wheel_speed_range(1), wheel_speed_range(2));
    ```

## 3. `Set` {#3-set}

### `setSolutionMethod(solution_method)` {#setsolutionmethodsolution_method}

选择后续 `step()` 使用的固定步长积分方法。名称不区分大小写，保存为 `'euler'` 或 `'RK4'`。成功设置会清除步长警告标记，不改变状态或指令；非法输入触发 `ackermann_robot:InvalidSolutionMethod`，配置保持不变。

- **参数：**
    - `solution_method`
        - 类型： 字符行向量或字符串标量
        - 可选值： `'euler'`, `'RK4'` （不区分大小写）
        - 另见： [<u>属性 `Config.solution_method`</u>](Properties.md#configsolution_method)
- **返回值：** 无
- **另见：** [<u>方法 `step`</u>](#stepdt-t), [<u>属性 `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive)
- **用法：**
    ```matlab
    robot.setSolutionMethod('euler');
    robot.setSolutionMethod('RK4'); % Switch back to the default method
    ```

### `setWrapHeading(wrap_heading)` {#setwrapheadingwrap_heading}

启用或禁用每次完整积分步结束后的航向角归一化。启用时不会立即改变当前航向；后续积分步将其映射到 `[-pi, pi)`。归一化会丢弃完整转圈数，之后禁用此选项也无法恢复。

- **参数：**
    - `wrap_heading`
        - 类型： `logical` 标量
        - 可选值： `true` 或 `false` （不接受数值 `1` 和 `0`）
        - 另见： [<u>属性 `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **返回值：** 无
- **另见：** [<u>方法 `step`</u>](#stepdt-t), [<u>方法 `getPose`</u>](#getpose)
- **用法：**
    ```matlab
    robot.setWrapHeading(true);  % Wrap heading after subsequent steps
    robot.setWrapHeading(false); % Preserve accumulated heading thereafter
    ```

### `setWarnOnSaturation(warn_on_saturation)` {#setwarnonsaturationwarn_on_saturation}

控制每次指令限幅时是否发出 `ackermann_robot:CommandSaturated`。禁用该警告不会禁用限幅，也不会抑制独立的零时间常数和大步长警告。此方法仅修改该配置选项。

- **参数：**
    - `warn_on_saturation`
        - 类型： `logical` 标量
        - 可选值： `true` 或 `false` （不接受数值 `1` 和 `0`）
        - 另见： [<u>属性 `Config.warn_on_saturation`</u>](Properties.md#configwarn_on_saturation)
- **返回值：** 无
- **另见：** [<u>方法 `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd)
- **用法：**
    ```matlab
    robot.setWarnOnSaturation(false); % Suppress command-clipping warnings
    robot.setWarnOnSaturation(true);  % Enable them again
    ```

## 4. `Send` {#4-send}

### `sendCmd(steering_angle_cmd, wheel_speed_cmd)` {#sendcmdsteering_angle_cmd-wheel_speed_cmd}

发送并保持虚拟转角和轮速目标，正值表示左转和前进。各目标独立限幅到 `getCmdLimits()` 返回的对称边界；实际车轮量不分别限幅。此调用只更新保持指令，不改变实际状态。之后每次 `step()` 均使用这些目标，直到下一次发送或重置。

- **参数：**
    - `steering_angle_cmd`
        - 类型： 有限实数数值标量
        - 单位： `rad`
    - `wheel_speed_cmd`
        - 类型： 有限实数数值标量
        - 单位： `rad/s`
- **返回值：** 无
- **另见：** [<u>属性 `Cmd`</u>](Properties.md#4-cmd), [<u>方法 `getCmd`</u>](#getcmd), [<u>方法 `getCmdLimits`</u>](#getcmdlimits), [<u>方法 `setWarnOnSaturation`</u>](#setwarnonsaturationwarn_on_saturation), [<u>方法 `step`</u>](#stepdt-t)
- **用法：**
    ```matlab
    robot.sendCmd(0.2, 5); % Set virtual actuator targets
    cmd = robot.getCmd(); % Read the applied targets after clipping
    fprintf('Applied command: delta_c=%f rad, Omega_c=%f rad/s\n', ...
            cmd(1), cmd(2));
    ```

## 5. 运行 {#5-running}

### `step(dt, t)` {#stepdt-t}

使用保持指令和选定的欧拉法或 RK4 法，将全部五个动态状态推进一个固定步长。RK4 的四个阶段使用相同指令；如启用航向角归一化，则仅在完整积分步结束后进行。方程为自治系统，因此 `t` 不影响结果，模型内部也不维护仿真时钟。

建议根据 `getParams()` 返回的实际参数选择 `dt <= 0.1 * min(steeringTimeConstant, wheelTimeConstant)`。进入较大步长范围时会发出一次 `ackermann_robot:LargeStepSize`，但不会停止积分或调整 `dt`。对于每个一阶执行器模态，欧拉法的线性稳定条件为 `dt < 2*T`，RK4 约为 `dt < 2.785*T`；稳定性本身不保证精度。详细理论推导见[阿克曼机器人模型](../Modeling/ackermann-robot-model.md)。

- **参数：**
    - `dt`
        - 类型： 有限、严格为正的实数数值标量
        - 单位： `s`
    - `t` （可选）
        - 类型： 有限实数数值标量，或 `[]`
        - 含义： 本积分步的起始时间，单位为 `s`；省略或为 `[]` 时取 `0`
- **返回值：** 无
- **另见：** [<u>属性 `States`</u>](Properties.md#2-states), [<u>属性 `Config`</u>](Properties.md#5-config), [<u>属性 `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive), [<u>方法 `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>方法 `stateDerivative`</u>](#statederivativezut)
- **用法：**
    ```matlab
    robot = rpm.ackermann_robot();
    params = robot.getParams();
    dt = 0.05 * min(params.steeringTimeConstant, params.wheelTimeConstant);
    robot.sendCmd(0.2, 5);
    for k = 1:100
        t = (k - 1) * dt; % Maintain simulation time externally
        robot.step(dt, t);
    end
    pose = robot.getPose();
    fprintf('Final pose: x=%f m, y=%f m, theta=%f rad\n', ...
            pose(1), pose(2), pose(3));
    ```

## 6. 其他 {#6-other}

### `virtual2body(virtual_state)` {#virtual2bodyvirtual_state}

将给定的虚拟转角和轮速转换为后轴中点的有符号前进速度及逆时针横摆角速度。该代数转换仅读取物理参数，不读取或改变当前状态，也不执行限幅。设轮半径为 $r$、轴距为 $L$：

$$
\begin{aligned}
v(t) &= r \cdot \Omega(t), \\ \\
\omega(t) &= \dfrac{r \cdot \Omega(t) \tan \delta(t)}{L}.
\end{aligned}
$$

详细理论推导见[<u>阿克曼机器人模型</u>](../Modeling/ackermann-robot-model.md)。

- **参数：**
    - `virtual_state`
        - 类型： 有限实数的二元素数值行向量或列向量
        - 顺序与单位： `[delta; Omega]`，单位为 `[rad; rad/s]`
- **返回值：**
    - `body_velocity`
        - 类型： `2x1 double`
        - 顺序与单位： `[v; omega]`，单位为 `[m/s; rad/s]`
- **另见：** [<u>方法 `body2virtual`</u>](#body2virtualbody_velocity), [<u>方法 `getVel`</u>](#getvel), [<u>属性 `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>属性 `Params.wheelBase`</u>](Properties.md#paramswheelbase)
- **用法：**
    ```matlab
    body_velocity = robot.virtual2body([0.2; 5]);
    fprintf('Body velocity: v=%f m/s, omega=%f rad/s\n', ...
            body_velocity(1), body_velocity(2));
    ```

### `body2virtual(body_velocity)` {#body2virtualbody_velocity}

将期望的有符号前进速度和横摆角速度转换为虚拟执行器量，不修改机器人，也不对结果限幅。静止请求 `[0; 0]` 映射为 `[0; 0]`；前进速度为零而横摆角速度非零时，触发 `ackermann_robot:InfeasibleBodyVelocity`，因为模型无法原地旋转。对于可实现的请求：

$$
\begin{aligned}
\delta(t) &= \begin{cases} \arctan \left(\dfrac{L \cdot \omega(t)}{v(t)}\right), & v(t) \neq 0 \\ 0, & v(t) = 0,\ \omega(t) = 0\end{cases} \\ \\
\Omega(t) &= \dfrac{v(t)}{r}.
\end{aligned} \quad 
$$

详细理论推导见[<u>阿克曼机器人模型</u>](../Modeling/ackermann-robot-model.md)。

- **参数：**
    - `body_velocity`
        - 类型： 有限实数的二元素数值行向量或列向量
        - 顺序与单位： `[v; omega]`，单位为 `[m/s; rad/s]`
- **返回值：**
    - `virtual_state`
        - 类型： `2x1 double`
        - 顺序与单位： `[delta; Omega]`，单位为 `[rad; rad/s]`
- **另见：** [<u>方法 `virtual2body`</u>](#virtual2bodyvirtual_state), [<u>方法 `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>方法 `getCmdLimits`</u>](#getcmdlimits)
- **用法：**
    ```matlab
    virtual_state = robot.body2virtual([0.5; 0.1]);
    fprintf('Virtual targets: delta=%f rad, Omega=%f rad/s\n', ...
            virtual_state(1), virtual_state(2));
    robot.sendCmd(virtual_state(1), virtual_state(2)); % Clipping occurs here
    ```

## 7.* 私有方法 {#7-private-methods}

### `validateInitialStates(states)` {#validateinitialstatesstates}

内部方法：在应用重置前校验并规范初始状态。输入必须为有限实数的五元素数值向量；转角须位于阿克曼几何的主定义域内，两个执行器状态须满足保守指令边界。非法值被拒绝，而非限幅。

- **参数：** `states` — 五元素数值行向量或列向量
- **返回值：** `states` — 规范后的 `5x1 double`
- **另见：** [<u>属性 `States`</u>](Properties.md#2-states), [<u>方法 `reset`</u>](#resetini_states), [<u>方法 `commandLimits`</u>](#commandlimits)

### `validateParams(Params)` {#validateparamsparams}

内部方法：校验标量参数结构体，并将十个必需数值字段规范为 double 标量或列向量。零时间常数会替换为 `1e-3` s 并发出警告；缺失或非法字段被拒绝。

- **参数：** `Params` — 包含全部必需字段的标量 `struct`
- **返回值：** `Params` — 经校验和规范的标量 `struct`
- **另见：** [<u>属性 `Params`</u>](Properties.md#3-params), [<u>方法 `rpm.ackermann_robot`</u>](#rpm-ackermann-robot)

### `stateDerivative(z,u,t)` {#statederivativezut}

内部方法：在当前状态或 RK4 中间状态处，使用保持指令计算五个连续状态导数。$r$ 表示轮半径，$L$ 表示轴距，$T_\delta$、$T_\Omega$ 分别表示转向与轮速时间常数：

$$
\dot{z} = \begin{bmatrix}
r \cdot z_5\cos z_3 \\
r \cdot z_5\sin z_3 \\
{r}/{L}\cdot z_5\tan z_4 \\
{(u_1-z_4)}/{T_\delta} \\
{(u_2-z_5)}/{T_\Omega}
\end{bmatrix}.
$$

详细理论推导见[<u>阿克曼机器人模型</u>](../Modeling/ackermann-robot-model.md)。

- **参数：** `z` — `5x1` 状态向量；`u` — `2x1` 保持指令；`t` — 阶段时间，单位为秒（当前未使用）
- **返回值：** `dz` — `5x1 double`，单位为 `[m/s; m/s; rad/s; rad/s; rad/s^2]`
- **另见：** [<u>方法 `step`</u>](#stepdt-t), [<u>属性 `States`</u>](Properties.md#2-states), [<u>属性 `Cmd`</u>](Properties.md#4-cmd)

### `physicalWheelMap(z)` {#physicalwheelmapz}

内部方法：在阿克曼几何和纯滚动假设下，将虚拟执行器状态映射为实际前轮转角和四轮转速。该映射是代数运算，不改变对象。$W$ 表示轮距，$L$ 表示轴距：

$$
\psi=
\begin{bmatrix}
\displaystyle \arctan\left(\dfrac{\tan z_4}{1-\lambda\tan z_4}\right)\\[8pt]
\displaystyle \arctan\left(\dfrac{\tan z_4}{1+\lambda\tan z_4}\right)\\[8pt]
\displaystyle z_5\left(1-\lambda\tan z_4\right)\\[6pt]
\displaystyle z_5\left(1+\lambda\tan z_4\right)\\[6pt]
\displaystyle z_5\sqrt{1-2\lambda\tan z_4+\left(1+\lambda^2\right)\tan^2 z_4}\\[8pt]
\displaystyle z_5\sqrt{1+2\lambda\tan z_4+\left(1+\lambda^2\right)\tan^2 z_4}
\end{bmatrix},\qquad \lambda = \dfrac{W}{2L}.
$$

详细理论推导见[<u>阿克曼机器人模型</u>](../Modeling/ackermann-robot-model.md)。

- **参数：** `z` — `5x1` 状态向量（仅使用 `z(4:5)`）
- **返回值：** `physical_values` ($\psi$) — `6x1 double`, 顺序为 `[delta_lf; delta_rf; Omega_lr; Omega_rr; Omega_lf; Omega_rf]`；转角单位为 `rad`，转速单位为 `rad/s`。此内部轮速顺序与 `getPhysicalWheelSpeed()` 不同。
- **另见：** [<u>方法 `getPhysicalSteeringAngle`</u>](#getphysicalsteeringangle), [<u>方法 `getPhysicalWheelSpeed`</u>](#getphysicalwheelspeed), [<u>属性 `Params.trackWidth`</u>](Properties.md#paramstrackwidth)

### `commandLimits` {#commandlimits}

内部方法：计算定义保守瞬态矩形范围的正虚拟执行器上限。设物理上限为 $\delta_m$、$\Omega_m$，$\lambda = W/(2L)$，则边界与当前转向状态无关：


$$ \left| \delta(t) \right| \le \bar{\delta}, \quad \bar{\delta}:=\arctan\left(\dfrac{2L\tan\delta_m}{2L+W\tan\delta_m}\right). $$

$$ \left|\Omega(t)\right|\le\dfrac{\Omega_m}{\sqrt{\gamma}}, \quad \gamma =1+2\lambda\tan\bar{\delta}+\left(1+\lambda^2\right)\tan^2\bar{\delta}. $$

详细理论推导见[<u>阿克曼机器人模型</u>](../Modeling/ackermann-robot-model.md)。

- **参数：** 无
- **返回值：** `limits` — `2x1 double`, 顺序为 `[bar_delta; Omega_m/sqrt(gamma)]`，单位为 `[rad; rad/s]`
- **另见：** [<u>方法 `getCmdLimits`</u>](#getcmdlimits), [<u>方法 `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>方法 `validateInitialStates`</u>](#validateinitialstatesstates), [<u>属性 `Params.maxPhysicalSteeringAngle`</u>](Properties.md#paramsmaxphysicalsteeringangle), [<u>属性 `Params.maxPhysicalWheelSpeed`</u>](Properties.md#paramsmaxphysicalwheelspeed)
