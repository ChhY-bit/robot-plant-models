# Introduction

`ackermann_robot` is a MATLAB `handle` class for simulating a planar, front-steered, rear-driven Ackermann robot under pure rolling without lateral slip. It integrates five states: the rear-axle midpoint's world-frame pose, virtual steering angle, and virtual wheel angular speed. Physical front-wheel angles and four wheel speeds are calculated from these states.

Heading is measured counterclockwise from the world x-axis; positive virtual steering means left steering, and positive wheel speed means forward motion. Units are metres, seconds, and radians. Only `Metadata` is publicly accessible; use methods to read states and parameters or change simulation settings. Assigning the object to another variable shares the same instance.

## 1. API Organization

- [Properties](Properties.md): metadata, state layout, YAML parameters, held commands, and private simulation configuration.
- [Methods](Methods.md): initialization, getters, configuration setters, command submission, integration, and velocity conversions.
- [Modeling](../Modeling/ackermann-robot-model.md): reserved for the detailed theoretical derivation; the page is not yet populated.

## 2. Basic Usage

With the project's `plants` directory on the MATLAB search path, create a robot, send actuator targets, advance the simulation, and read the result. Calling `sendCmd()` alone does not move the robot; commands are held until another command or reset. Direct calls to parameter-loading or export helpers also require `utils` on the search path.

```matlab
robot = ackermann_robot();
robot.sendCmd(0.2, 5); % Virtual steering angle [rad] and wheel speed [rad/s]
for k = 1:100
    robot.step(0.005, (k - 1) * 0.005); % Suitable for the bundled parameters
end
pose = robot.getPose();
fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', pose(1), pose(2), pose(3));
```
