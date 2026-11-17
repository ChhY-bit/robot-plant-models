# Quadruple-Tank Properties

> **Tips:** Sections with `'*'` describe private properties. Water levels are publicly readable, with private write access.

## 1. Water Levels {#1-water-levels}

### `x1`, `x2`, `x3`, `x4` {#water-levels}

The current heights of water in tanks 1 through 4. Tanks 1 and 2 are the lower tanks; tank 3 drains into tank 1 and tank 4 drains into tank 2. The state vector used internally during integration is `[x1; x2; x3; x4]`; there is no stored `States` property.

- **type:** Four `double` scalars, in m.
- **default:** `0` for each level.
- **constraints:** The constructor and `reset()` accept four-element finite real numeric row or column vectors. Each level must lie in `[0, corresponding tank height]`, including endpoints; out-of-range values are rejected. Values are normalized to double columns.
- **access:** Read with `tank.x1` through `tank.x4`; external assignment is prohibited. `step()` clips final levels to `[0, corresponding tank height]`; `reset()` assigns new initial levels.
- **see also:** [constructor](Methods.md#rpm-quadruple-tank), [integration](Methods.md#stepdt-t).
- **Usage:**

    ```matlab
    tank = rpm.quadruple_tank([], [0.1; 0.2; 0.3; 0.4]);
    levels = [tank.x1; tank.x2; tank.x3; tank.x4];
    output = [tank.x1; tank.x2];
    ```

## 2.* Physical Parameters {#2-physical-parameters}

The constructor requires the following 19 case-sensitive fields. After validation, the structure is stored in private `Params`, preserving YAML field names. There is no public parameter getter. Extra fields in a directly supplied structure are retained but do not participate in calculations.

| Field | Meaning | Default | Unit | Constraint |
| --- | --- | --- | --- | --- |
| `TankArea_1` | Tank 1 area | `2.8` | m² | Positive scalar |
| `TankArea_2` | Tank 2 area | `3.2` | m² | Positive scalar |
| `TankArea_3` | Tank 3 area | `2.8` | m² | Positive scalar |
| `TankArea_4` | Tank 4 area | `3.2` | m² | Positive scalar |
| `HoleArea_1` | Tank 1 outlet area | `0.71` | m² | Positive scalar |
| `HoleArea_2` | Tank 2 outlet area | `0.57` | m² | Positive scalar |
| `HoleArea_3` | Tank 3 outlet area | `0.71` | m² | Positive scalar |
| `HoleArea_4` | Tank 4 outlet area | `0.57` | m² | Positive scalar |
| `g` | Gravity | `9.81` | m/s² | Positive scalar |
| `gamma_1` | Pump 1 split ratio | `0.5` | — | `[0, 1]` |
| `gamma_2` | Pump 2 split ratio | `0.5` | — | `[0, 1]` |
| `TankHeight_1` | Tank 1 height / level limit | `1.2` | m | Positive scalar |
| `TankHeight_2` | Tank 2 height / level limit | `1.5` | m | Positive scalar |
| `TankHeight_3` | Tank 3 height / level limit | `1.2` | m | Positive scalar |
| `TankHeight_4` | Tank 4 height / level limit | `1.5` | m | Positive scalar |
| `PumpMaxFlow_1` | Pump 1 maximum total flow | `0.05` | m³/s | Positive scalar |
| `PumpMaxFlow_2` | Pump 2 maximum total flow | `0.05` | m³/s | Positive scalar |
| `PumpFlowSpeed_1` | Pump 1 design flow speed | `1.0` | m/s | Positive scalar |
| `PumpFlowSpeed_2` | Pump 2 design flow speed | `1.0` | m/s | Positive scalar |

All required values are finite real numeric scalars normalized to `double`. Defaults come from `+rpm/config/quadruple_tank.yaml`; missing fields are errors, with no individual defaults. Heights bound initial and integrated levels; maximum flows bound inputs. Design flow speeds are average outlet-main-pipe speeds at maximum flow, allowing abstract areas to be derived as `S = Qmax / v`; they do not enter the dynamics.

Pump 1 sends fraction `gamma_1` to tank 1 and fraction `1-gamma_1` to tank 4. Pump 2 sends fraction `gamma_2` to tank 2 and fraction `1-gamma_2` to tank 3. Ratios can be changed after construction through [setValve](Methods.md#setvalvegamma_1-gamma_2). Other physical parameters are fixed for the object's lifetime. Editing the source structure or YAML file does not update an existing object.

```matlab
params = rpm.utils.load_quadruple_tank_params();
params.TankArea_1 = 3.0;
tank = rpm.quadruple_tank(params);
tank.setValve(0.3, 0.7);
```

## 3.* Pump Inputs {#3-pump-inputs}

### `u1`, `u2` {#pump-inputs}

- **type:** Two `double` scalars, in `m^3/s`.
- **default:** Both `0`.
- **constraints:** Finite, real, nonnegative numeric scalar inputs.
- **behavior:** Set with [send](Methods.md#sendu1-u2); both values are held until the next successful call. Inputs are applied directly as flow rates, capped at the corresponding `PumpMaxFlow` without pump actuator dynamics; `reset()` clears both inputs. Both inputs are validated before either property is changed.

## 4.* Disturbance {#4-disturbance}

### `disturbance`

- **type:** `4x1 double`, ordered `[d1; d2; d3; d4]`, in `m/s`.
- **default:** `[0; 0; 0; 0]`.
- **constraints:** Four finite, real numeric elements; positive, negative, and zero values are accepted. Row input is normalized to a column vector.
- **behavior:** [addDisturbance](Methods.md#adddisturbanced) replaces the held vector. It is added directly to the four water-level derivatives in every RK4 stage and remains active until replaced. It is not divided by tank area. Positive values raise a tank's rate of change; negative values lower it. Water-level clipping applies at zero and tank height; `reset()` clears the disturbance.

```matlab
tank.addDisturbance([1e-4; -1e-4; 0; 0]);
tank.addDisturbance(zeros(4, 1)); % Clear the held disturbance
```
