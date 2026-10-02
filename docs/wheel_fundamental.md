## 驱动

- 正运动：$$ \begin{bmatrix} v \\ \\ \omega \end{bmatrix}  = \begin{bmatrix} \dfrac{v_L + v_R}{2}  \\ \\ \dfrac{v_R - v_L}{L} \end{bmatrix} = \begin{bmatrix} \dfrac{1}{2} & \dfrac{1}{2} \\ \\ -\dfrac{1}{L} & \dfrac{1}{L} \end{bmatrix} \begin{bmatrix} v_L \\ \\ v_R \end{bmatrix}$$

- 逆运动： $$ \begin{bmatrix} v_L \\ \\ v_R \end{bmatrix} = \begin{bmatrix} 1 & -\dfrac{L}{2} \\ \\ 1 & \dfrac{L}{2} \end{bmatrix} \begin{bmatrix} v \\ \\ \omega \end{bmatrix} = \begin{bmatrix} v - \dfrac{\omega L}{2} \\ \\ v + \dfrac{\omega L}{2} \end{bmatrix}$$

- 进一步考虑轮胎半径：$$v_L = r_L \Omega_L, \quad v_R = r_R \Omega_R,$$ 其中， $\Omega_L,\Omega_R,r_L,r_R$ 分别为左右轮转速、半径。进而有： $$ \begin{bmatrix} v \\ \\ \omega \end{bmatrix} = \underbrace{\begin{bmatrix} \dfrac{r_L}{2} & \dfrac{r_R}{2} \\ \\ -\dfrac{r_L}{L} & \dfrac{r_R}{L} \end{bmatrix}}_{\text{正运动矩阵 } M_r} \begin{bmatrix} \Omega_L \\ \\ \Omega_R \end{bmatrix}, \qquad \begin{bmatrix} \Omega_L \\ \\ \Omega_R \end{bmatrix} = \underbrace{\begin{bmatrix} \dfrac{1}{r_L} & -\dfrac{L}{2 r_L} \\ \\ \dfrac{1}{r_R} & \dfrac{L}{2 r_R} \end{bmatrix}}_{\text{逆运动矩阵 } M_r^{-1}} \begin{bmatrix} v \\ \\ \omega \end{bmatrix} = \begin{bmatrix} \dfrac{v - \omega L/2}{r_L} \\ \\ \dfrac{v + \omega L/2}{r_R} \end{bmatrix}$$

- 电机暂态：$$\dot{\Omega}_L = \dfrac{1}{T_{L}} \left(\Omega_{L,\text{cmd}} - \Omega_L \right), \quad \dot{\Omega}_R = \dfrac{1}{T_{R}} \left(\Omega_{R,\text{cmd}} - \Omega_R \right)$$ 其中， $T_L,T_R$ 分别为左右电机时间常数，$\Omega_{L,\text{cmd}},\Omega_{R,\text{cmd}}$ 为左右轮指令转速。

## 运动

无漂移仿射控制系统: $$ \underbrace{\begin{bmatrix} \dot{x}(t) \\ \dot{y}(t) \\ \dot{\theta}(t) \end{bmatrix}}_{\dot{\xi}(t)} = \underbrace{\begin{bmatrix} \cos \theta(t) & 0 \\ \sin \theta(t) & 0 \\ 0 & 1 \end{bmatrix}}_{g(\xi(t))} \underbrace{\begin{bmatrix} v(t) \\ \omega(t) \end{bmatrix}}_{u(t)}. $$ 将 $u(t) = M_r \Omega(t)$ 代入，其中 $\Omega(t) = \begin{bmatrix} \Omega_L(t) & \Omega_R(t) \end{bmatrix}^T$，可得以轮转速为输入的完整展开形式： $$ \dot{\xi}(t) = \underbrace{g(\xi(t))\, M_r}_{G(\xi(t))_{3\times 2}} \begin{bmatrix} \Omega_L(t) \\ \\ \Omega_R(t) \end{bmatrix} = \begin{bmatrix} \dfrac{r_L \cos \theta}{2} & \dfrac{r_R \cos \theta}{2} \\ \\ \dfrac{r_L \sin \theta}{2} & \dfrac{r_R \sin \theta}{2} \\ \\ -\dfrac{r_L}{L} & \dfrac{r_R}{L} \end{bmatrix} \begin{bmatrix} \Omega_L(t) \\ \\ \Omega_R(t) \end{bmatrix}$$

# 综合动态

定义状态向量与轮速指令向量：

$$
z = \begin{bmatrix}
x & y & \theta & \alpha_L & \Omega_L & \alpha_R & \Omega_R
\end{bmatrix}^{T},
\qquad
c = \begin{bmatrix}
\Omega_{L,\mathrm{cmd}} \\
\Omega_{R,\mathrm{cmd}}
\end{bmatrix}.
$$

综合动态方程为：

$$
\dot z = f(z,c) =
\begin{bmatrix}
\dfrac{r_L\Omega_L+r_R\Omega_R}{2}\cos\theta \\[6pt]
\dfrac{r_L\Omega_L+r_R\Omega_R}{2}\sin\theta \\[6pt]
\dfrac{r_R\Omega_R-r_L\Omega_L}{L} \\[6pt]
\Omega_L \\[4pt]
\dfrac{\Omega_{L,\mathrm{cmd}}-\Omega_L}{T_L} \\[6pt]
\Omega_R \\[4pt]
\dfrac{\Omega_{R,\mathrm{cmd}}-\Omega_R}{T_R}
\end{bmatrix}.
$$
