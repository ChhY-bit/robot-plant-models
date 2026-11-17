# Quadruple-Tank Methods

> **Tips:** Sections with `'*'` describe private methods.

## 1. Initialization {#1-initialization}

### `rpm.quadruple_tank(Params, Ini_States)` {#rpm-quadruple-tank}

Create a new `handle` object with independent physical parameters and water levels. Pump inputs and disturbances start at zero. Omitted or `[]` arguments use the bundled YAML parameters and four zero levels, respectively. Construction does not advance time.

- **Argument:**
    - `Params` (optional): scalar structure containing all 19 [physical parameter fields](Properties.md#2-physical-parameters), or `[]`. All fields except valve ratios must be positive finite real numeric scalars; valve ratios must be finite real numeric scalars in `[0, 1]`.
    - `Ini_States` (optional): four-element finite, real, nonnegative numeric row or column vector, or `[]`; ordered `[x1; x2; x3; x4]` in m and normalized to `4x1 double`. Each level must not exceed its `TankHeight`; equality is allowed.
- **Return:** `obj`, an `rpm.quadruple_tank` handle object.
- **see also:** [parameter loader](Utils.md#rpm-utils-load-quadruple-tank-params), [water levels](Properties.md#1-water-levels).
- **Usage:**

    ```matlab
    tank = rpm.quadruple_tank();
    params = rpm.utils.load_quadruple_tank_params();
    params.gamma_1 = 0.3;
    tank = rpm.quadruple_tank(params, [0.1, 0.1, 0.1, 0.1]);
    ```

Missing required fields raise `quadruple_tank:MissingParameter`; invalid shapes, types, and ranges are rejected by MATLAB attribute validation. Parameters are stored in private `Params` with YAML field names preserved. Initial levels above tank height raise `quadruple_tank:InvalidInitialState`. Use `reset()` to restart.

### `reset(Ini_States)` {#resetini_states}

Reset levels and clear held pump inputs and disturbances, preserving `Params`, including current valve ratios.

- **Argument:** `Ini_States` (optional): four-element finite real numeric row or column vector, ordered `[x1; x2; x3; x4]`, in m. Omitted or `[]` means zero levels. Each level must lie in `[0, corresponding tank height]`, including endpoints; invalid levels are rejected rather than clipped.
- **Return:** none.
- **Behavior:** Shares `validateInitialStates()` with construction. The object is updated only after validation; rejected input preserves existing levels, inputs, and disturbances.
- **Usage:**

```matlab
tank.reset([0.1; 0.2; 0.3; 0.4]);
tank.reset();
```

## 2. Pump Inputs {#2-pump-inputs}

### `send(u1, u2)` {#sendu1-u2}

Replace the two held pump flow rates. The values remain active across subsequent integration steps. Both inputs are checked before either property is updated, so a rejected call preserves the previous inputs.

- **Argument:** `u1`, `u2`: finite, real, nonnegative numeric scalars, in `m^3/s`; stored as `double`.
- **Return:** none.
- **see also:** [pump inputs](Properties.md#3-pump-inputs), [integration](#stepdt-t).
- **Usage:**

    ```matlab
    tank.send(1e-5, 2e-5);
    tank.step(0.01, 0);
    tank.send(0, 0); % Stop both pumps; existing water can still drain
    ```

This method calls `validateAndLimitInput()` to validate and normalize inputs to double. Negative flows are rejected; inputs above `PumpMaxFlow_1/2` are capped at their respective maxima. It does not integrate the model and includes no pump voltage conversion or first-order actuator response.

## 3. Valve Settings {#3-valve-settings}

### `setValve(gamma_1, gamma_2)` {#setvalvegamma_1-gamma_2}

Replace the valve split ratios used in subsequent steps. Both values are validated before either is updated; water levels and pump inputs are preserved.

- **Argument:** `gamma_1`, `gamma_2`: finite real numeric scalars in `[0, 1]`, including endpoints; stored as `double`.
- **Return:** none.
- **see also:** [physical parameters](Properties.md#2-physical-parameters), [flow connections](../Modeling/quadruple-tank-model.md#1-flow-connections).
- **Usage:**

    ```matlab
    tank.setValve(0.3, 0.7);
    tank.setValve(1, 1); % Both pumps feed only their lower tanks
    ```

`gamma_1` directs pump 1 to tank 1, with the remainder going to tank 4. `gamma_2` directs pump 2 to tank 2, with the remainder going to tank 3. Setting a ratio does not immediately change a water level.

## 4. Disturbance {#4-disturbance}

### `addDisturbance(d)` {#adddisturbanced}

Set the held additive water-level-rate disturbance. Despite the method name, each call **replaces** the vector rather than adding it to the previously stored value. It remains active until replaced.

- **Argument:** `d`: four-element finite real numeric row or column vector, ordered `[d1; d2; d3; d4]`, in `m/s`; normalized to `4x1 double`. Either sign and zero are accepted.
- **Return:** none.
- **see also:** [disturbance property](Properties.md#4-disturbance), [state equations](../Modeling/quadruple-tank-model.md#2-state-equations).
- **Usage:**

    ```matlab
    tank.addDisturbance([1e-4, -1e-4, 0, 0]);
    tank.step(0.01, 0);
    tank.addDisturbance(zeros(4, 1)); % Cancel the disturbance
    ```

The vector is added directly to `dz` without division by area. It is constant within a step, including all RK4 stages. For a piecewise-constant disturbance, call this method with the new value before each affected step. A rejected call preserves the existing disturbance.

## 5. Integration {#5-integration}

### `step(dt, t)` {#stepdt-t}

Advance the four water levels by one classical fourth-order Runge–Kutta (RK4) step using the held pump inputs, current valve settings, and held disturbance. The method updates the object without returning a state vector; read `tank.x1` through `tank.x4` afterwards.

- **Argument:**
    - `dt`: must be a positive finite real numeric scalar integration interval, in s.
    - `t`: must be a finite real numeric scalar start time, in s. Both `dt` and `t` are required; there is no default time argument.
- **Return:** none.
- **see also:** [water levels](Properties.md#1-water-levels), [boundary handling](../Modeling/quadruple-tank-model.md#3-numerical-integration).
- **Usage:**

    ```matlab
    dt = 0.01;
    for k = 1:1000
        tank.step(dt, (k - 1) * dt);
    end
    levels = [tank.x1; tank.x2; tank.x3; tank.x4];
    ```

`validateStepArguments()` checks `dt` and `t` before integration and normalizes both to double. Rejected arguments leave levels unchanged. The object does not store or increment a simulation clock. Stage times are passed to `stateDerivative`, but the current derivative does not use time explicitly.

Water levels supplied to each derivative evaluation are clipped at zero before square roots are evaluated. Final levels are clipped by `limitStates()` to `[0, corresponding tank height]`; RK4 intermediate stages may still exceed tank height. This prevents negative-level square roots for valid physical inputs, but clipping does not guarantee accuracy or exact volume conservation near empty tanks. Reduce the step size as needed. No adaptive step size or explicit overflow model is implemented; final upper clipping does not track the destination of excess water.

## 6.* Internal Methods {#6-internal-methods}

### `validateParams(Params)` {#validateparamsparams}

Require a scalar structure and all 19 physical fields, validate their scalar types and ranges, and normalize required values to `double`. Called by the constructor even when a manually built structure is supplied. This private helper does not load files or change an existing object's parameters.

### `stateDerivative(z, u, t)` {#statederivativez-u-t}

Calculate a `4x1` water-level derivative in `m/s` from `z = [x1; x2; x3; x4]`, `u = [u1; u2]`, physical parameters, and the held disturbance. It clips `z` at zero for flow evaluation, adds the disturbance to the result, and does not modify the stored water levels. The `t` argument is currently unused. See the [state equations](../Modeling/quadruple-tank-model.md#2-state-equations).


The following helpers return validated or limited values without modifying object properties.

### `validateStepArguments(dt, t)` {#validatestepargumentsdt-t}

Validate a positive step size and finite real start time, normalizing both to double scalars.

### `validateInitialStates(Ini_States)` {#validateinitialstatesini_states}

Validate four initial levels against their tank heights and normalize to 4x1 double. Construction shares this check through reset.

### `validateAndLimitInput(u1, u2)` {#validateandlimitinputu1-u2}

Validate both finite real nonnegative scalar inputs, then cap them at their maximum flows and normalize to double.

### `validateValve(gamma_1, gamma_2)` {#validatevalvegamma_1-gamma_2}

Validate both ratios in [0, 1] and normalize to double scalars.

### `validateDisturbance(d)` {#validatedisturbanced}

Validate a four-element finite real disturbance of either sign and normalize to 4x1 double.

### `limitStates(States)` {#limitstatesstates}

Clip internal integrated levels elementwise to [0, corresponding tank height]; this is not an initial-state validator.
