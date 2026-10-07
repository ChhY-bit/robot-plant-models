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

Robot classes use the `rpm` namespace. Shared utilities for Ackermann, differential-drive, and humanoid robots live in `+rpm/+utils/` and use `rpm.utils`, for example `rpm.utils.load_wheel_params()` and `rpm.utils.load_urdf(file_path)`.

Robot structure trees and their link/joint nodes live in `+rpm/+chain/`, using
`rpm.chain.robotTree`, `rpm.chain.linkNode` and `rpm.chain.jointNode`.

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

## URDF structure tree

`rpm.utils.load_urdf` always supplies a complete `origin` for each joint and
each existing inertial, visual or collision element. Missing `origin.xyz`
and `origin.rpy` default to `[0; 0; 0]`, including when `<origin>` is omitted.
Explicit values are preserved; malformed attributes remain errors. Other
optional elements retain `[]` when absent, including an absent inertial element.

For revolute, continuous, prismatic and planar joints, an omitted axis defaults
to `[1; 0; 0]`. The reader preserves explicit axes; `jointNode` validates and
normalizes them to double unit column vectors in `description.axis`, including
for directly supplied structs. Zero or invalid axes fail node construction.
Prismatic motion can therefore use `description.axis * q` directly.

`rpm.utils.rpy2rot(rpy)` converts a three-element row or column vector
`[roll, pitch, yaw]` in radians to a 3x3 rotation matrix, using
`Rz(yaw)*Ry(pitch)*Rx(roll)`. `rpm.utils.rot2rpy(R)` returns a column vector
with pitch in `[-pi/2, pi/2]`. At gimbal lock it selects roll = 0; equivalent
orientations need not have identical RPY values. Both utilities use only base
MATLAB and return double values.

`rpm.utils.axis2rot(axis, theta)` converts a nonzero three-element rotation axis
and an angle in radians to a double 3x3 active rotation matrix. It normalizes
the axis and applies the Rodrigues rotation formula directly.
For example, `rpm.utils.axis2rot([0; 0; 1], pi/2)` returns
`[0, -1, 0; 1, 0, 0; 0, 0, 1]` up to floating-point precision.

```matlab
urdf = rpm.utils.load_urdf("robot.urdf");
tree = rpm.chain.robotTree(urdf);
root = tree.baseLink;
if ~isempty(root.childJoint)
    joint = root.childJoint(1);         % Follow the kinematic hierarchy
    child = joint.childLink;
    parent = child.parentJoint.parentLink;
end
link = tree.getLink(urdf.links(1).name); % Search links from the root
if ~isempty(urdf.joints)
    joint = tree.getJoint(urdf.joints(1).name); % Search joints from the root
end
tree.show_tree();                      % Expand/collapse the hierarchy
tree.show_frames();                    % Plot link frames at zero displacement
```

`robotTree` retains only `baseLink`. Node arrays and name indices are local
to construction and are not stored in the tree. A link has one
`parentJoint` (empty for the root) and a column `rpm.chain.jointNode` array `childJoint`
(empty for leaves). Use parentheses to select a
node, for example `root.childJoint(1).childLink` when the root has children.
`getLink` and `getJoint` perform breadth-first searches using child references;
each searches only its own node type and returns the original handle object.
Link and joint names can overlap without ambiguity.
Each node retains its complete URDF struct in `description`. Node `name`
and joint `type` are dependent properties read from that struct, without
storing duplicate values. Tree/node properties, including joint `q` and `dq`,
are publicly readable and writable by `rpm.humanoid_robot` and their defining
classes. External code cannot assign them. `name` and `type` remain read-only;
update `description` from the main class to change their source values.
Joint `q` and `dq` are initialized to scalar zero when each node is created.
Tree construction connects nodes through its internal methods. Invalid topology
and unknown lookup names produce errors. This API initializes structure;
it does not evaluate joint states, mimic constraints or world transforms,
so `world_T` remains empty.

`show_tree` uses base MATLAB `uifigure`, `uitree` and `uitreenode` to display
alternating link and joint levels, with joint types in the labels. All
branches are initially expanded. The window resizes with its tree component.
`[fig, view] = tree.show_tree()` returns the window and tree UI handles;
each UI node's `NodeData` holds the original robot node. Use
`tree.show_tree("off")` to create a hidden window for scripting. The robot
does not retain UI handles or a second topology representation.

`fig = tree.show_frames()` plots the link coordinate frames at zero joint
displacement, with the root pose set to `eye(4)`. X/Y/Z axes are red/green/blue.
For a subtree, call `tree.show_frames(T0, linkName, fig)` or pass a `linkNode`
from this tree in place of `linkName`. `T0` is the starting link's world pose;
pass `[]` for default arguments. Child poses are accumulated directly through
joint references using the URDF origins (`Rz(yaw)*Ry(pitch)*Rx(roll)`). Existing
plots and axes hold state are preserved. This display does not update node
`world_T` or apply joint state/mimic motion. The method replaces the former
`humanoid_robot.show_frames`; subtree indices are replaced by names or objects.

`humanoid_robot` creates its `Tree` with the same `rpm.chain.robotTree` constructor:

```matlab
robot = rpm.humanoid_robot(urdf);
robot.Tree.show_tree();
robot.Tree.show_frames();
joint = robot.Tree.getJoint(urdf.joints(1).name); % If joints exist
```

Topology and visualization are handled by `robot.Tree`; each node retains its
own URDF description.

## License

Released under the [MIT License](LICENSE). Copyright (c) 2026 ChhY-bit.
