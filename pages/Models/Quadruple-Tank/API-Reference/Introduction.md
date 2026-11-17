# Introduction

`rpm.quadruple_tank` is a MATLAB `handle` class for simulating four interconnected water tanks. Two pump flow rates feed the tanks through adjustable splitting valves. The model integrates four water levels using mass balance and gravity-driven outlet flows, with optional additive water-level-rate disturbances.

The state order is `[x1; x2; x3; x4]`, in metres. Pump inputs are volumetric flow rates in `m^3/s`; disturbances are in `m/s`. Tanks 3 and 4 drain into tanks 1 and 2, respectively. The usual measured output is `[x1; x2]`, and all four levels are publicly readable. Assigning the object to another variable shares the same instance.

## 1. API Organization

- [Properties](Properties.md): water levels, the parameter structure, held pump inputs, valve ratios, and disturbances.
- [Methods](Methods.md): construction, reset, pump commands, valve settings, disturbance settings, and integration.
- [Utils](Utils.md): YAML parameter loading, validation, and template export.
- [Modeling](../Modeling/quadruple-tank-model.md): tank connections, state equations, and numerical boundary handling.

## 2. Basic Usage

Put the project root (the parent of `+rpm/`) on the MATLAB search path. Do not add `+rpm/` or its subdirectories separately. Create a tank system, set its pump inputs, call `step(dt, t)`, and read the water-level properties. Both time arguments are required. Pump inputs, valve settings, and disturbances remain in effect until replaced; setting them alone does not advance the simulation.

```matlab
tank = rpm.quadruple_tank();
tank.send(1e-5, 1e-5); % Pump flow rates [m^3/s]
dt = 0.01;
for k = 1:1000
    tank.step(dt, (k - 1) * dt);
end
levels = [tank.x1; tank.x2; tank.x3; tank.x4];
output = levels(1:2); % Lower-tank measurements [m]
```

Choose a step size appropriate to the parameters and input changes, particularly near empty tanks. The implementation clips final levels to `[0, corresponding tank height]` and caps pump inputs at their maximum flows.

## 3. Optional Namespace Import

The class belongs to `rpm`; parameter helpers belong to `rpm.utils`. Import each namespace where short names are needed:

```matlab
import rpm.*
import rpm.utils.*
params = load_quadruple_tank_params();
tank = quadruple_tank(params, [0.1; 0.1; 0.1; 0.1]);
tank.step(0.01, 0);
```

Imports apply only to the scope where they are declared. The current class exposes water levels directly; it has no `getStates()` or `getParams()` method. Use `reset()` or `reset(Ini_States)` to reset levels and clear inputs and disturbances while preserving current valve ratios. Construct a new object to change fixed parameters.
