# Introduction

`rpm.wheel_robot` is a MATLAB `handle` class for simulating a planar, two-wheel differential-drive robot under pure rolling without lateral slip. It integrates seven states: the drive-axle midpoint's world-frame pose, followed by each wheel's accumulated angle and actual angular speed. The two wheel speeds follow their held targets through separate first-order actuator responses; left and right parameters may differ.

Heading is measured counterclockwise from the world x-axis, and positive wheel rotation means forward rolling. Wheel pairs are always ordered left, then right. Units are metres, seconds, and radians. Only `Metadata` is publicly accessible; use methods to read states and parameters or change simulation settings. Assigning the object to another variable shares the same instance.

## 1. API Organization

- [Properties](Properties.md): metadata, the interleaved state layout, YAML parameters, held wheel commands, and private simulation configuration.
- [Methods](Methods.md): initialization, getters, configuration setters, command submission, integration, and body/wheel velocity conversions.
- [Utils](Utils.md): YAML parameter loading, validation, and configuration template export.
- [Modeling](../Modeling/wheel-robot-model.md): reserved for the detailed theoretical derivation; the page is not yet populated.

## 2. Basic Usage

With the project root (the parent of `+rpm/`) on the MATLAB search path, create a robot, send wheel-speed targets, advance the simulation, and read the result. Calling `sendCmd()` alone does not move the robot; commands are held until another command or reset. The same root path makes the parameter-loading and export helpers available; do not add `+rpm/` or its subdirectories separately. In a source checkout, run `setup` from `packaging/`; in a release ZIP, run it from the extracted top-level directory.

```matlab
robot = rpm.wheel_robot();
robot.sendCmd(4, 6); % Left and right wheel targets [rad/s]
for k = 1:100
    robot.step(0.005, (k - 1) * 0.005); % Suitable for the bundled parameters
end
pose = robot.getPose();
fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', pose(1), pose(2), pose(3));
```

## 3. Optional Namespace Import

All public classes and helper functions belong to the `rpm` namespace. The examples above use fully qualified names for clarity. To omit the `rpm.` prefix in your own code, place `import rpm.*` at the beginning of the script or function, or enter it at the command prompt:

```matlab
import rpm.*
params = load_wheel_params();
robot = wheel_robot(params);
robot.step(0.001);
```

Imports apply to the scope where they are declared, not to every function or future MATLAB session. A command-window import does not replace imports inside functions; add an import where the short names are used. Importing also does not install the project or add it to the MATLAB search path. Object method calls such as `robot.step()` are unchanged.

Wildcard imports can introduce name conflicts. Use `rpm.wheel_robot()` to identify the class unambiguously, or import only the required names, for example `import rpm.wheel_robot` and `import rpm.load_wheel_params`. For MATLAB's import and scope rules, see the [official `import` documentation](https://www.mathworks.com/help/matlab/ref/import.html).
