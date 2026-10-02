# Ackermann-Robot Methods

> **Tips:** Sections with `'*'` are private terms.

## 1. Initialization

Use the constructor to create a robot with its own physical parameters, initial states, and metadata. Use `reset()` to restart an existing robot without changing its parameters or simulation configuration; neither operation advances simulation time.

### `ackermann_robot(Params, Ini_States, Metadata)`

Create a new Ackermann robot with the supplied parameters, initial states, and metadata. Omitted or `[]` arguments use the bundled YAML parameters, five zero states, and default metadata, respectively. Initial states are validated rather than clipped, and both held commands start at zero, even when the initial actuator states are nonzero.

- **Argument:**
    - `Params` (optional)
        - type: `struct`
        - see also: [<u>property `Params`</u>](Properties.md#3-params)
    - `Ini_States` (optional)
        - type: `5x1 double`
        - see also: [<u>property `States`</u>](Properties.md#2-states)
    - `Metadata` (optional)
        - type: `struct`
        - see also: [<u>property `Metadata`</u>](Properties.md#1-metadata)
- **Return:**
    - `ackermann_robot`
        - type: `object`
- **Usage:**
    ```matlab
    % Use default parameters
    robot = ackermann_robot();
    ```

    ```matlab
    % Use custom parameters
    Params = load_ackermann_params();   % get default parameters
    Params.maxPhysicalSteeringAngle = 0.5;  % change parameter(s)
    robot = ackermann_robot(Params);    % use modified parameters
    ```

    ```matlab
    % Use initial states and metadata
    Ini_States = [10; -10; -pi/2; 0; 0];    % custom initial states
    Metadata = struct('Name', 'Robert', 'Number', '001', ...
                      'Description', 'My beloved robot.');   % custom metadata
    robot = ackermann_robot([], Ini_States, Metadata);
    ```

### `reset(ini_states)`

Reset the robot to the supplied states, or zero states when `ini_states` is omitted or `[]`. A successful reset clears the held commands and step-size warning flag while preserving parameters, metadata, and configuration. Invalid initial states are rejected without changing the robot; they are not clipped.

- **Argument:**
    - `ini_states` (optional)
        - type: `5x1 double`
        - see also: [<u>property `States`</u>](Properties.md#2-states)
- **Return:** none
- **Usage:**
    ```matlab
    robot = ackermann_robot();

    % do something ...
    % ...
    % ...

    robot.reset();    % Reset to zero-states
    robot.reset([1,-1,pi/2,0,0]);   % or custom initial states
    ```

## 2. `Get`

### `getStates`

Get the five current dynamic states as `[x; y; theta; delta; Omega]`, in `[m; m; rad; rad; rad/s]`. The first three describe the rear-axle midpoint's world-frame pose; the last two are actual virtual actuator states, not commands. Reading or editing the returned vector does not change the robot.

- **Argument:** none
- **Return:**
    - `States`
        - type: `5x1 double`
        - see also: [<u>property `States`</u>](Properties.md#2-states)
- **Usage:**
    ```matlab
    states = robot.getStates();
    x = states(1); y = states(2); theta = states(3);
    delta = states(4); Omega = states(5);   % semantics of states
    fprintf('Robot states: x=%f, y=%f, theta=%f, delta=%f, Omega=%f\n',...
            x, y, theta, delta, Omega);
    ```

### `getCmd`

Get the currently held virtual actuator command after clipping. These targets are used by subsequent `step()` calls until the next `sendCmd()` or `reset()`; they may differ from the actual actuator states.

- **Argument:** none
- **Return:**
    - `cmd`
        - type: `2x1 double`
        - order and units: `[steering_angle_cmd; wheel_speed_cmd]`, in `[rad; rad/s]`
        - see also: [<u>property `Cmd`</u>](Properties.md#4-cmd), [<u>method `getStates`</u>](#getstates)
- **Usage:**
    ```matlab
    cmd = robot.getCmd();
    delta_c = cmd(1); Omega_c = cmd(2);
    fprintf('Held command: delta_c=%f rad, Omega_c=%f rad/s\n', ...
            delta_c, Omega_c);
    ```

### `getPose`

Get the current pose of the rear-axle midpoint in the world frame. The heading is measured counterclockwise from the world x-axis; it accumulates by default and is normalized to `[-pi, pi)` after each `step()` when heading wrapping is enabled.

- **Argument:** none
- **Return:**
    - `pose`
        - type: `3x1 double`
        - order and units: `[x; y; theta]`, in `[m; m; rad]`
        - see also: [<u>property `States`</u>](Properties.md#2-states), [<u>property `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **Usage:**
    ```matlab
    pose = robot.getPose();
    x = pose(1); y = pose(2); theta = pose(3);
    fprintf('Robot pose: x=%f m, y=%f m, theta=%f rad\n', ...
            x, y, theta);
    ```

### `getVel`

Get the instantaneous body velocity of the rear-axle midpoint, calculated from the actual virtual actuator states rather than their commands. The forward speed is signed, and positive yaw rate indicates counterclockwise rotation: `v = wheelRadius * Omega` and `omega = v * tan(delta) / wheelBase`.

- **Argument:** none
- **Return:**
    - `velocity`
        - type: `2x1 double`
        - order and units: `[v; omega]`, in `[m/s; rad/s]`
        - see also: [<u>method `getVirtualSteeringAngle`</u>](#getvirtualsteeringangle), [<u>method `getVirtualWheelSpeed`</u>](#getvirtualwheelspeed), [<u>method `getPoseDot`</u>](#getposedot), [<u>method `virtual2body()`</u>](#virtual2bodyvirtual_state)
- **Usage:**
    ```matlab
    velocity = robot.getVel();
    v = velocity(1); omega = velocity(2);
    fprintf('Body velocity: v=%f m/s, omega=%f rad/s\n', v, omega);
    ```

### `getPoseDot`

Get the instantaneous pose derivative in the world frame: `[v*cos(theta); v*sin(theta); omega]`. The yaw rate is the physical angular velocity and does not include numerical jumps caused by heading wrapping. This method reads the current state without advancing the simulation.

- **Argument:** none
- **Return:**
    - `pose_derivative`
        - type: `3x1 double`
        - order and units: `[x_dot; y_dot; theta_dot]`, in `[m/s; m/s; rad/s]`
        - see also: [<u>method `getPose`</u>](#getpose), [<u>method `getVel`</u>](#getvel)
- **Usage:**
    ```matlab
    pose_derivative = robot.getPoseDot();
    x_dot = pose_derivative(1); y_dot = pose_derivative(2);
    theta_dot = pose_derivative(3);
    fprintf('Pose derivative: x_dot=%f m/s, y_dot=%f m/s, theta_dot=%f rad/s\n', ...
            x_dot, y_dot, theta_dot);
    ```

### `getVirtualSteeringAngle`

Get the actual virtual front-wheel steering angle. Positive values indicate left steering. Because of the first-order steering response, this value may differ from the held steering command.

- **Argument:** none
- **Return:**
    - `delta`
        - type: `double` scalar
        - unit: `rad`
        - see also: [<u>property `States(4)` / `States(5)`</u>](Properties.md#states4-states5), [<u>method `getCmd`</u>](#getcmd), [<u>method `getPhysicalSteeringAngle`</u>](#getphysicalsteeringangle)
- **Usage:**
    ```matlab
    delta = robot.getVirtualSteeringAngle();
    fprintf('Virtual steering angle: delta=%f rad\n', delta);
    ```

### `getVirtualWheelSpeed`

Get the actual virtual wheel angular speed. Positive values indicate forward motion. Because of the first-order wheel-speed response, this value may differ from the held wheel-speed command.

- **Argument:** none
- **Return:**
    - `Omega`
        - type: `double` scalar
        - unit: `rad/s`
        - see also: [<u>property `States(4)` / `States(5)`</u>](Properties.md#states4-states5), [<u>method `getCmd`</u>](#getcmd), [<u>method `getPhysicalWheelSpeed`</u>](#getphysicalwheelspeed)
- **Usage:**
    ```matlab
    Omega = robot.getVirtualWheelSpeed();
    fprintf('Virtual wheel speed: Omega=%f rad/s\n', Omega);
    ```

### `getPhysicalSteeringAngle`

Get the left and right physical front-wheel steering angles, calculated from the current virtual steering angle using Ackermann geometry. Positive values indicate left steering. These angles are not independent dynamic states and are not clipped separately.

- **Argument:** none
- **Return:**
    - `steering_angles`
        - type: `2x1 double`
        - order and units: `[left_front; right_front]`, both in `rad`
        - see also: [<u>method `getVirtualSteeringAngle`</u>](#getvirtualsteeringangle), [<u>property `Params.wheelBase`</u>](Properties.md#paramswheelbase), [<u>property `Params.trackWidth`</u>](Properties.md#paramstrackwidth), [<u>method `physicalWheelMap()`</u>](#physicalwheelmapz)
- **Usage:**
    ```matlab
    steering_angles = robot.getPhysicalSteeringAngle();
    delta_lf = steering_angles(1); delta_rf = steering_angles(2);
    fprintf('Physical steering angles: left_front=%f rad, right_front=%f rad\n', ...
            delta_lf, delta_rf);
    ```

### `getPhysicalWheelSpeed`

Get the angular speeds of all four physical wheels, calculated from the current virtual steering angle and wheel speed under the pure-rolling assumption. Positive values correspond to forward rolling. These speeds are not independent dynamic states and are not clipped separately.

- **Argument:** none
- **Return:**
    - `wheel_speeds`
        - type: `4x1 double`
        - order and units: `[left_front; right_front; left_rear; right_rear]`, all in `rad/s`
        - see also: [<u>method `getVirtualSteeringAngle`</u>](#getvirtualsteeringangle), [<u>method `getVirtualWheelSpeed`</u>](#getvirtualwheelspeed), [<u>method `physicalWheelMap()`</u>](#physicalwheelmapz)
- **Usage:**
    ```matlab
    wheel_speeds = robot.getPhysicalWheelSpeed();
    Omega_lf = wheel_speeds(1); Omega_rf = wheel_speeds(2);
    Omega_lr = wheel_speeds(3); Omega_rr = wheel_speeds(4);
    fprintf(['Physical wheel speeds (rad/s): left_front=%f, right_front=%f, ' ...
             'left_rear=%f, right_rear=%f\n'], ...
            Omega_lf, Omega_rf, Omega_lr, Omega_rr);
    ```

### `getParams`

Get a copy of the physical and display parameters currently used by the robot. The returned values include numeric normalization and any zero time constants replaced by the constructor. Editing this copy does not change the robot; create a new object to apply different parameters.

- **Argument:** none
- **Return:**
    - `params`
        - type: scalar `struct`
        - see also: [<u>property `Params`</u>](Properties.md#3-params)
- **Usage:**
    ```matlab
    params = robot.getParams();
    radius = params.wheelRadius;
    body_size = params.bodySize;
    fprintf('Wheel radius: %f m\n', radius);
    fprintf('Body size: length=%f m, width=%f m, height=%f m\n', ...
            body_size(1), body_size(2), body_size(3));
    ```

### `getCmdLimits`

Get the positive virtual actuator limits defining the symmetric conservative transient rectangle. `sendCmd()` clips each target to its corresponding `[-limit, limit]`; the constructor and `reset()` require the initial virtual actuator states to lie within these same inclusive bounds. The wheel-speed limit is conservative and independent of the current steering angle. This method reads only the parameters and does not change states or commands.

- **Argument:** none
- **Return:**
    - `limits`
        - type: `2x1 double`
        - order and units: `[virtual_steering_limit; virtual_wheel_speed_limit]`, in `[rad; rad/s]`
        - see also: [<u>property `Params.maxPhysicalSteeringAngle`</u>](Properties.md#paramsmaxphysicalsteeringangle), [<u>property `Params.maxPhysicalWheelSpeed`</u>](Properties.md#paramsmaxphysicalwheelspeed), [<u>method `reset`</u>](#resetini_states), [<u>method `sendCmd()`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>method `commandLimits()`</u>](#commandlimits)
- **Usage:**
    ```matlab
    limits = robot.getCmdLimits();
    steering_range = [-limits(1), limits(1)];
    wheel_speed_range = [-limits(2), limits(2)];
    fprintf('Virtual steering range: [%f, %f] rad\n', ...
            steering_range(1), steering_range(2));
    fprintf('Virtual wheel-speed range: [%f, %f] rad/s\n', ...
            wheel_speed_range(1), wheel_speed_range(2));
    ```

## 3. `Set`

### `setSolutionMethod(solution_method)`

Select the fixed-step integration method for subsequent `step()` calls. Names are case-insensitive and stored as `'euler'` or `'RK4'`. A successful change clears the step-size warning flag without changing states or commands; invalid input raises `ackermann_robot:InvalidSolutionMethod` and leaves the configuration unchanged.

- **Argument:**
    - `solution_method`
        - type: character row vector or string scalar
        - accepted values: `'euler'`, `'RK4'` (case-insensitive)
        - see also: [<u>property `Config.solution_method`</u>](Properties.md#configsolution_method)
- **Return:** none
- **see also:** [<u>method `step`</u>](#stepdt-t), [<u>property `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive)
- **Usage:**
    ```matlab
    robot.setSolutionMethod('euler');
    robot.setSolutionMethod('RK4'); % Switch back to the default method
    ```

### `setWrapHeading(wrap_heading)`

Enable or disable heading normalization after each complete integration step. Enabling this option does not immediately change the current heading; subsequent steps map it to `[-pi, pi)`. Wrapping discards complete rotation counts, which cannot be restored by disabling the option later.

- **Argument:**
    - `wrap_heading`
        - type: `logical` scalar
        - accepted values: `true` or `false` (numeric `1` and `0` are not accepted)
        - see also: [<u>property `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **Return:** none
- **see also:** [<u>method `step`</u>](#stepdt-t), [<u>method `getPose`</u>](#getpose)
- **Usage:**
    ```matlab
    robot.setWrapHeading(true);  % Wrap heading after subsequent steps
    robot.setWrapHeading(false); % Preserve accumulated heading thereafter
    ```

### `setWarnOnSaturation(warn_on_saturation)`

Control whether each command-clipping event issues `ackermann_robot:CommandSaturated`. Disabling this warning does not disable clipping or suppress the independent zero-time-constant and large-step warnings. The method changes only this configuration option.

- **Argument:**
    - `warn_on_saturation`
        - type: `logical` scalar
        - accepted values: `true` or `false` (numeric `1` and `0` are not accepted)
        - see also: [<u>property `Config.warn_on_saturation`</u>](Properties.md#configwarn_on_saturation)
- **Return:** none
- **see also:** [<u>method `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd)
- **Usage:**
    ```matlab
    robot.setWarnOnSaturation(false); % Suppress command-clipping warnings
    robot.setWarnOnSaturation(true);  % Enable them again
    ```

## 4. `Send`

### `sendCmd(steering_angle_cmd, wheel_speed_cmd)`

Send and hold virtual steering and wheel-speed targets. Positive values indicate left steering and forward motion. Each target is clipped independently to the symmetric limits returned by `getCmdLimits()`; physical wheel values are not clipped separately. This call updates only the held command, not the actual states. Every subsequent `step()` uses these targets until another command or reset.

- **Argument:**
    - `steering_angle_cmd`
        - type: finite, real numeric scalar
        - unit: `rad`
    - `wheel_speed_cmd`
        - type: finite, real numeric scalar
        - unit: `rad/s`
- **Return:** none
- **see also:** [<u>property `Cmd`</u>](Properties.md#4-cmd), [<u>method `getCmd`</u>](#getcmd), [<u>method `getCmdLimits`</u>](#getcmdlimits), [<u>method `setWarnOnSaturation`</u>](#setwarnonsaturationwarn_on_saturation), [<u>method `step`</u>](#stepdt-t)
- **Usage:**
    ```matlab
    robot.sendCmd(0.2, 5); % Set virtual actuator targets
    cmd = robot.getCmd(); % Read the applied targets after clipping
    fprintf('Applied command: delta_c=%f rad, Omega_c=%f rad/s\n', ...
            cmd(1), cmd(2));
    ```

## 5. Running

### `step(dt, t)`

Advance all five dynamic states by one fixed step using the held command and the selected Euler or RK4 method. RK4 uses the same command at all four stages; heading wrapping, if enabled, occurs only after the complete step. The equations are autonomous, so `t` does not affect the result and no simulation clock is maintained internally.

Choose `dt <= 0.1 * min(steeringTimeConstant, wheelTimeConstant)` as a step-size guideline, using the actual parameters from `getParams()`. Entering the larger-step range issues `ackermann_robot:LargeStepSize` once, but does not stop integration or adjust `dt`. For each first-order actuator mode, linear stability requires `dt < 2*T` for Euler or approximately `dt < 2.785*T` for RK4; stability alone does not guarantee accuracy. For the detailed theoretical derivation, see [Ackermann robot model](../Modeling/ackermann-robot-model.md).

- **Argument:**
    - `dt`
        - type: finite, real, strictly positive numeric scalar
        - unit: `s`
    - `t` (optional)
        - type: finite, real numeric scalar, or `[]`
        - meaning: start time of this integration step, in `s`; omitted or `[]` means `0`
- **Return:** none
- **see also:** [<u>property `States`</u>](Properties.md#2-states), [<u>property `Config`</u>](Properties.md#5-config), [<u>property `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive), [<u>method `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>method `stateDerivative`</u>](#statederivativezut)
- **Usage:**
    ```matlab
    robot = ackermann_robot();
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

## 6. Other

### `virtual2body(virtual_state)`

Convert a supplied virtual steering angle and wheel speed to the rear-axle midpoint's signed forward speed and counterclockwise yaw rate. This algebraic conversion reads only physical parameters; it neither reads nor changes the current states and performs no clipping. With wheel radius $r$ and wheelbase $L$:

$$
\begin{aligned}
v(t) &= r \cdot \Omega(t), \\ \\
\omega(t) &= \dfrac{r \cdot \Omega(t) \tan \delta(t)}{L}.
\end{aligned}
$$

For the detailed theoretical derivation, see [<u>Ackermann robot model</u>](../Modeling/ackermann-robot-model.md).

- **Argument:**
    - `virtual_state`
        - type: finite, real two-element numeric row or column vector
        - order and units: `[delta; Omega]`, in `[rad; rad/s]`
- **Return:**
    - `body_velocity`
        - type: `2x1 double`
        - order and units: `[v; omega]`, in `[m/s; rad/s]`
- **see also:** [<u>method `body2virtual`</u>](#body2virtualbody_velocity), [<u>method `getVel`</u>](#getvel), [<u>property `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>property `Params.wheelBase`</u>](Properties.md#paramswheelbase)
- **Usage:**
    ```matlab
    body_velocity = robot.virtual2body([0.2; 5]);
    fprintf('Body velocity: v=%f m/s, omega=%f rad/s\n', ...
            body_velocity(1), body_velocity(2));
    ```

### `body2virtual(body_velocity)`

Convert a desired signed forward speed and yaw rate to virtual actuator values without modifying the robot or clipping the result. A stationary request `[0; 0]` maps to `[0; 0]`; a request with zero forward speed and nonzero yaw rate raises `ackermann_robot:InfeasibleBodyVelocity`, because the model cannot rotate in place. For feasible requests:

$$
\begin{aligned}
\delta(t) &= \begin{cases} \arctan \left(\dfrac{L \cdot \omega(t)}{v(t)}\right), & v(t) \neq 0 \\ 0, & v(t) = 0,\ \omega(t) = 0\end{cases} \\ \\
\Omega(t) &= \dfrac{v(t)}{r}.
\end{aligned} \quad 
$$

For the detailed theoretical derivation, see [<u>Ackermann robot model</u>](../Modeling/ackermann-robot-model.md).

- **Argument:**
    - `body_velocity`
        - type: finite, real two-element numeric row or column vector
        - order and units: `[v; omega]`, in `[m/s; rad/s]`
- **Return:**
    - `virtual_state`
        - type: `2x1 double`
        - order and units: `[delta; Omega]`, in `[rad; rad/s]`
- **see also:** [<u>method `virtual2body`</u>](#virtual2bodyvirtual_state), [<u>method `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>method `getCmdLimits`</u>](#getcmdlimits)
- **Usage:**
    ```matlab
    virtual_state = robot.body2virtual([0.5; 0.1]);
    fprintf('Virtual targets: delta=%f rad, Omega=%f rad/s\n', ...
            virtual_state(1), virtual_state(2));
    robot.sendCmd(virtual_state(1), virtual_state(2)); % Clipping occurs here
    ```

## 7.* Private Methods

### `validateInitialStates(states)`

Internally validate and normalize initial states before applying a reset. Inputs must be finite real five-element numeric vectors; steering must lie in the principal Ackermann geometric domain, and both actuator states must satisfy the conservative command limits. Invalid values are rejected rather than clipped.

- **Argument:** `states` — five-element numeric row or column vector
- **Return:** `states` — normalized `5x1 double`
- **see also:** [<u>property `States`</u>](Properties.md#2-states), [<u>method `reset`</u>](#resetini_states), [<u>method `commandLimits`</u>](#commandlimits)

### `validateParams(Params)`

Internally validate the scalar parameter structure and normalize the ten required numeric fields to double scalars or column vectors. Zero time constants are replaced by `1e-3` s with a warning; missing or invalid fields are rejected.

- **Argument:** `Params` — scalar `struct` containing all required fields
- **Return:** `Params` — validated and normalized scalar `struct`
- **see also:** [<u>property `Params`</u>](Properties.md#3-params), [<u>method `ackermann_robot`</u>](#ackermann_robotparams-ini_states-metadata)

### `stateDerivative(z,u,t)`

Internally compute the five continuous state derivatives at the current or RK4 intermediate state, using a held command. Here $r$ is wheel radius, $L$ is wheelbase, and $T_\delta$, $T_\Omega$ are the steering and wheel-speed time constants:

$$
\dot{z} = \begin{bmatrix}
r \cdot z_5\cos z_3 \\
r \cdot z_5\sin z_3 \\
{r}/{L}\cdot z_5\tan z_4 \\
{(u_1-z_4)}/{T_\delta} \\
{(u_2-z_5)}/{T_\Omega}
\end{bmatrix}.
$$

For the detailed theoretical derivation, see [<u>Ackermann robot model</u>](../Modeling/ackermann-robot-model.md).

- **Argument:** `z` — `5x1` state vector; `u` — `2x1` held command; `t` — stage time in seconds (currently unused)
- **Return:** `dz` — `5x1 double`, in `[m/s; m/s; rad/s; rad/s; rad/s^2]`
- **see also:** [<u>method `step`</u>](#stepdt-t), [<u>property `States`</u>](Properties.md#2-states), [<u>property `Cmd`</u>](Properties.md#4-cmd)

### `physicalWheelMap(z)`

Internally map the virtual actuator states to physical front-wheel angles and four wheel speeds under Ackermann geometry and pure rolling. The mapping is algebraic and does not change the object. Here $W$ is track width and $L$ is wheelbase:

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

For the detailed theoretical derivation, see [<u>Ackermann robot model</u>](../Modeling/ackermann-robot-model.md).

- **Argument:** `z` — `5x1` state vector (only `z(4:5)` are used)
- **Return:** `physical_values` ($\psi$) — `6x1 double`, ordered as `[delta_lf; delta_rf; Omega_lr; Omega_rr; Omega_lf; Omega_rf]`; angles in `rad`, speeds in `rad/s`. This internal wheel-speed order differs from `getPhysicalWheelSpeed()`.
- **see also:** [<u>method `getPhysicalSteeringAngle`</u>](#getphysicalsteeringangle), [<u>method `getPhysicalWheelSpeed`</u>](#getphysicalwheelspeed), [<u>property `Params.trackWidth`</u>](Properties.md#paramstrackwidth)

### `commandLimits`

Internally compute the positive virtual actuator limits defining the conservative transient rectangle. With physical limits $\delta_m$ and $\Omega_m$, and $\lambda = W/(2L)$, the bounds are independent of the current steering state:


$$ \left| \delta(t) \right| \le \bar{\delta}, \quad \bar{\delta}:=\arctan\left(\dfrac{2L\tan\delta_m}{2L+W\tan\delta_m}\right). $$

$$ \left|\Omega(t)\right|\le\dfrac{\Omega_m}{\sqrt{\gamma}}, \quad \gamma =1+2\lambda\tan\bar{\delta}+\left(1+\lambda^2\right)\tan^2\bar{\delta}. $$

For the detailed theoretical derivation, see [<u>Ackermann robot model</u>](../Modeling/ackermann-robot-model.md).

- **Argument:** none
- **Return:** `limits` — `2x1 double`, ordered as `[bar_delta; Omega_m/sqrt(gamma)]`, in `[rad; rad/s]`
- **see also:** [<u>method `getCmdLimits`</u>](#getcmdlimits), [<u>method `sendCmd`</u>](#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>method `validateInitialStates`</u>](#validateinitialstatesstates), [<u>property `Params.maxPhysicalSteeringAngle`</u>](Properties.md#paramsmaxphysicalsteeringangle), [<u>property `Params.maxPhysicalWheelSpeed`</u>](Properties.md#paramsmaxphysicalwheelspeed)
