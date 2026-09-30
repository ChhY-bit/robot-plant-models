## 运动

- 结构：前轮转向，后轮驱动

- 有效滚动半径（轮速到线速度的换算系数）为 $r\,[\text{m/rad}]$；前后轮轴距为 $L$，左右轮间距为 $W$

- 定义车辆轨迹的带符号曲率为 $\kappa$，左转为正、右转为负；当 $\kappa\ne0$ 时，带符号转弯半径为 $R=1/\kappa$。纯滚动、不侧滑时，左右前轮满足几何约束： $$ \tan \delta_L = \dfrac{L\kappa}{1-W\kappa/2},\qquad \tan \delta_R = \dfrac{L\kappa}{1+W\kappa/2}. $$ 引入位于前轮轴中点的虚拟车轮，其转角记为 $\delta$，则有 $$ \kappa(t)=\dfrac{\tan\delta(t)}{L}. $$ 因而任意时刻前轮转角： $$\delta_{L}(t)=\arctan\left(\dfrac{L\kappa(t)}{1-W\kappa(t)/2}\right),\qquad \delta_{R}(t)=\arctan\left(\dfrac{L\kappa(t)}{1+W\kappa(t)/2}\right).$$ 在非零转角下，左右轮转角与虚拟转角之间还满足 $$\dfrac{1}{\tan \delta(t)} = \dfrac{1}{2}\left( \dfrac{1}{\tan \delta_L(t)} + \dfrac{1}{\tan\delta_R(t)} \right);$$ 直行时三者均为零，可按连续极限理解。以上表达式取通常的转向范围 $|\delta_L|,|\delta_R|<\pi/2$，并假设 $|W\kappa/2|<1$。

- 当后轮轴中点处的带符号纵向速度为 $v$ 时，左右后轮的线速度分别为 $$ v_L(t) = v(t)\left(1-\dfrac{W\kappa(t)}{2}\right),\qquad v_R(t) = v(t)\left(1+\dfrac{W\kappa(t)}{2}\right). $$ 定义虚拟轮角速度为左右后轮角速度的平均值 $$\Omega(t):=\dfrac{\Omega_L(t)+\Omega_R(t)}{2},$$ 则 $$v(t)=r\Omega(t),\qquad \Omega_L(t)=\Omega(t)\left(1-\dfrac{W\kappa(t)}{2}\right),\qquad \Omega_R(t)=\Omega(t)\left(1+\dfrac{W\kappa(t)}{2}\right).$$

## 驱动

- 虚拟转向角 (Virtual Steering Angle) ： $[\text{rad}]$ $$ \dot{\delta}(t) = \dfrac{1}{T_{\delta}}\left[ \delta_{c}(t) - \delta(t) \right].$$

- 虚拟轮速 (Virtual Wheel Speed)：$[\text{rad/s}]$ $$ \dot{\Omega}(t) = \dfrac{1}{T_{\Omega}}\left[ \Omega_c(t) - \Omega(t)\right]. $$

## 控制

- 车辆的转动角速度为 $$\dot{\theta}=v\kappa=\dfrac{v\tan \delta}{L}.$$ 平动速度为 $$\dot{x} = v\cos{\theta},\quad \dot{y} = v \sin{\theta}.$$

- 给定控制指令 $u := \left[\delta_c,\Omega_c\right]^\top$ 后，有关物理量如下（若上层给出速度指令 $v_c$，则令 $\Omega_c=v_c/r$）：
  1. 指令曲率（左转为正、右转为负）： $$ \kappa_c=\dfrac{\tan\delta_c}{L}. $$
  2. 左右轮转角最终期望值： $$\delta_{L}^*=\arctan\left(\dfrac{L\kappa_c}{1-W\kappa_c/2}\right),\qquad \delta_{R}^*=\arctan\left(\dfrac{L\kappa_c}{1+W\kappa_c/2}\right).$$

## 工作机制

