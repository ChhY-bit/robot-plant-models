# Wheel-Robot Properties

> **Tips:** Sections with `'*'` are **private** properties/methods.

## 1. `Metadata`

The basic information of the Wheel-Robot, stored in a public structure. These fields do not affect simulation, and custom fields may be added. They can be provided through the constructor's `Metadata` argument or edited through `robot.Metadata`. The constructor requires a scalar structure and fills missing default fields, but does not validate the types or contents of individual metadata fields.

### `Metadata.Name`

A descriptive name for identifying the robot in displays, logs, or application code; it does not change the model's behavior.

- **type:** User-defined; conventionally `char`, as in the default value.
- **default:** `'wheel_robot'`
- **see also:** [<u>method `rpm.wheel_robot()`</u>](Methods.md#rpm-wheel-robot)
- **usage:**
    ```matlab
    robot.Metadata.Name = 'WheelBot';
    ```

### `Metadata.Number`

An optional identifier for distinguishing robots in multi-robot applications. The model does not assign, validate, or use this identifier in its calculations.

- **type:** User-defined; for example, `char` or a numeric scalar (the default `[]` is an empty `double` array).
- **default:** `[]`
- **see also:** [<u>method `rpm.wheel_robot()`</u>](Methods.md#rpm-wheel-robot)
- **usage:**
    ```matlab
    robot.Metadata.Number = '001';
    ```

### `Metadata.Description`

Free-form information about the robot, such as its purpose, hardware, or configuration. It is descriptive metadata and does not participate in model calculations.

- **type:** User-defined; conventionally `char`, as in the default value.
- **default:** `'none'`
- **see also:** [<u>method `rpm.wheel_robot()`</u>](Methods.md#rpm-wheel-robot)
- **usage:**
    ```matlab
    robot.Metadata.Description = 'A two-wheel differential-drive robot.';
    ```

## 2.* `States`

The vector order is `[x; y; theta; left_wheel_angle; left_wheel_speed; right_wheel_angle; right_wheel_speed]`, corresponding to the theoretical notation $[x, y, \theta, \alpha_L, \Omega_L, \alpha_R, \Omega_R]^\mathsf{T}$.

The dynamic states of the Wheel-Robot, stored as a private `7x1 double` vector. Initialize them through the constructor's `Ini_States` argument or `reset(ini_states)`, and read them with `getStates()` or the individual getters. Seven-element finite, real numeric row and column vectors are accepted and converted to a double column vector. `step()` integrates all seven states, including wheel angles and first-order wheel-speed responses.

Wheel angle and speed are interleaved for each wheel: indices `4` and `5` belong to the left wheel, while `6` and `7` belong to the right wheel. Concatenating `[pose; wheel_angles; wheel_speeds]` does not produce this layout; use `[pose; wheel_angles(1); wheel_speeds(1); wheel_angles(2); wheel_speeds(2)]` instead.

### `States(1)` `States(2)`

The x-position and y-position of the drive-axle midpoint in the *world* frame, respectively, in metres (m). The pose reference point is not shifted by the display parameter `Params.axleOffset`.

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `getPose()`</u>](Methods.md#getpose), [<u>method `getStates()`</u>](Methods.md#getstates), and [<u>method `getPoseDot()`</u>](Methods.md#getposedot)

### `States(3)`

The heading angle in the *world* frame, in radians (rad), measured counterclockwise from the world x-axis. By default it accumulates without wrapping; when `Config.wrap_heading` is enabled, `step()` maps it to `[-pi, pi)` after integration. Constructor and reset inputs are not immediately wrapped.

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `getPose()`</u>](Methods.md#getpose), [<u>method `setWrapHeading()`</u>](Methods.md#setwrapheadingwrap_heading), and [<u>method `step()`</u>](Methods.md#stepdt-t)

### `States(4)` `States(6)`

The accumulated rotation angles of the left and right wheels, respectively, in radians (rad). Positive rotation corresponds to forward rolling. Each angle is integrated from its actual wheel speed, not its commanded target; the angles are never normalized modulo `2*pi`, even when heading wrapping is enabled.

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `getWheelAngle()`</u>](Methods.md#getwheelangle), [<u>method `getWheelSpeed()`</u>](Methods.md#getwheelspeed), and [<u>method `stateDerivative()`</u>](Methods.md#statederivativez-u-t)

### `States(5)` `States(7)`

The actual angular speeds of the left and right wheels, respectively, in rad/s. Positive speeds correspond to forward rolling. Each follows its own held command through a first-order response with the corresponding `motorTimeConstant`, so these states can differ from `Cmd`.

The constructor and `reset()` accept any finite real initial wheel speeds, including values outside `Params.maxWheelSpeed`. They neither reject nor clip such values on speed-range grounds: that parameter limits command targets only. Held commands start at zero, so nonzero initial speeds decay towards zero unless new targets are sent. No separate state clipping is performed after integration.

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `getWheelSpeed()`</u>](Methods.md#getwheelspeed), [<u>method `getVel()`</u>](Methods.md#getvel), [<u>method `reset()`</u>](Methods.md#resetini_states), and [<u>method `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd)

## 3.* `Params`

The physical and display parameters of the Wheel-Robot, stored in a private scalar structure. The seven fields below are all required: each corresponds to a top-level YAML key with exactly the same case-sensitive name. For example, YAML `wheelRadius: [0.10, 0.12]` becomes MATLAB `params.wheelRadius = [0.10; 0.12]` after loading; the YAML file does not contain a surrounding `Params:` key.

When the constructor's `Params` argument is omitted or `[]`, `rpm.utils.load_wheel_params()` reads the project's `+rpm/config/wheel_robot.yaml`. To use a custom file, call `rpm.utils.load_wheel_params(file_path)` and pass its returned structure to the constructor. Alternatively, supply a manually created scalar structure containing all seven fields. Missing fields cause an error; individual missing values are not filled from the default YAML file.

For `wheelRadius`, `motorTimeConstant`, `maxWheelSpeed`, and `wheelWidth`, a scalar specifies the same value for both wheels; a two-element row or column vector specifies `[left; right]`. The loader and constructor normalize these fields to `2x1 double` vectors, `bodySize` to a `3x1 double` vector, and the remaining required fields to double scalars. The loader preserves zero time constants; the constructor warns and replaces only the zero elements with `1e-3` s. The **default** values below come from the bundled YAML template rather than hard-coded per-field constructor defaults.

Parameters are copied into the object at construction. Editing the YAML file, the original structure, or a copy returned by `getParams()` does not update an existing robot. Create a new object to apply changed physical parameters; `reset()` preserves them. Additional fields in a manually supplied structure are retained by the constructor, but `rpm.utils.load_wheel_params()` returns only the seven recognized fields. The YAML parameter file does not configure `Metadata`, `States`, `Cmd`, or `Config`.

For example, export a template once, edit its values, then load it:

```matlab
rpm.utils.export_wheel_params('my_wheel.yaml'); % Refuses to overwrite an existing file.
% Edit my_wheel.yaml before loading it.
params = rpm.utils.load_wheel_params('my_wheel.yaml');
params.wheelRadius = [0.08; 0.12]; % Optional in-memory override; does not edit the YAML.
robot = rpm.wheel_robot(params);
actual_params = robot.getParams();
```

Keep custom YAML files in the supported flat numeric form: `key: number` or `key: [number, ...]`. Without `readyaml`, the bundled fallback reader does not support nested YAML or inline comments after values; use separate comment lines. Relative custom file paths are resolved from MATLAB's current working directory.

### `Params.wheelRadius`

The effective rolling radii of the left and right wheels, in metres (m). The corresponding linear rolling speeds are `r_L * Omega_L` and `r_R * Omega_R`. Different radii are supported; equal angular speeds produce straight motion only when the effective radii are also equal.

- **type:** `2x1 double` (scalar or two-element row/column input accepted)
- **default:** `[0.10; 0.10]`
- **constraints:** Two finite, real, strictly positive elements.
- **YAML key:** `wheelRadius`
- **see also:** [<u>method `stateDerivative()`</u>](Methods.md#statederivativez-u-t), [<u>method `wheel2body()`</u>](Methods.md#wheel2bodywheel_speed), and [<u>method `body2wheel()`</u>](Methods.md#body2wheelbody_velocity)

### `Params.trackWidth`

The lateral distance between the left and right wheel centre lines, in metres (m). It relates the difference in wheel linear speeds to the drive-axle midpoint's yaw rate: `omega = (r_R * Omega_R - r_L * Omega_L) / trackWidth`.

- **type:** `double` scalar
- **default:** `0.45`
- **constraints:** Finite, real, and strictly positive.
- **YAML key:** `trackWidth`
- **see also:** [<u>method `stateDerivative()`</u>](Methods.md#statederivativez-u-t), [<u>method `kin_fwd()`</u>](Methods.md#kin_fwd), and [<u>method `kin_inv()`</u>](Methods.md#kin_inv)

### `Params.motorTimeConstant`

The time constants of the left and right wheel-speed responses, in seconds (s): `dOmega_i/dt = (Omega_i_cmd - Omega_i) / T_i`. A smaller value gives a faster response. For a constant target, one time constant closes approximately 63.2% of the initial speed error in the continuous model. Different time constants can produce transient turning even when the commanded steady-state wheel linear speeds are equal.

- **type:** `2x1 double` (scalar or two-element row/column input accepted)
- **default:** `[0.15; 0.15]`
- **constraints:** Two finite, real, nonnegative elements. Zeros are accepted by the loader, but the constructor issues `wheel_robot:ZeroMotorTimeConstant` and replaces only those elements with `1e-3` s to approximate ideal actuators.
- **YAML key:** `motorTimeConstant`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams), [<u>method `stateDerivative()`</u>](Methods.md#statederivativez-u-t), and the step-size warning check in [<u>method `step()`</u>](Methods.md#stepdt-t)

### `Params.maxWheelSpeed`

The maximum absolute target angular speeds of the left and right wheels, in rad/s, measured at the wheels rather than at motor shafts before gearboxes. `sendCmd()` clips each target independently to its own symmetric range. These are command limits, not guaranteed bounds on actual states: initial wheel speeds are unrestricted apart from being finite real values, and numerical integration does not clip wheel-speed states.

- **type:** `2x1 double` (scalar or two-element row/column input accepted)
- **default:** `[20.0; 20.0]`
- **constraints:** Two finite, real, strictly positive elements.
- **YAML key:** `maxWheelSpeed`
- **see also:** [<u>method `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>method `getParams()`</u>](Methods.md#getparams), and [<u>method `getWheelSpeed()`</u>](Methods.md#getwheelspeed)

### `Params.bodySize`

The bounding-box dimensions of the main robot body, excluding wheels, in metres (m), ordered as `[length; width; height]`. This is a display geometry parameter; it does not affect the current motion equations.

- **type:** `3x1 double` (three-element row or column input accepted)
- **default:** `[0.60; 0.40; 0.20]`
- **constraints:** Three finite, real, strictly positive elements.
- **YAML key:** `bodySize`; written as `bodySize: [0.60, 0.40, 0.20]` in YAML and normalized to a column vector.
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams) and [<u>method `getParams()`</u>](Methods.md#getparams) for external rendering or geometry calculations

### `Params.wheelWidth`

The widths of the left and right wheels along their axle direction, in metres (m). This is a display geometry parameter and does not affect the wheel-speed or pose equations.

- **type:** `2x1 double` (scalar or two-element row/column input accepted)
- **default:** `[0.05; 0.05]`
- **constraints:** Two finite, real, strictly positive elements.
- **YAML key:** `wheelWidth`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams) and [<u>method `getParams()`</u>](Methods.md#getparams) for external rendering or geometry calculations

### `Params.axleOffset`

The signed longitudinal offset of the drive-axle midpoint from the body's geometric centre, in metres (m), along the body forward axis. A positive value places the axle ahead of the body centre; a negative value places it behind. This display geometry parameter locates the body relative to the pose reference point and does not shift the reference point used by the motion equations.

- **type:** `double` scalar
- **default:** `0.0`
- **constraints:** Any finite real scalar; positive, negative, and zero values are allowed.
- **YAML key:** `axleOffset`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams) and [<u>method `getParams()`</u>](Methods.md#getparams) for external rendering or geometry calculations

## 4.* `Cmd`

The private scalar structure holding the latest clipped left and right wheel-speed commands. Its fields are `left` and `right`; `getCmd()` returns their values as the vector `[left_wheel_cmd; right_wheel_cmd]`, corresponding to the theoretical notation $[\Omega_{L,\mathrm{cmd}}, \Omega_{R,\mathrm{cmd}}]^\mathsf{T}$.

`sendCmd()` updates the targets, and every `step()` uses the same held values until the next `sendCmd()` or `reset()`. The constructor and `reset()` initialize both fields to zero, even when initial wheel speeds are nonzero. Sending a command does not immediately change actual wheel speeds, wheel angles, or pose.

### `Cmd.left` `Cmd.right`

The target angular speeds of the left and right wheels, respectively, in rad/s. Positive values correspond to forward rolling. Each input is clipped independently to `[-Params.maxWheelSpeed(i), Params.maxWheelSpeed(i)]`; actual wheel speeds approach these held targets through their respective first-order responses.

- **type:** `double` scalar for each field
- **default:** `0` for each field
- **see also:** [<u>method `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd), [<u>method `getCmd()`</u>](Methods.md#getcmd), and [<u>method `step()`</u>](Methods.md#stepdt-t)

## 5.* `Config`

The private simulation configuration structure, initialized by the constructor and preserved by `reset()`. Change its fields through the public setters below. These options are not read from the physical-parameter YAML file.

### `Config.solution_method`

The fixed-step integration method used to advance all seven states in `step()`. `'euler'` selects explicit Euler; `'RK4'` selects classical fourth-order Runge-Kutta. `setSolutionMethod()` accepts either name case-insensitively as a character row vector or string scalar and stores the canonical spelling. A successful call clears the step-size warning flag without changing states or held commands.

- **type:** `char`
- **default:** `'RK4'`
- **see also:** [<u>method `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method) and [<u>method `step()`</u>](Methods.md#stepdt-t)

### `Config.wrap_heading`

Whether `step()` normalizes the heading to `[-pi, pi)` after completing an integration step. `false` preserves accumulated heading; `true` discards complete rotation counts. Setting this option does not immediately alter the heading, and disabling it later does not restore discarded rotations. The two wheel angles are unaffected and always accumulate without wrapping.

- **type:** `logical` scalar
- **default:** `false`
- **see also:** [<u>method `setWrapHeading()`</u>](Methods.md#setwrapheadingwrap_heading), [<u>method `step()`</u>](Methods.md#stepdt-t), and [<u>method `getWheelAngle()`</u>](Methods.md#getwheelangle)

### `Config.warn_on_saturation`

Whether each `sendCmd()` call that clips one or both out-of-range targets issues `wheel_robot:CommandSaturated`. Disabling this option suppresses that warning only: clipping still occurs, and zero-time-constant and large-step warnings remain independent.

- **type:** `logical` scalar
- **default:** `true`
- **see also:** [<u>method `setWarnOnSaturation()`</u>](Methods.md#setwarnonsaturationwarn_on_saturation) and [<u>method `sendCmd()`</u>](Methods.md#sendcmdleft_wheel_cmd-right_wheel_cmd)

## 6.* `StepSizeWarningActive`

A private flag that prevents consecutive large-step calls from repeating the same warning. In `step()`, the model calculates `ratio = max(dt ./ Params.motorTimeConstant)`. When `ratio > 0.1`, it issues `wheel_robot:LargeStepSize` only if this flag was `false`, then sets it to `true`. Further steps in the warning range remain silent, even if their step sizes change. A step with `ratio <= 0.1` clears the flag, allowing a later large step to warn again.

- **type:** `logical` scalar
- **default:** `false`
- **see also:** [<u>method `step()`</u>](Methods.md#stepdt-t) checks and updates it; [<u>method `reset()`</u>](Methods.md#resetini_states) and a successful [<u>method `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method) clear it. The constructor initializes it through [<u>method `reset()`</u>](Methods.md#resetini_states).

---
