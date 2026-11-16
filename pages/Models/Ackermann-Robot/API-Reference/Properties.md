# Ackermann-Robot Properties

> **Tips:** Sections with `'*'` are **private** properties/methods.

## 1. `Metadata`

The basic information of the Ackermann-Robot, stored in a public structure. These fields do not affect simulation, and custom fields may be added. They can be provided through the constructor's `Metadata` argument or edited through `robot.Metadata`.

### `Metadata.Name`

A descriptive name for identifying the robot in displays, logs, or application code; it does not change the model's behavior.

- **type:** `char`
- **default:** `'ackermann_robot'`
- **see also:** [<u>method `rpm.ackermann_robot()`</u>](Methods.md#rpm-ackermann-robot)
- **usage:**
    ```matlab
    robot.Metadata.Name = 'AckerBot';
    ```

### `Metadata.Number`

An optional identifier for distinguishing robots in multi-robot applications. The model does not assign, validate, or use this identifier in its calculations.

- **type:** User-defined; for example, `char` (the default `[]` is an empty `double` array).
- **default:** `[]`
- **see also:** [<u>method `rpm.ackermann_robot()`</u>](Methods.md#rpm-ackermann-robot)
- **usage:**
    ```matlab
    robot.Metadata.Number = '0';
    ```

### `Metadata.Description`

Free-form information about the robot, such as its purpose, hardware, or configuration. It is descriptive metadata and does not participate in model calculations.

- **type:** `char`
- **default:** `'none'`
- **see also:** [<u>method `rpm.ackermann_robot()`</u>](Methods.md#rpm-ackermann-robot)
- **usage:**
    ```matlab
    robot.Metadata.Description = 'AckerBot is a robot with ackermann steering.';
    ```

## 2.* `States`

The vector order is `[x; y; theta; delta; Omega]`, corresponding to the theoretical notation $[x, y, \theta, \delta, \Omega]^\mathsf{T}$.

The dynamic states of the Ackermann-Robot, stored as a private `5x1 double` vector. Initialize them through the constructor's `Ini_States` argument or `reset(ini_states)`, and read them with `getStates()` or the individual getters. Five-element row and column vectors are accepted and converted to a column vector. `step()` integrates these states; the physical front-wheel angles and four physical wheel speeds are calculated from them rather than integrated independently.

### `States(1)` `States(2)`

The x-position and y-position of the rear-axle midpoint in the *world* frame, respectively, in metres (m).

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `getPose()`</u>](Methods.md#getpose)

### `States(3)`

The heading angle in the *world* frame, in radians (rad), measured counterclockwise from the world x-axis. By default it accumulates without wrapping; when `Config.wrap_heading` is enabled, `step()` maps it to `[-pi, pi)` after integration.

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `getPose()`</u>](Methods.md#getpose)

### `States(4)` `States(5)`

The actual virtual front-wheel steering angle (rad) and virtual wheel angular speed (rad/s), respectively, in the *robot-body* frame. Positive values indicate left steering and forward motion. Each follows its held command through a first-order inertial actuator response, so these states can differ from `Cmd`. In both the constructor and `reset()`, initial steering must satisfy `abs(delta) < atan(2*wheelBase/trackWidth)`, and both initial actuator states must lie within the symmetric conservative transient bounds returned by `getCmdLimits()` (including the boundaries). Out-of-range values cause `ackermann_robot:InvalidInitialState` rather than automatic clipping; the actuator-range error reports the allowed steering and wheel-speed ranges. A rejected `reset()` preserves the existing states and held command.

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `getVirtualSteeringAngle()`</u>](Methods.md#getvirtualsteeringangle) and [<u>method `getVirtualWheelSpeed()`</u>](Methods.md#getvirtualwheelspeed)

## 3.* `Params`

The physical and display parameters of the Ackermann-Robot, stored in a private scalar structure. The ten fields below are all required: each corresponds to a top-level YAML key with exactly the same case-sensitive name. For example, YAML `wheelRadius: 0.1` becomes MATLAB `params.wheelRadius = 0.1` after loading; the YAML file does not contain a surrounding `Params:` key.

When the constructor's `Params` argument is omitted or `[]`, `rpm.utils.load_ackermann_params()` reads the project's `+rpm/config/ackermann_robot.yaml`. To use a custom file, call `rpm.utils.load_ackermann_params(file_path)` and pass its returned structure to the constructor. Alternatively, supply a manually created structure containing all ten fields. Missing fields cause an error; individual missing values are not filled from the default YAML file.

The loader and constructor validate the parameters and normalize their numeric values to `double` scalars or column vectors. The loader preserves zero time constants; the constructor warns and replaces them with `1e-3` s. The **default** values below are the values in the bundled YAML template, rather than hard-coded per-field constructor defaults.

Parameters are copied into the object at construction. Editing the YAML file or the original structure later does not update an existing robot. `getParams()` returns a copy of the actual parameters in use, including any time-constant replacements; editing that copy also does not update the robot. Create a new object to apply changed physical parameters. `reset()` preserves them. The YAML parameter file does not configure `Metadata`, `States`, `Cmd`, or `Config`.

For example, export a template once, edit its values, then load it:

```matlab
rpm.utils.export_ackermann_params('my_ackermann.yaml'); % Refuses to overwrite an existing file.
% Edit my_ackermann.yaml before loading it.
params = rpm.utils.load_ackermann_params('my_ackermann.yaml');
params.wheelRadius = 0.12; % Optional in-memory override; does not edit the YAML.
robot = rpm.ackermann_robot(params);
actual_params = robot.getParams();
```

Keep custom YAML files in the supported flat numeric form: `key: number` or `key: [number, ...]`. Without `readyaml`, the bundled fallback reader does not support nested YAML or inline comments after values; use separate comment lines.

<!-- TODO: Add the parameter illustration and its relative image link when the asset is available. -->

### `Params.wheelRadius`

The common effective rolling radius of all four wheels, in metres (m). It converts virtual wheel angular speed into the forward speed of the rear-axle midpoint: `v = wheelRadius * Omega`.

- **type:** `double` scalar
- **default:** `0.1`
- **constraints:** Finite, real, and strictly positive.
- **YAML key:** `wheelRadius`
- **see also:** [<u>method `stateDerivative()`</u>](Methods.md#statederivativezut), [<u>method `virtual2body()`</u>](Methods.md#virtual2bodyvirtual_state), and [<u>method `body2virtual()`</u>](Methods.md#body2virtualbody_velocity); also used indirectly by [<u>method `getVel()`</u>](Methods.md#getvel) and [<u>method `getPoseDot()`</u>](Methods.md#getposedot).

### `Params.wheelBase`

The longitudinal distance between the front and rear axle centre lines, in metres (m). It determines yaw rate in the bicycle model and participates in the Ackermann mapping and virtual command limits.

- **type:** `double` scalar
- **default:** `0.60`
- **constraints:** Finite, real, and strictly positive.
- **YAML key:** `wheelBase`
- **see also:** [<u>method `stateDerivative()`</u>](Methods.md#statederivativezut), [<u>method `virtual2body()`</u>](Methods.md#virtual2bodyvirtual_state), [<u>method `body2virtual()`</u>](Methods.md#body2virtualbody_velocity), [<u>method `physicalWheelMap()`</u>](Methods.md#physicalwheelmapz), [<u>method `commandLimits()`</u>](Methods.md#commandlimits), and [<u>method `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

### `Params.trackWidth`

The lateral distance between the left and right wheel centre lines, in metres (m), shared by the front and rear axles. It determines the difference between the left/right physical steering angles and wheel speeds.

- **type:** `double` scalar
- **default:** `0.45`
- **constraints:** Finite, real, and strictly positive.
- **YAML key:** `trackWidth`
- **see also:** [<u>method `physicalWheelMap()`</u>](Methods.md#physicalwheelmapz), [<u>method `commandLimits()`</u>](Methods.md#commandlimits), and [<u>method `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

### `Params.wheelTimeConstant`

The time constant of the virtual wheel-speed actuator, in seconds (s): `dOmega/dt = (Omega_c - Omega) / wheelTimeConstant`. A smaller value gives a faster response. For a constant target, one time constant closes approximately 63.2% of the initial speed error in the continuous model.

- **type:** `double` scalar
- **default:** `0.2`
- **constraints:** Finite, real, and nonnegative. A value of `0` is accepted by the loader, but the constructor issues `ackermann_robot:ZeroTimeConstant` and replaces it with `1e-3` s to approximate an ideal actuator.
- **YAML key:** `wheelTimeConstant`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams), [<u>method `stateDerivative()`</u>](Methods.md#statederivativezut), and the step-size warning check in [<u>method `step()`</u>](Methods.md#stepdt-t).

### `Params.steeringTimeConstant`

The time constant of the virtual steering actuator, in seconds (s): `ddelta/dt = (delta_c - delta) / steeringTimeConstant`. A smaller value gives a faster steering response. For a constant target, one time constant closes approximately 63.2% of the initial steering error in the continuous model.

- **type:** `double` scalar
- **default:** `0.1`
- **constraints:** Finite, real, and nonnegative. A value of `0` is accepted by the loader, but the constructor issues `ackermann_robot:ZeroTimeConstant` and replaces it with `1e-3` s.
- **YAML key:** `steeringTimeConstant`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams), [<u>method `stateDerivative()`</u>](Methods.md#statederivativezut), and the step-size warning check in [<u>method `step()`</u>](Methods.md#stepdt-t).

### `Params.maxPhysicalWheelSpeed`

The maximum absolute angular speed of any physical wheel, in rad/s, measured at the wheel rather than at the motor shaft before a gearbox. It is converted into a conservative, steering-independent virtual wheel-speed command limit over the allowed steering range. The four physical wheel speeds are not clipped separately.

- **type:** `double` scalar
- **default:** `20.0`
- **constraints:** Finite, real, and strictly positive.
- **YAML key:** `maxPhysicalWheelSpeed`
- **see also:** [<u>method `commandLimits()`</u>](Methods.md#commandlimits), called by [<u>method `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>method `getCmdLimits()`</u>](Methods.md#getcmdlimits), and [<u>method `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

### `Params.maxPhysicalSteeringAngle`

The maximum absolute steering angle of either physical front wheel, in radians (rad). It is converted through Ackermann geometry into a symmetric virtual steering command limit, which is generally smaller than this physical limit. The physical front-wheel angles are not clipped separately.

- **type:** `double` scalar
- **default:** `0.61086524` (approximately 35 degrees)
- **constraints:** Finite, real, and strictly between `0` and `pi/2`.
- **YAML key:** `maxPhysicalSteeringAngle`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams) and [<u>method `commandLimits()`</u>](Methods.md#commandlimits); the latter is called by [<u>method `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>method `getCmdLimits()`</u>](Methods.md#getcmdlimits), and [<u>method `validateInitialStates()`</u>](Methods.md#validateinitialstatesstates).

The two physical limits above determine the conservative transient bounds returned by `getCmdLimits()`. `sendCmd()` clips its targets to these bounds, while the constructor and `reset()` require the initial virtual steering angle and wheel speed to already satisfy the same bounds, including their boundaries. Invalid initial states are rejected, not clipped. This rectangle is conservative: an initial state may be rejected even if its instantaneous physical wheel values satisfy the physical limits. With valid initial states and bounded commands, the continuous first-order actuator model remains within this rectangle; numerical simulation still requires a suitable integration step size and method.

### `Params.bodySize`

The bounding-box dimensions of the main robot body, excluding wheels, in metres (m), ordered as `[length; width; height]`. This is a display geometry parameter; it does not affect the current motion equations.

- **type:** `double`, `3x1` column vector (three-element row or column input accepted)
- **default:** `[0.70; 0.40; 0.20]`
- **constraints:** Three finite, real, strictly positive elements.
- **YAML key:** `bodySize`; written as `bodySize: [0.70, 0.40, 0.20]` in YAML and normalized to a column vector.
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams) and [<u>method `getParams()`</u>](Methods.md#getparams) for external rendering or geometry calculations; not used by the current motion equations.

### `Params.wheelWidth`

The common width of all four wheels along their axle direction, in metres (m). This is a display geometry parameter and does not affect wheel-speed or steering calculations.

- **type:** `double` scalar
- **default:** `0.05`
- **constraints:** Finite, real, and strictly positive.
- **YAML key:** `wheelWidth`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams) and [<u>method `getParams()`</u>](Methods.md#getparams) for external rendering or geometry calculations; not used by the current motion equations.

### `Params.rearAxleOffset`

The signed longitudinal offset of the rear-axle midpoint from the body's geometric centre, in metres (m), along the body forward axis. A positive value places the rear axle ahead of the body centre; a negative value places it behind. This display geometry parameter locates the body relative to the pose reference point and does not shift the reference point used by the motion equations.

- **type:** `double` scalar
- **default:** `-0.30`
- **constraints:** Any finite real scalar; positive, negative, and zero values are allowed.
- **YAML key:** `rearAxleOffset`
- **see also:** [<u>method `validateParams()`</u>](Methods.md#validateparamsparams) and [<u>method `getParams()`</u>](Methods.md#getparams) for external rendering or geometry calculations; not used by the current motion equations.


## 4.* `Cmd`

The vector order is `[steering_angle_cmd; wheel_speed_cmd]`, corresponding to the theoretical notation $[\delta_c, \Omega_c]^\mathsf{T}$.

The private `2x1 double` vector holding the latest clipped virtual actuator command. `sendCmd()` updates it, `getCmd()` reads it, and every `step()` uses the same held values until the next `sendCmd()` or `reset()`. The constructor and `reset()` initialize it to zero, even when the initial actuator states are nonzero. Sending a command changes the targets without immediately changing the actual states or pose.

### `Cmd(1)` `Cmd(2)`

The virtual steering angle target (rad) and virtual wheel angular-speed target (rad/s), respectively. Positive values indicate left steering and forward motion. Each input is clipped independently to the symmetric bounds returned by `getCmdLimits()`; the actual actuator states approach these held targets through their first-order dynamics.

- **type:** `double`
- **default:** `0`
- **see also:** [<u>method `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd), [<u>method `getCmd()`</u>](Methods.md#getcmd) and [<u>method `step()`</u>](Methods.md#stepdt-t)

## 5.* `Config`

The private simulation configuration structure, initialized by the constructor and preserved by `reset()`. Change its fields through the public setters below. These options are not read from the physical-parameter YAML file.

### `Config.solution_method`

The fixed-step integration method used to advance all five states in `step()`. `'euler'` selects explicit Euler; `'RK4'` selects classical fourth-order Runge-Kutta. `setSolutionMethod()` accepts either name case-insensitively as a character row vector or string scalar and stores the canonical spelling. Changing the method resets the step-size warning flag without changing the states or held command.

- **type:** `char`
- **default:** `'RK4'`
- **see also:** [<u>method `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method) and [<u>method `step()`</u>](Methods.md#stepdt-t).

### `Config.wrap_heading`

Whether `step()` normalizes the heading to `[-pi, pi)` after completing an integration step. `false` preserves accumulated heading; `true` discards complete rotation counts. Setting this option does not immediately alter the heading, and disabling it later does not restore discarded rotations.

- **type:** `logical` scalar
- **default:** `false`
- **see also:** [<u>method `setWrapHeading()`</u>](Methods.md#setwrapheadingwrap_heading) and [<u>method `step()`</u>](Methods.md#stepdt-t).

### `Config.warn_on_saturation`

Whether each `sendCmd()` call that clips an out-of-range command issues `ackermann_robot:CommandSaturated`. Disabling this option suppresses that warning only: clipping still occurs, and zero-time-constant and large-step warnings remain independent.

- **type:** `logical` scalar
- **default:** `true`
- **see also:** [<u>method `setWarnOnSaturation()`</u>](Methods.md#setwarnonsaturationwarn_on_saturation) and [<u>method `sendCmd()`</u>](Methods.md#sendcmdsteering_angle_cmd-wheel_speed_cmd).

## 6.* `StepSizeWarningActive`

A private flag that prevents consecutive large-step calls from repeating the same warning. In `step()`, the model calculates `ratio = max(dt ./ [steeringTimeConstant; wheelTimeConstant])`. When `ratio > 0.1`, it issues `ackermann_robot:LargeStepSize` only if this flag was `false`, then sets it to `true`. Further steps in the same warning range remain silent, even if their step sizes change. A step with `ratio <= 0.1` clears the flag, allowing a later large step to warn again.

- **type:** `logical` scalar
- **default:** `false`
- **see also:** [<u>method `step()`</u>](Methods.md#stepdt-t) checks and updates it; [<u>method `reset()`</u>](Methods.md#resetini_states) and a successful [<u>method `setSolutionMethod()`</u>](Methods.md#setsolutionmethodsolution_method) clear it. The constructor initializes it through [<u>method `reset()`</u>](Methods.md#resetini_states).

---
