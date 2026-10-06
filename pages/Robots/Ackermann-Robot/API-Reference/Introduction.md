# Introduction

`rpm.ackermann_robot` is a MATLAB `handle` class for simulating a planar, front-steered, rear-driven Ackermann robot under pure rolling without lateral slip. It integrates five states: the rear-axle midpoint's world-frame pose, virtual steering angle, and virtual wheel angular speed. Physical front-wheel angles and four wheel speeds are calculated from these states.

Heading is measured counterclockwise from the world x-axis; positive virtual steering means left steering, and positive wheel speed means forward motion. Units are metres, seconds, and radians. Only `Metadata` is publicly accessible; use methods to read states and parameters or change simulation settings. Assigning the object to another variable shares the same instance.

## 1. API Organization

- [Properties](Properties.md): metadata, state layout, YAML parameters, held commands, and private simulation configuration.
- [Methods](Methods.md): initialization, getters, configuration setters, command submission, integration, and velocity conversions.
- [Utils](Utils.md): YAML parameter loading, validation, and configuration template export.
- [Modeling](../Modeling/ackermann-robot-model.md): reserved for the detailed theoretical derivation; the page is not yet populated.

## 2. Basic Usage

With the project root (the parent of `+rpm/`) on the MATLAB search path, create a robot, send actuator targets, advance the simulation, and read the result. Calling `sendCmd()` alone does not move the robot; commands are held until another command or reset. The same root path makes the parameter-loading and export helpers available; do not add `+rpm/` or its subdirectories separately. In a source checkout, run `setup` from `packaging/`; in a release ZIP, run it from the extracted top-level directory.

```matlab
robot = rpm.ackermann_robot();
robot.sendCmd(0.2, 5); % Virtual steering angle [rad] and wheel speed [rad/s]
for k = 1:100
    robot.step(0.005, (k - 1) * 0.005); % Suitable for the bundled parameters
end
pose = robot.getPose();
fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', pose(1), pose(2), pose(3));
```

## 3. Optional Namespace Import

Public classes belong to `rpm`; shared helper functions belong to `rpm.utils`. The examples above use fully qualified names for clarity. To use short names, import both namespaces at the beginning of the script or function, or enter the imports at the command prompt. `import rpm.*` does not import the nested `rpm.utils` functions:

```matlab
import rpm.*
import rpm.utils.*
params = load_ackermann_params();
robot = ackermann_robot(params);
robot.step(0.001);
```

Imports apply to the scope where they are declared, not to every function or future MATLAB session. A command-window import does not replace imports inside functions; add an import where the short names are used. Importing also does not install the project or add it to the MATLAB search path. Object method calls such as `robot.step()` are unchanged.

Wildcard imports can introduce name conflicts. Use `rpm.ackermann_robot()` to identify the class unambiguously, or import only the required names, for example `import rpm.ackermann_robot` and `import rpm.utils.load_ackermann_params`. For MATLAB's import and scope rules, see the [official `import` documentation](https://www.mathworks.com/help/matlab/ref/import.html).
