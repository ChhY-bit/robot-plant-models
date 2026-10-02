# Robot Plant Models

[![Documentation](https://img.shields.io/badge/docs-online-blue)](https://chhy-bit.github.io/robot-plant-models/) [![Latest release](https://img.shields.io/github/v/release/ChhY-bit/robot-plant-models?include_prereleases&label=release)](https://github.com/ChhY-bit/robot-plant-models/releases) [![Website deployment](https://github.com/ChhY-bit/robot-plant-models/actions/workflows/pages.yml/badge.svg?branch=main)](https://github.com/ChhY-bit/robot-plant-models/actions/workflows/pages.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

Open-source, customizable MATLAB plant models for mobile robots, including Ackermann and differential-drive robots. Explore their parameters, states, actuator dynamics, and command interfaces through the documentation.

## Documentation and downloads

- [Project website and documentation](https://chhy-bit.github.io/robot-plant-models/)
- [Releases and downloads](https://github.com/ChhY-bit/robot-plant-models/releases)
- [Issues and feedback](https://github.com/ChhY-bit/robot-plant-models/issues)

See the documentation for model APIs and the Releases page for available versions and release notes.

## Installation

MATLAB R2024a has been verified. Earlier releases have not been tested.

1. Download the project ZIP attached to a [release](https://github.com/ChhY-bit/robot-plant-models/releases) and extract it.
2. In MATLAB, open the extracted folder containing `setup.m` and `+rpm/`, then run `setup`.
3. Choose whether to save the MATLAB search path permanently when prompted. Keep the extracted folder in place after installation.

For a source checkout, run `setup` from `packaging/` instead. The script adds the project root to the search path; do not add `+rpm/` itself.

## Quick example

```matlab
robot = rpm.ackermann_robot();
robot.sendCmd(0.1, 1); % Steering angle [rad], wheel speed [rad/s]
for k = 1:100
    robot.step(0.001); % Simulation step [s]
end
pose = robot.getPose();
fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', pose(1), pose(2), pose(3));
```

For a differential-drive model, use `rpm.wheel_robot()`; its `sendCmd(left, right)` arguments are the left and right wheel speeds in rad/s. See the [API documentation](https://chhy-bit.github.io/robot-plant-models/Robots/) for details.

## License

Released under the [MIT License](LICENSE). Copyright (c) 2026 ChhY-bit.
