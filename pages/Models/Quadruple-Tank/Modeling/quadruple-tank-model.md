# Quadruple-Tank Model

This page describes the continuous equations and numerical implementation of `rpm.quadruple_tank`. Symbols correspond to the [physical properties](../API-Reference/Properties.md#2-physical-parameters).

## 1. Flow Connections {#1-flow-connections}

The four tanks have constant cross-sectional areas. Each outlet follows the gravity-driven law below; final levels are clipped between zero and tank height without explicitly calculating overflow rates.

| Source | Destination | Volumetric flow rate |
| --- | --- | --- |
| Pump 1 | Tank 1 | `gamma_1 * u1` |
| Pump 1 | Tank 4 | `(1-gamma_1) * u1` |
| Pump 2 | Tank 2 | `gamma_2 * u2` |
| Pump 2 | Tank 3 | `(1-gamma_2) * u2` |
| Tank 3 outlet | Tank 1 | `q3` |
| Tank 4 outlet | Tank 2 | `q4` |
| Tank 1 / tank 2 outlet | Outside the system | `q1` / `q2` |

Here `u1` and `u2` are nonnegative pump flow rates in `m^3/s`; the dimensionless valve ratios lie in `[0, 1]`.

## 2. State Equations {#2-state-equations}

For tank index $i$, outlet area $a_i$, level $x_i$, and gravity $g$, the outlet flow is

$$
q_i = a_i\sqrt{2gx_i},\qquad i=1,2,3,4.
$$

Mass balance gives the water-level dynamics, including the held disturbance $d$:

$$
\begin{aligned}
\dot{x}_1 &= \frac{-q_1+q_3+\gamma_1u_1}{A_1}+d_1,\\
\dot{x}_2 &= \frac{-q_2+q_4+\gamma_2u_2}{A_2}+d_2,\\
\dot{x}_3 &= \frac{-q_3+(1-\gamma_2)u_2}{A_3}+d_3,\\
\dot{x}_4 &= \frac{-q_4+(1-\gamma_1)u_1}{A_4}+d_4.
\end{aligned}
$$

The state order is $[x_1,x_2,x_3,x_4]^\mathsf{T}$, and the usual measured output is $[x_1,x_2]^\mathsf{T}$. The object exposes all four levels directly. Disturbance components are water-level rates in `m/s`; they are added after the flow-to-height conversion and are not divided by area.

For the continuous equations, total volume satisfies the following balance. Internal flows from tanks 3 and 4 cancel:

$$
\frac{d}{dt}\sum_{i=1}^{4} A_i x_i
= u_1+u_2-q_1-q_2+\sum_{i=1}^{4}A_i d_i.
$$

## 3. Numerical Integration {#3-numerical-integration}

[step(dt, t)](../API-Reference/Methods.md#stepdt-t) uses classical RK4. Pump inputs, valve ratios, and the disturbance are held throughout each step. The derivative evaluates outlet flows using nonnegative levels, equivalent to replacing each square-root argument's level with `max(x_i, 0)`. The final integrated state is also clipped componentwise at zero.

This clipping keeps stored levels nonnegative for valid physical inputs, but it can alter the discrete volume balance and integration accuracy near an empty tank. It is not an adaptive or event-based draining solver. Select a sufficiently small positive step size and check sensitivity to smaller steps for the intended operating conditions. A negative disturbance at zero level cannot make the stored level negative because of the final clipping.

The time argument is passed to the RK4 stages but is not currently used by the state equations. Time-varying commands or disturbances are supplied by updating the held values between steps. The class does not provide a linearization or transfer-function API.

Construction and `reset()` reject initial levels outside `[0, corresponding tank height]`. `send()` rejects negative flows and caps flows at `PumpMaxFlow_1/2`. `step()` requires finite real scalars `dt > 0` and `t`. Upper clipping can be interpreted as removing excess water without tracking its destination. The volume identity above describes the unclipped continuous equations and excludes water removed by discrete clipping.
