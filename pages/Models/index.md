---
title: Models
sidebar: false
aside: false
prev: false
next: false
---

# Models

Explore MATLAB plant models, each with its own state layout, actuator dynamics, and command interface. Choose a model to explore its API.

<ModelCards />

Also available: [Quadruple Tank](Quadruple-Tank/API-Reference/Introduction.md), a four-state liquid-level plant with two pump inputs, adjustable valves, and additive disturbances. Its documentation covers [properties](Quadruple-Tank/API-Reference/Properties.md), [methods](Quadruple-Tank/API-Reference/Methods.md), [parameter utilities](Quadruple-Tank/API-Reference/Utils.md), and [model equations](Quadruple-Tank/Modeling/quadruple-tank-model.md).

## What is available?

Explore Introduction, Properties, and Methods references for the available models. The quadruple-tank equations are documented; the robot modeling pages remain reserved for future theoretical derivations and are marked as work in progress.

These are simulation plant models, not hardware drivers. Commands set robot actuator targets or tank pump flow rates; simulation advances through explicit integration steps.
