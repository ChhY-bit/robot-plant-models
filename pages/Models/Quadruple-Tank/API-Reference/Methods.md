# Quadruple-Tank Methods

> **Tips:** Sections with `'*'` describe private methods.

## 1. Initialization {#1-initialization}

### `rpm.quadruple_tank(Params, Ini_States)` {#rpm-quadruple-tank}

Create a new `handle` object with independent physical parameters and water levels. Pump inputs and disturbances start at zero. Omitted or `[]` arguments use the bundled YAML parameters and four zero levels, respectively. Construction does not advance time.

- **Argument:**
    - `Params` (optional): scalar structure containing all 11 [physical parameter fields](Properties.md#2-physical-parameters), or `[]`. Areas and `g` must be positive finite real numeric scalars; valve ratios must be finite real numeric scalars in `[0, 1]`.
    - `Ini_States` (optional): four-element finite, real, nonnegative numeric row or column vector, or `[]`; ordered `[x1; x2; x3; x4]` in m and normalized to `4x1 double`.
- **Return:** `obj`, an `rpm.quadruple_tank` handle object.
- **see also:** [parameter loader](Utils.md#rpm-utils-load-quadruple-tank-params), [water levels](Properties.md#1-water-levels).
- **Usage:**

    ```matlab
    tank = rpm.quadruple_tank();
    params = rpm.utils.load_quadruple_tank_params();
    params.gamma_1 = 0.3;
    tank = rpm.quadruple_tank(params, [0.1, 0.1, 0.1, 0.1]);
    ```

Missing required fields raise `quadruple_tank:MissingParameter`; invalid shapes, types, and ranges are rejected by MATLAB attribute validation. Physical values are mapped from YAML names to private property names. The class does not provide `reset()`; construct a new object to restart.

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

This method does not integrate the model. Inputs are volumetric flow rates, with no pump voltage conversion, upper saturation, or first-order actuator response.

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
    - `dt`: intended to be a positive finite real scalar integration interval, in s.
    - `t`: intended to be a finite real scalar start time, in s. Both `dt` and `t` are required; there is no default time argument.
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

The current implementation does not validate `dt` or `t`. It does not store or increment a simulation clock. Stage times are passed to `stateDerivative`, but the current derivative does not use time explicitly.

Water levels supplied to each derivative evaluation are clipped at zero before square roots are evaluated. The final integrated levels are also clipped at zero. This prevents negative-level square roots for valid physical inputs, but clipping does not guarantee accuracy or exact volume conservation near empty tanks. Reduce the step size as needed. No adaptive step size, upper capacity limit, or overflow model is implemented.

## 6.* Internal Methods {#6-internal-methods}

### `validateParams(Params)` {#validateparamsparams}

Require a scalar structure and all 11 physical fields, validate their scalar types and ranges, and normalize required values to `double`. Called by the constructor even when a manually built structure is supplied. This private helper does not load files or change an existing object's parameters.

### `stateDerivative(z, u, t)` {#statederivativez-u-t}

Calculate a `4x1` water-level derivative in `m/s` from `z = [x1; x2; x3; x4]`, `u = [u1; u2]`, physical parameters, and the held disturbance. It clips `z` at zero for flow evaluation, adds the disturbance to the result, and does not modify the stored water levels. The `t` argument is currently unused. See the [state equations](../Modeling/quadruple-tank-model.md#2-state-equations).
