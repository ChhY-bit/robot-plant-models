# Quadruple-Tank Properties

> **Tips:** Sections with `'*'` describe private properties. Water levels are publicly readable, with private write access.

## 1. Water Levels {#1-water-levels}

### `x1`, `x2`, `x3`, `x4` {#water-levels}

The current heights of water in tanks 1 through 4. Tanks 1 and 2 are the lower tanks; tank 3 drains into tank 1 and tank 4 drains into tank 2. The state vector used internally during integration is `[x1; x2; x3; x4]`; there is no stored `States` property.

- **type:** Four `double` scalars, in m.
- **default:** `0` for each level.
- **constraints:** Initial levels must be finite, real, nonnegative numeric values. The constructor accepts a four-element row or column vector and normalizes it to a double column vector before assignment.
- **access:** Read with `tank.x1` through `tank.x4`; direct external assignment is prohibited. `step()` updates the levels and clips the final result at zero. No upper water-level limit is configured.
- **see also:** [constructor](Methods.md#rpm-quadruple-tank), [integration](Methods.md#stepdt-t).
- **Usage:**

    ```matlab
    tank = rpm.quadruple_tank([], [0.1; 0.2; 0.3; 0.4]);
    levels = [tank.x1; tank.x2; tank.x3; tank.x4];
    output = [tank.x1; tank.x2];
    ```

## 2.* Physical Parameters {#2-physical-parameters}

The constructor accepts a scalar `Params` structure with the following 11 case-sensitive fields. It validates them, converts required values to `double`, and maps them to individual private properties. There is no stored `Params` property and no public parameter getter. Extra structure fields are not stored in the object.

| YAML / `Params` field | Private property | Bundled default | Unit | Constraint |
| --- | --- | --- | --- | --- |
| `TankArea_1` | `A1` | `2.8e-3` | m² | Positive scalar |
| `TankArea_2` | `A2` | `3.2e-3` | m² | Positive scalar |
| `TankArea_3` | `A3` | `2.8e-3` | m² | Positive scalar |
| `TankArea_4` | `A4` | `3.2e-3` | m² | Positive scalar |
| `HoleArea_1` | `a1` | `7.1e-6` | m² | Positive scalar |
| `HoleArea_2` | `a2` | `5.7e-6` | m² | Positive scalar |
| `HoleArea_3` | `a3` | `7.1e-6` | m² | Positive scalar |
| `HoleArea_4` | `a4` | `5.7e-6` | m² | Positive scalar |
| `g` | `g` | `9.81` | m/s² | Positive scalar |
| `gamma_1` | `gamma_1` | `0.5` | Dimensionless | Scalar in `[0, 1]` |
| `gamma_2` | `gamma_2` | `0.5` | Dimensionless | Scalar in `[0, 1]` |

All required values must be numeric, real, and finite. `A1` through `A4` are tank cross-sectional areas; `a1` through `a4` are outlet-hole areas. The defaults come from `+rpm/config/quadruple_tank.yaml`. Missing fields are errors; individual fields are not filled from defaults when a custom structure is supplied.

Pump 1 sends fraction `gamma_1` to tank 1 and fraction `1-gamma_1` to tank 4. Pump 2 sends fraction `gamma_2` to tank 2 and fraction `1-gamma_2` to tank 3. Ratios can be changed after construction through [setValve](Methods.md#setvalvegamma_1-gamma_2). Other physical parameters are fixed for the object's lifetime. Editing the source structure or YAML file does not update an existing object.

```matlab
params = rpm.utils.load_quadruple_tank_params();
params.TankArea_1 = 3e-3;
tank = rpm.quadruple_tank(params);
tank.setValve(0.3, 0.7);
```

## 3.* Pump Inputs {#3-pump-inputs}

### `u1`, `u2` {#pump-inputs}

- **type:** Two `double` scalars, in `m^3/s`.
- **default:** Both `0`.
- **constraints:** Finite, real, nonnegative numeric scalar inputs.
- **behavior:** Set with [send](Methods.md#sendu1-u2); both values are held until the next successful call. Inputs are applied directly as flow rates, without pump actuator dynamics or an upper flow limit. Both inputs are validated before either property is changed.

## 4.* Disturbance {#4-disturbance}

### `disturbance`

- **type:** `4x1 double`, ordered `[d1; d2; d3; d4]`, in `m/s`.
- **default:** `[0; 0; 0; 0]`.
- **constraints:** Four finite, real numeric elements; positive, negative, and zero values are accepted. Row input is normalized to a column vector.
- **behavior:** [addDisturbance](Methods.md#adddisturbanced) replaces the held vector. It is added directly to the four water-level derivatives in every RK4 stage and remains active until replaced. It is not divided by tank area. Positive values raise a tank's rate of change; negative values lower it. Water-level clipping still applies at zero.

```matlab
tank.addDisturbance([1e-4; -1e-4; 0; 0]);
tank.addDisturbance(zeros(4, 1)); % Clear the held disturbance
```
