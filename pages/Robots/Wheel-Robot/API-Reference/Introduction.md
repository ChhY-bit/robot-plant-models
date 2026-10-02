# Introduction

`wheel_robot` is a MATLAB `handle` class for simulating a planar, two-wheel differential-drive robot under pure rolling without lateral slip. It integrates seven states: the drive-axle midpoint's world-frame pose, followed by each wheel's accumulated angle and actual angular speed. The two wheel speeds follow their held targets through separate first-order actuator responses; left and right parameters may differ.

Heading is measured counterclockwise from the world x-axis, and positive wheel rotation means forward rolling. Wheel pairs are always ordered left, then right. Units are metres, seconds, and radians. Only `Metadata` is publicly accessible; use methods to read states and parameters or change simulation settings. Assigning the object to another variable shares the same instance.

## 1. API Organization

- [Properties](Properties.md): metadata, the interleaved state layout, YAML parameters, held wheel commands, and private simulation configuration.
- [Methods](Methods.md): initialization, getters, configuration setters, command submission, integration, and body/wheel velocity conversions.
- [Modeling](../Modeling/wheel-robot-model.md): reserved for the detailed theoretical derivation; the page is not yet populated.

## 2. Basic Usage

With the project's `plants` directory on the MATLAB search path, create a robot, send wheel-speed targets, advance the simulation, and read the result. Calling `sendCmd()` alone does not move the robot; commands are held until another command or reset. Direct calls to parameter-loading or export helpers also require `utils` on the search path.

```matlab
robot = wheel_robot();
robot.sendCmd(4, 6); % Left and right wheel targets [rad/s]
for k = 1:100
    robot.step(0.005, (k - 1) * 0.005); % Suitable for the bundled parameters
end
pose = robot.getPose();
fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', pose(1), pose(2), pose(3));
```
