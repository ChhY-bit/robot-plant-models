# 四水箱容器 Quadruple-Tank

## 特性

- 多输入、多输出
- 非本质非线性系统
- 线性化模型的零点可调

## 组成

- 输入：2个水泵进水速率 $u_1,u_2\;\text[m^3/s]$
- 状态：4个容器液位 $x_1,x_2,x_3,x_4\;\text[m]$
- 输出：容器1与2的液位 $y_1,y_2\;\text[m]$

## 模型

根据质量平衡原理与伯努利定律：

$$ \begin{cases}
\dot{x}_1(t) = -\dfrac{a_1}{A_1}\sqrt{2g x_1(t)} + \dfrac{a_3}{A_1}\sqrt{2gx_3(t)} + \dfrac{\gamma_1}{A_1}u_1(t), \\ \\ 

\dot{x}_2(t) = -\dfrac{a_2}{A_2}\sqrt{2g x_2(t)} + \dfrac{a_4}{A_2}\sqrt{2gx_4(t)} + \dfrac{\gamma_2}{A_2}u_2(t), \\ \\

\dot{x}_3(t) = -\dfrac{a_3}{A_3}\sqrt{2g x_3(t)} + \dfrac{1-\gamma_2}{A_3}u_2(t), \\ \\

\dot{x}_4(t) = -\dfrac{a_4}{A_4}\sqrt{2g x_4(t)} + \dfrac{1-\gamma_1}{A_4}u_1(t).
\end{cases}
$$

## 线性化

由 Taylor 级数可知 $f(x) = \sqrt{x}$ 在 $x_0$ 处可近似为 $$ \dfrac{x-x_0}{2\sqrt{x_0}} + \sqrt{x_0} = \dfrac{x}{2\sqrt{x_0}} + \dfrac{\sqrt{x_0}}{2},$$