1. 指令接收： $\delta_c, \Omega_c$
2. 虚拟转角 $\delta(t)$ 与虚拟轮速 $\Omega(t)$ 惯性运行
3. 左右前轮转角 $\delta_L(t),\delta_R(t)$、左右后轮角速度 $\Omega_L(t),\Omega_R(t)$ 以及左右前轮角速度 $\varpi_L(t),\varpi_R(t)$ 由当前虚拟状态实时计算
4. 实际位姿 $x(t),y(t),\theta(t)$ 更新

## 综合动态

定义动态状态

$$
z(t) :=
\left[x(t),y(t),\theta(t),\delta(t),\Omega(t)\right]^\top,
$$

控制

$$
u(t):=\left[
\delta_c(t), \Omega_c(t)
\right]^\top,
$$

和输出

$$
\psi(t):=\left[
\delta_L(t),\delta_R(t),\Omega_L(t),\Omega_R(t),\varpi_L(t),\varpi_R(t)
\right]^\top,
$$

其中 $\varpi_L(t),\varpi_R(t)$ 分别表示左右前轮角速度。假设四个车轮具有相同的有效滚动半径 $r$，由前轮速度在车身纵向的投影可得

$$
r\varpi_L\cos\delta_L=r\Omega_L,
\qquad
r\varpi_R\cos\delta_R=r\Omega_R,
$$

因此

$$
\varpi_L=\dfrac{\Omega_L}{\cos\delta_L},
\qquad
\varpi_R=\dfrac{\Omega_R}{\cos\delta_R}.
$$

进一步有状态方程：

$$
\dot{z} = \begin{bmatrix}
r z_5\cos z_3 \\
r z_5\sin z_3 \\
\dfrac{r z_5}{L}\tan z_4 \\
\dfrac{u_1-z_4}{T_\delta} \\
\dfrac{u_2-z_5}{T_\Omega}
\end{bmatrix}.
$$

输出中的左右前轮转角、左右后轮角速度及左右前轮角速度不是独立动态状态，而是由 $z_4$、$z_5$ 决定的代数量。令

$$
\kappa(z):=\dfrac{\tan z_4}{L},
$$

则输出方程为

$$
\psi=h(z):=
\begin{bmatrix}
\displaystyle \arctan\left(\dfrac{L\kappa(z)}{1-W\kappa(z)/2}\right)\\[6pt]
\displaystyle \arctan\left(\dfrac{L\kappa(z)}{1+W\kappa(z)/2}\right)\\[6pt]
\displaystyle z_5\left(1-\dfrac{W\kappa(z)}{2}\right)\\[6pt]
\displaystyle z_5\left(1+\dfrac{W\kappa(z)}{2}\right)\\[6pt]
\displaystyle \dfrac{z_5\left(1-W\kappa(z)/2\right)}{\cos\delta_L}\\[10pt]
\displaystyle \dfrac{z_5\left(1+W\kappa(z)/2\right)}{\cos\delta_R}
\end{bmatrix}.
$$

## 约束

- 针对物理机构，一般有约束
  1. 前轮转角 $$ \left|\delta_L\right|,\left| \delta_R \right| \le \delta_m, \quad 0<\delta_m<\dfrac{\pi}{2}. $$ 或转化为适合控制决策的形式： $$ \left| \delta(t) \right| \le \bar{\delta}, \quad \bar{\delta}:=\arctan\left(\dfrac{2L\tan\delta_m}{2L+W\tan\delta_m}\right). $$
  2. 轮转速（必定有 $|\varpi_{L,R}| \ge |\Omega_{L,R}|$ ） $$ \left| \varpi_L \right|,\left| \varpi_R \right| < \Omega_m, \quad \Omega_m > 0. $$ 或转化为适合控制决策的形式：$$\left|\Omega(t)\right| \le \bar{\Omega},\quad \bar{\Omega}:=\dfrac{\Omega_m \cos \delta_m}{1+W/(2R)}???.$$
