## 输出量推导

### 前轮角速度

记

$$
\lambda:=\dfrac{W}{2L}.
$$

由 Ackermann 几何关系，左右前轮转角以及左右后轮角速度分别满足

$$
\tan\delta_L(t)
=\dfrac{\tan\delta(t)}{1-\lambda\tan\delta(t)},
\qquad
\tan\delta_R(t)
=\dfrac{\tan\delta(t)}{1+\lambda\tan\delta(t)},
$$

$$
\Omega_L(t)=\Omega(t)\left[1-\lambda\tan\delta(t)\right],
\qquad
\Omega_R(t)=\Omega(t)\left[1+\lambda\tan\delta(t)\right].
$$

前轮沿其滚动方向的线速度在车身纵向上的投影，应等于同侧后轮的线速度，因此

$$
r\varpi_L(t)\cos\delta_L(t)=r\Omega_L(t),
\qquad
r\varpi_R(t)\cos\delta_R(t)=r\Omega_R(t).
$$

在正常转向范围

$$
\left|\lambda\tan\delta(t)\right|<1,
\qquad
|\delta_L(t)|,|\delta_R(t)|<\dfrac{\pi}{2}
$$

内，各相关分母和余弦均为正。利用

$$
\dfrac{1}{\cos\alpha}=\sqrt{1+\tan^2\alpha},
\qquad |\alpha|<\dfrac{\pi}{2},
$$

可得左前轮角速度

$$
\begin{aligned}
\varpi_L(t)
&=\Omega(t)\left[1-\lambda\tan\delta(t)\right]
\sqrt{1+
\left[
\dfrac{\tan\delta(t)}{1-\lambda\tan\delta(t)}
\right]^2}\\
&=\Omega(t)\sqrt{
\left[1-\lambda\tan\delta(t)\right]^2
+\tan^2\delta(t)}\\
&=\Omega(t)\sqrt{
1-2\lambda\tan\delta(t)
+\left(1+\lambda^2\right)\tan^2\delta(t)}.
\end{aligned}
$$

同理，右前轮角速度为

$$
\varpi_R(t)=\Omega(t)\sqrt{
1+2\lambda\tan\delta(t)
+\left(1+\lambda^2\right)\tan^2\delta(t)}.
$$

这两个表达式就是主文档输出映射 $\psi=h(z)$ 中最后两个分量的来源。

## 约束推导

### 前轮转角约束

以左转，即 $\delta(t)\ge0$ 为例，左前轮是转角绝对值较大的内侧车轮。要求

$$
\tan\delta_L(t)
=\dfrac{\tan\delta(t)}{1-\lambda\tan\delta(t)}
\le\tan\delta_m,
$$

整理得

$$
\tan\delta(t)
\le\dfrac{\tan\delta_m}{1+\lambda\tan\delta_m}.
$$

右转情形由对称性得到相同的绝对值限制，因而

$$
|\delta(t)|\le\bar\delta,
\qquad
\bar\delta
:=\arctan\left(
\dfrac{2L\tan\delta_m}{2L+W\tan\delta_m}
\right).
$$

### 轮转速约束

将物理车轮转速限制

$$
|\varpi_L(t)|\le\Omega_m,
\qquad
|\varpi_R(t)|\le\Omega_m
$$

直接应用于上述前轮角速度输出，可得

$$
\Omega^2(t)\left[
1-2\lambda\tan\delta(t)
+\left(1+\lambda^2\right)\tan^2\delta(t)
\right]\le\Omega_m^2,
$$

$$
\Omega^2(t)\left[
1+2\lambda\tan\delta(t)
+\left(1+\lambda^2\right)\tan^2\delta(t)
\right]\le\Omega_m^2.
$$

同时满足左右轮约束，等价于

$$
\underbrace{\Omega^2(t)\left[
1+2\lambda\left|\tan\delta(t)\right|
+\left(1+\lambda^2\right)\tan^2\delta(t)
\right]}_{\phi(\Omega(t),\delta(t))}
\le\Omega_m^2.
$$

上式是严格的 Ackermann 非线性不光滑约束。$\delta(t)=0$ 时，虚拟轮速 $\Omega(t)$ 具有最宽松的可行范围。

进一步利用

$$
|\delta(t)|\le\bar\delta
\quad\Longrightarrow\quad
|\tan\delta(t)|\le\tan\bar\delta,
$$

可以得到与转向状态解耦的保守约束

$$
|\Omega(t)|\le\dfrac{\Omega_m}{\sqrt{\gamma}},
$$

其中

$$
\gamma
:=1+2\lambda\tan\bar\delta
+\left(1+\lambda^2\right)\tan^2\bar\delta.
$$

为减少保守性，还可以进一步优化线性约束的形式：

- （待定）两个约束情况（三角形）
- （待定）通用情况：任意给定约束数量（$n$ 个约束对应 $n+1$ 边形），用最小二乘或泛函等方式
