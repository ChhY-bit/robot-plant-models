# Wheel-Robot Methods

> **Tips:** Sections with `'*'` are private terms.

## 1. Initialization

Use the constructor to create a robot with its own physical parameters, initial states, and metadata. Use `reset()` to restart an existing robot without changing its parameters or simulation configuration; neither operation advances simulation time.

### `rpm.wheel_robot(Params, Ini_States, Metadata)` {#rpm-wheel-robot}

Create a new differential-drive robot with the supplied parameters, initial states, and metadata. Omitted or `[]` arguments use the bundled YAML parameters, seven zero states, and default metadata, respectively. Initial wheel speeds are not clipped or restricted by `maxWheelSpeed`. Both held commands start at zero, so nonzero initial speeds decay unless new targets are sent. Each constructor call creates an independent `handle` object.

- **Argument:**
    - `Params` (optional)
        - type: scalar `struct` containing all seven required parameter fields, or `[]`
        - see also: [<u>property `Params`</u>](Properties.md#3-params)
    - `Ini_States` (optional)
        - type: finite, real seven-element numeric row or column vector, or `[]`; normalized to `7x1 double`
        - order and units: `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`, in `[m; m; rad; rad; rad/s; rad; rad/s]`
        - see also: [<u>property `States`</u>](Properties.md#2-states)
    - `Metadata` (optional)
        - type: scalar `struct`, or `[]`; missing default fields are filled without validating individual field types
        - see also: [<u>property `Metadata`</u>](Properties.md#1-metadata)
- **Return:**
    - `obj`
        - type: `rpm.wheel_robot` handle object
- **see also:** [<u>method `reset()`</u>](#resetini_states), [<u>method `getParams()`</u>](#getparams)
- **Usage:**
    ```matlab
    % Use default parameters
    robot = rpm.wheel_robot();
    ```

    ```matlab
    % Use custom parameters; left and right values may differ
    Params = rpm.utils.load_wheel_params();
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

### `reset(ini_states)`

Reset the robot to the supplied states, or zero states when `ini_states` is omitted or `[]`. A successful reset clears the two held wheel commands and step-size warning flag while preserving parameters, metadata, and configuration. Invalid dimensions or nonfinite/complex values are rejected before changing the object; finite initial wheel speeds are retained even outside the command limits.

- **Argument:**
    - `ini_states` (optional)
        - type: finite, real seven-element numeric row or column vector, or `[]`; normalized to `7x1 double`
        - order and units: `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`, in `[m; m; rad; rad; rad/s; rad; rad/s]`
        - see also: [<u>property `States`</u>](Properties.md#2-states)
- **Return:** none
- **see also:** [<u>property `Cmd`</u>](Properties.md#4-cmd), [<u>property `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive), [<u>method `rpm.wheel_robot()`</u>](#rpm-wheel-robot)
- **Usage:**
    ```matlab
    robot = rpm.wheel_robot();
    robot.sendCmd(4, 6);
    robot.step(0.005);
    robot.reset(); % Zero states and zero held commands
    robot.reset([1, -1, pi/2, 0, 2, 0, 2]); % Or custom initial states
    ```

## 2. `Get`

### `getStates`

Get the seven current dynamic states as `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`. The first three describe the drive-axle midpoint's world-frame pose; the last four are the interleaved actual wheel angles and speeds, not command targets. Reading or editing the returned vector does not change the robot.

- **Argument:** none
- **Return:**
    - `states`
        - type: `7x1 double`
        - order and units: `[x; y; theta; alpha_L; Omega_L; alpha_R; Omega_R]`, in `[m; m; rad; rad; rad/s; rad; rad/s]`
        - see also: [<u>property `States`</u>](Properties.md#2-states)
- **Usage:**
    ```matlab
    states = robot.getStates();
    x = states(1); y = states(2); theta = states(3);
    alpha_L = states(4); Omega_L = states(5);
    alpha_R = states(6); Omega_R = states(7);
    fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', x, y, theta);
    fprintf('Left wheel: angle=%f rad, speed=%f rad/s\n', alpha_L, Omega_L);
    fprintf('Right wheel: angle=%f rad, speed=%f rad/s\n', alpha_R, Omega_R);
    ```

### `getCmd`

Get the currently held left and right wheel-speed targets after clipping. These targets are used by subsequent `step()` calls until the next `sendCmd()` or `reset()`; they may differ from actual wheel speeds. Although the private `Cmd` property is a structure, this method returns a numeric column vector.

- **Argument:** none
- **Return:**
    - `cmd`
        - type: `2x1 double`
        - order and units: `[left_wheel_cmd; right_wheel_cmd]`, both in `rad/s`
        - see also: [<u>property `Cmd`</u>](Properties.md#4-cmd), [<u>method `getWheelSpeed()`</u>](#getwheelspeed)
- **Usage:**
    ```matlab
    cmd = robot.getCmd();
    fprintf('Held command: left=%f rad/s, right=%f rad/s\n', cmd(1), cmd(2));
    ```

### `getPose`

Get the current pose of the drive-axle midpoint in the world frame. Heading is measured counterclockwise from the world x-axis; it accumulates by default and is normalized to `[-pi, pi)` after each `step()` when heading wrapping is enabled. The display offset of the body does not change this reference point.

- **Argument:** none
- **Return:**
    - `pose`
        - type: `3x1 double`
        - order and units: `[x; y; theta]`, in `[m; m; rad]`
        - see also: [<u>property `States`</u>](Properties.md#2-states), [<u>property `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **Usage:**
    ```matlab
    pose = robot.getPose();
    fprintf('Robot pose: x=%f m, y=%f m, theta=%f rad\n', ...
            pose(1), pose(2), pose(3));
    ```

### `getVel`

Get the instantaneous body velocity of the drive-axle midpoint from actual wheel speeds rather than command targets. Forward speed is signed, and positive yaw rate means counterclockwise rotation: `v = (r_L * Omega_L + r_R * Omega_R) / 2` and `omega = (r_R * Omega_R - r_L * Omega_L) / trackWidth`. The model supports reverse motion and in-place rotation.

- **Argument:** none
- **Return:**
    - `velocity`
        - type: `2x1 double`
        - order and units: `[v; omega]`, in `[m/s; rad/s]`
        - see also: [<u>method `getWheelSpeed()`</u>](#getwheelspeed), [<u>method `wheel2body()`</u>](#wheel2bodywheel_speed), [<u>method `getPoseDot()`</u>](#getposedot)
- **Usage:**
    ```matlab
    velocity = robot.getVel();
    fprintf('Body velocity: v=%f m/s, omega=%f rad/s\n', ...
            velocity(1), velocity(2));
    ```

### `getPoseDot`

Get the instantaneous pose derivative in the world frame: `[v*cos(theta); v*sin(theta); omega]`. The yaw rate is the physical angular velocity and does not include numerical jumps caused by heading wrapping. This method reads the current state without advancing the simulation.

- **Argument:** none
- **Return:**
    - `pos_derivative`
        - type: `3x1 double`
        - order and units: `[x_dot; y_dot; theta_dot]`, in `[m/s; m/s; rad/s]`
        - see also: [<u>method `getPose()`</u>](#getpose), [<u>method `getVel()`</u>](#getvel)
- **Usage:**
    ```matlab
    pose_derivative = robot.getPoseDot();
    fprintf('Pose derivative: x_dot=%f m/s, y_dot=%f m/s, theta_dot=%f rad/s\n', ...
            pose_derivative(1), pose_derivative(2), pose_derivative(3));
    ```

### `getWheelSpeed`

Get the actual angular speeds of the left and right wheels. Positive values correspond to forward rolling. Each speed follows its held target through its own first-order response, so these values need not equal `getCmd()`. The method reads states `5` and `7` and does not clip them.

- **Argument:** none
- **Return:**
    - `wheel_speed`
        - type: `2x1 double`
        - order and units: `[left_wheel_speed; right_wheel_speed]`, both in `rad/s`
        - see also: [<u>property `States(5)` / `States(7)`</u>](Properties.md#states5-states7), [<u>method `getCmd()`</u>](#getcmd), [<u>property `Params.motorTimeConstant`</u>](Properties.md#paramsmotortimeconstant)
- **Usage:**
    ```matlab
    wheel_speed = robot.getWheelSpeed();
    fprintf('Actual wheel speeds: left=%f rad/s, right=%f rad/s\n', ...
            wheel_speed(1), wheel_speed(2));
    ```

### `getWheelAngle`

Get the accumulated rotation angles of the left and right wheels, integrated from their actual speeds. Positive values correspond to forward rolling. Unlike optional heading wrapping, wheel angles are never normalized modulo `2*pi`, so complete wheel rotations remain available for odometry or encoder-style calculations.

- **Argument:** none
- **Return:**
    - `wheel_angle`
        - type: `2x1 double`
        - order and units: `[left_wheel_angle; right_wheel_angle]`, both in `rad`
        - see also: [<u>property `States(4)` / `States(6)`</u>](Properties.md#states4-states6), [<u>method `getWheelSpeed()`</u>](#getwheelspeed)
- **Usage:**
    ```matlab
    wheel_angle = robot.getWheelAngle();
    fprintf('Accumulated wheel angles: left=%f rad, right=%f rad\n', ...
            wheel_angle(1), wheel_angle(2));
    ```

### `getParams`

Get a copy of the physical and display parameters currently used by the robot. Returned values include numeric normalization, expansion of scalar wheel-pair inputs, and any zero time constants replaced by the constructor. Editing this copy does not change the robot; create a new object to apply different parameters. Wheel-speed command limits are available in `params.maxWheelSpeed`; this class has no separate `getCmdLimits()` method.

- **Argument:** none
- **Return:**
    - `params`
        - type: scalar `struct`
        - see also: [<u>property `Params`</u>](Properties.md#3-params), [<u>property `Params.maxWheelSpeed`</u>](Properties.md#paramsmaxwheelspeed)
- **Usage:**
    ```matlab
    params = robot.getParams();
    fprintf('Wheel radii: left=%f m, right=%f m\n', ...
            params.wheelRadius(1), params.wheelRadius(2));
    fprintf('Command limits: left=+/- %f rad/s, right=+/- %f rad/s\n', ...
            params.maxWheelSpeed(1), params.maxWheelSpeed(2));
    fprintf('Body size: length=%f m, width=%f m, height=%f m\n', ...
            params.bodySize(1), params.bodySize(2), params.bodySize(3));
    ```

## 3. `Set`

### `setSolutionMethod(solution_method)`

Select the fixed-step integration method for subsequent `step()` calls. Names are case-insensitive and stored as `'euler'` or `'RK4'`. A successful call clears the step-size warning flag without changing states or commands; invalid input raises `wheel_robot:InvalidSolutionMethod` and leaves the configuration unchanged.

- **Argument:**
    - `solution_method`
        - type: character row vector or string scalar
        - accepted values: `'euler'`, `'RK4'` (case-insensitive); missing strings are rejected
        - see also: [<u>property `Config.solution_method`</u>](Properties.md#configsolution_method)
- **Return:** none
- **see also:** [<u>method `step()`</u>](#stepdt-t), [<u>property `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive)
- **Usage:**
    ```matlab
    robot.setSolutionMethod('euler');
    robot.setSolutionMethod('RK4'); % Switch back to the default method
    ```

### `setWrapHeading(wrap_heading)`

Enable or disable heading normalization after each complete integration step. Enabling this option does not immediately change the current heading; subsequent steps map it to `[-pi, pi)`. Wrapping discards complete heading rotation counts, which cannot be restored by disabling the option later. Accumulated wheel angles are unaffected.

- **Argument:**
    - `wrap_heading`
        - type: `logical` scalar
        - accepted values: `true` or `false` (numeric `1` and `0` are not accepted)
        - see also: [<u>property `Config.wrap_heading`</u>](Properties.md#configwrap_heading)
- **Return:** none
- **see also:** [<u>method `step()`</u>](#stepdt-t), [<u>method `getPose()`</u>](#getpose), [<u>method `getWheelAngle()`</u>](#getwheelangle)
- **Usage:**
    ```matlab
    robot.setWrapHeading(true);  % Wrap heading after subsequent steps
    robot.setWrapHeading(false); % Preserve accumulated heading thereafter
    ```

### `setWarnOnSaturation(warn_on_saturation)`

Control whether each command-clipping event issues `wheel_robot:CommandSaturated`. Disabling this warning does not disable clipping or suppress the independent zero-time-constant and large-step warnings. The method changes only this configuration option, leaving states and held targets unchanged.

- **Argument:**
    - `warn_on_saturation`
        - type: `logical` scalar
        - accepted values: `true` or `false` (numeric `1` and `0` are not accepted)
        - see also: [<u>property `Config.warn_on_saturation`</u>](Properties.md#configwarn_on_saturation)
- **Return:** none
- **see also:** [<u>method `sendCmd()`</u>](#sendcmdleft_wheel_cmd-right_wheel_cmd)
- **Usage:**
    ```matlab
    robot.setWarnOnSaturation(false); % Suppress command-clipping warnings
    robot.setWarnOnSaturation(true);  % Enable them again
    ```

## 4. `Send`

### `sendCmd(left_wheel_cmd, right_wheel_cmd)`

Send and hold left and right wheel-speed targets. Positive values correspond to forward rolling. Each input is converted to `double` and clipped independently to the corresponding `[-maxWheelSpeed(i), maxWheelSpeed(i)]` range. This call updates only the held commands, not actual wheel speeds, angles, or pose. Every subsequent `step()` uses these targets until another command or reset; a zero target causes first-order deceleration rather than an instantaneous stop.

- **Argument:**
    - `left_wheel_cmd`
        - type: finite, real numeric scalar
        - unit: `rad/s`
    - `right_wheel_cmd`
        - type: finite, real numeric scalar
        - unit: `rad/s`
- **Return:** none
- **see also:** [<u>property `Cmd`</u>](Properties.md#4-cmd), [<u>property `Params.maxWheelSpeed`</u>](Properties.md#paramsmaxwheelspeed), [<u>method `getCmd()`</u>](#getcmd), [<u>method `setWarnOnSaturation()`</u>](#setwarnonsaturationwarn_on_saturation), [<u>method `step()`</u>](#stepdt-t)
- **Usage:**
    ```matlab
    robot.sendCmd(4, 6); % Set left and right wheel-speed targets
    cmd = robot.getCmd(); % Read the applied targets after clipping
    fprintf('Applied command: left=%f rad/s, right=%f rad/s\n', ...
            cmd(1), cmd(2));
    ```

## 5. Running

### `step(dt, t)`

Advance all seven dynamic states by one fixed step using the held commands and the selected Euler or RK4 method. RK4 uses the same commands at all four stages, with each stage's intermediate states; heading wrapping, if enabled, occurs only after the complete step. The equations are autonomous, so `t` does not affect the result and no simulation clock is maintained internally. This method does not change `Cmd` or clip wheel-speed states.

Choose `dt <= 0.1 * min(params.motorTimeConstant)` as a step-size guideline, using the actual parameters from `getParams()`. Entering the larger-step range issues `wheel_robot:LargeStepSize` once, but does not stop integration or adjust `dt`. For each first-order wheel-speed mode, linear stability requires `dt < 2*T_i` for Euler or approximately `dt < 2.785*T_i` for RK4; stability alone does not guarantee accuracy. The [<u>Wheel robot model</u>](../Modeling/wheel-robot-model.md) page is reserved for the detailed theoretical derivation and is not yet populated.

- **Argument:**
    - `dt`
        - type: finite, real, strictly positive numeric scalar
        - unit: `s`
    - `t` (optional)
        - type: finite, real numeric scalar, or `[]`
        - meaning: start time of this integration step, in `s`; omitted or `[]` means `0`
- **Return:** none
- **see also:** [<u>property `States`</u>](Properties.md#2-states), [<u>property `Config`</u>](Properties.md#5-config), [<u>property `StepSizeWarningActive`</u>](Properties.md#6-stepsizewarningactive), [<u>method `sendCmd()`</u>](#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>method `stateDerivative()`</u>](#statederivativez-u-t)
- **Usage:**
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

## 6. Other

### `body2wheel(body_velocity)`

Convert a supplied signed forward speed and counterclockwise yaw rate into left and right wheel angular speeds. This algebraic conversion reads only physical parameters; it neither reads nor changes current states and performs no clipping. In-place rotation (`v = 0`, `omega ~= 0`) is supported. With left/right wheel radii $r_L$, $r_R$ and track width $L$:

$$
\begin{aligned}
\Omega_L &= \frac{v-\omega L/2}{r_L}, \\
\Omega_R &= \frac{v+\omega L/2}{r_R}.
\end{aligned}
$$

Sending the result through `sendCmd()` may clip either wheel independently, changing the requested body velocity. Actual body velocity also depends on the first-order wheel-speed response. The [<u>Wheel robot model</u>](../Modeling/wheel-robot-model.md) page is reserved for the detailed theoretical derivation and is not yet populated.

- **Argument:**
    - `body_velocity`
        - type: finite, real two-element numeric row or column vector
        - order and units: `[v; omega]`, in `[m/s; rad/s]`
- **Return:**
    - `wheel_speed`
        - type: `2x1 double`
        - order and units: `[Omega_L; Omega_R]`, both in `rad/s`
- **see also:** [<u>method `wheel2body()`</u>](#wheel2bodywheel_speed), [<u>method `sendCmd()`</u>](#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>method `kin_inv()`</u>](#kin_inv), [<u>property `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>property `Params.trackWidth`</u>](Properties.md#paramstrackwidth)
- **Usage:**
    ```matlab
    wheel_cmd = robot.body2wheel([0.5; 0.2]);
    fprintf('Wheel targets: left=%f rad/s, right=%f rad/s\n', ...
            wheel_cmd(1), wheel_cmd(2));
    robot.sendCmd(wheel_cmd(1), wheel_cmd(2)); % Clipping occurs here
    ```

### `wheel2body(wheel_speed)`

Convert supplied left and right wheel angular speeds into the drive-axle midpoint's signed forward speed and counterclockwise yaw rate. This algebraic conversion reads only physical parameters, not the robot's states or held commands, and performs no clipping. With left/right wheel radii $r_L$, $r_R$ and track width $L$:

$$
\begin{aligned}
v &= \frac{r_L\Omega_L+r_R\Omega_R}{2}, \\
\omega &= \frac{r_R\Omega_R-r_L\Omega_L}{L}.
\end{aligned}
$$

Turning direction depends on the difference in wheel *linear* speeds, not angular speeds alone when radii differ. The [<u>Wheel robot model</u>](../Modeling/wheel-robot-model.md) page is reserved for the detailed theoretical derivation and is not yet populated.

- **Argument:**
    - `wheel_speed`
        - type: finite, real two-element numeric row or column vector
        - order and units: `[Omega_L; Omega_R]`, both in `rad/s`
- **Return:**
    - `body_velocity`
        - type: `2x1 double`
        - order and units: `[v; omega]`, in `[m/s; rad/s]`
- **see also:** [<u>method `body2wheel()`</u>](#body2wheelbody_velocity), [<u>method `getVel()`</u>](#getvel), [<u>method `kin_fwd()`</u>](#kin_fwd), [<u>property `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>property `Params.trackWidth`</u>](Properties.md#paramstrackwidth)
- **Usage:**
    ```matlab
    body_velocity = robot.wheel2body([4; 6]);
    fprintf('Converted body velocity: v=%f m/s, omega=%f rad/s\n', ...
            body_velocity(1), body_velocity(2));
    ```

## 7.* Private Methods

### `validateParams(Params)`

Internally validate the scalar parameter structure and normalize its seven required numeric fields. Scalar wheel-pair inputs are expanded to `2x1` vectors; extra structure fields are retained. Zero motor time constants are replaced by `1e-3` s with `wheel_robot:ZeroMotorTimeConstant`; missing or invalid fields are rejected. This method does not read YAML or validate initial states.

- **Argument:** `Params` — scalar `struct` containing all required fields
- **Return:** `Params` — validated and normalized scalar `struct`
- **see also:** [<u>property `Params`</u>](Properties.md#3-params), [<u>method `rpm.wheel_robot()`</u>](#rpm-wheel-robot)

### `stateDerivative(z, u, t)`

Internally compute the seven continuous state derivatives at the current or RK4 intermediate state using the held wheel-speed command vector $u = [\Omega_{L,\mathrm{cmd}}, \Omega_{R,\mathrm{cmd}}]^\mathsf{T}$. Here $r_L$, $r_R$ are wheel radii, $L$ is track width, and $T_L$, $T_R$ are the two motor time constants:

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

The [<u>Wheel robot model</u>](../Modeling/wheel-robot-model.md) page is reserved for the detailed theoretical derivation and is not yet populated.

- **Argument:** `z` — `7x1` state vector; `u` — `2x1` held wheel-speed command, ordered as `[left; right]`; `t` — stage time in seconds (currently unused)
- **Return:** `dz` — `7x1 double`, in `[m/s; m/s; rad/s; rad/s; rad/s^2; rad/s; rad/s^2]`
- **see also:** [<u>method `step()`</u>](#stepdt-t), [<u>property `States`</u>](Properties.md#2-states), [<u>property `Cmd`</u>](Properties.md#4-cmd)

### `kin_fwd`

Internally construct the `2x2` forward-kinematics matrix satisfying `[v; omega] = Mr * [Omega_L; Omega_R]`. It supports unequal wheel radii and is calculated from the validated radii and track width; it does not read or change motion states. The corresponding equations are shown in `wheel2body()`.

- **Argument:** none
- **Return:** `Mr` — `2x2 double` forward-kinematics matrix
- **see also:** [<u>method `wheel2body()`</u>](#wheel2bodywheel_speed), [<u>method `kin_inv()`</u>](#kin_inv), [<u>property `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>property `Params.trackWidth`</u>](Properties.md#paramstrackwidth)

### `kin_inv`

Internally construct the `2x2` analytic inverse-kinematics matrix satisfying `[Omega_L; Omega_R] = Mr_inv * [v; omega]`. It uses the same wheel order and sign convention as `kin_fwd()`, without numerical matrix inversion or clipping. The corresponding equations are shown in `body2wheel()`.

- **Argument:** none
- **Return:** `Mr_inv` — `2x2 double` inverse-kinematics matrix
- **see also:** [<u>method `body2wheel()`</u>](#body2wheelbody_velocity), [<u>method `kin_fwd()`</u>](#kin_fwd), [<u>property `Params.wheelRadius`</u>](Properties.md#paramswheelradius), [<u>property `Params.trackWidth`</u>](Properties.md#paramstrackwidth)
