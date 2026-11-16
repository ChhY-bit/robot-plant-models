# 四水箱容器简介 {#introduction}

`rpm.quadruple_tank` 是 MATLAB `handle` 类，用于模拟四个相互连接的水箱。两个水泵通过可调分流阀向水箱供水。模型根据质量平衡与重力驱动的出水规律积分四个液位，并支持叠加液位变化率扰动。

状态顺序为 `[x1; x2; x3; x4]`，单位为米。水泵输入为体积流量，单位为 `m^3/s`；扰动单位为 `m/s`。水箱 3 和 4 分别向水箱 1 和 2 排水。通常取 `[x1; x2]` 为测量输出，四个液位均可公开读取。将对象赋给另一个变量时，二者引用同一个实例。

## 1. API 组织 {#1-api-organization}

- [属性](Properties.md)：液位、YAML 字段与属性映射、保持的水泵输入、阀门分配比及扰动。
- [方法](Methods.md)：构造、水泵指令、阀门设置、扰动设置和积分。
- [工具函数](Utils.md)：YAML 参数加载、校验及模板导出。
- [模型理论](../Modeling/quadruple-tank-model.md)：水箱连接、状态方程及数值边界处理。

## 2. 基本用法 {#2-basic-usage}

将项目根目录（`+rpm/` 的父目录）加入 MATLAB 搜索路径，不要单独添加 `+rpm/` 或其子目录。创建对象、设置水泵输入后，通过 `step(dt, t)` 推进仿真，再读取液位属性。两个时间参数均须提供。水泵输入、阀门设置和扰动会保持到被替换；仅设置这些值不会推进仿真。

```matlab
tank = rpm.quadruple_tank();
tank.send(1e-5, 1e-5); % Pump flow rates [m^3/s]
dt = 0.01;
for k = 1:1000
    tank.step(dt, (k - 1) * dt);
end
levels = [tank.x1; tank.x2; tank.x3; tank.x4];
output = levels(1:2); % Lower-tank measurements [m]
```

步长应根据参数与输入变化选择，尤其应注意接近排空的水箱。当前实现将液位截断在零以上，没有设置水箱容量上限。

## 3. 可选的命名空间导入 {#3-optional-namespace-import}

类属于 `rpm`，参数工具函数属于 `rpm.utils`。如需使用短名称，应在使用处分别导入：

```matlab
import rpm.*
import rpm.utils.*
params = load_quadruple_tank_params();
tank = quadruple_tank(params, [0.1; 0.1; 0.1; 0.1]);
tank.step(0.01, 0);
```

导入只对声明它的作用域生效。当前类直接公开液位的读取权限，没有 `getStates()`、`getParams()` 或 `reset()` 方法。如需用指定液位重新开始，或更换固定物理参数，应创建新对象。
