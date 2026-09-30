## 约束推导

- 前轮转角

- 转速

$$
\left|\dfrac{\Omega_L(t)}{\cos\delta_L(t)}\right| \le \Omega_m,
$$

即

$$
\Omega_L^2(t) \le \dfrac{\Omega_m^2}{1+\tan^2 \delta_L(t)}.
$$

同理：

$$
\Omega_R^2(t) \le \dfrac{\Omega_m^2}{1+\tan^2 \delta_R(t)}.
$$

将

$$
\Omega_L(t)=\Omega(t) \cdot \dfrac{2L-W\tan\delta(t)}{2L},
\qquad
\Omega_R(t)=\Omega(t) \cdot \dfrac{2L+W\tan\delta(t)}{2L},
$$

以及

$$
\tan\delta_L(t)=\dfrac{2L\tan\delta(t)}{2L-W\tan\delta(t)},
\qquad
\tan\delta_R(t)=\dfrac{2L\tan\delta(t)}{2L+W\tan\delta(t)}
$$

代入上述左右轮转速约束，可得

$$
\begin{cases}
\Omega^2(t) \le \dfrac{4L^2\Omega_m^2}{\left[2L-W\tan\delta(t)\right]^2+\left[2L\tan \delta(t)\right]^2}, \\
\Omega^2(t) \le \dfrac{4L^2\Omega_m^2}{\left[2L+W\tan\delta(t)\right]^2+\left[2L\tan \delta(t)\right]^2}.
\end{cases}
$$

分析 $\delta(t)$ 的正负性并整理得

$$
\Omega^2(t) \le \dfrac{4L^2\Omega_m^2}{\left(2L+W\left|\tan\delta(t)\right|\right)^2+\left(2L\tan \delta(t)\right)^2}.
$$

将分母展开并约去 $4L^2$，可进一步化简为

$$
\Omega^2(t)\left[
1+\dfrac{W}{L}\left|\tan\delta(t)\right|
+\left(1+\dfrac{W^2}{4L^2}\right)\tan^2\delta(t)
\right]\le \Omega_m^2.
$$

记 $\lambda:=\dfrac{W}{2L}$，进一步化简为

$$
\underbrace{\Omega^2(t)\left[
1+2\lambda\left|\tan\delta(t)\right|
+\left(1+\lambda^2\right)\tan^2\delta(t)
\right]}_{\phi(\Omega(t),\delta(t))}\le \Omega_m^2.
$$

上式即为严格的 Ackermann 非线性不光滑约束条件。不难得知，$\delta(t) = 0$ 时 $\Omega(t)$ 具有最宽松的取值范围。

考虑到已经对虚拟转角作出约束 $\left| \delta(t) \right| \le \bar{\delta}$，进而有

$$
\left|\tan \delta(t)\right| \le \tan \bar{\delta},
$$

为得到与 $\delta(t)$ 解耦且易于处理的约束，可采用以下更严格的充分条件，即保守的线性约束

$$
\left|\Omega(t)\right| \le \dfrac{\Omega_m}{\sqrt{\gamma}},
$$

其中

$$
\gamma := 1+2\lambda\tan \bar{\delta}
+\left(1+\lambda^2\right)\tan^2 \bar{\delta}.
$$

为减少保守性，还可以进一步优化线性约束的形式：
- （待定）两个约束情况（三角形）
- （待定）通用情况：任意给定约束数量（$n$ 个约束对应 $n+1$ 边形），用最小二乘或泛函等方式