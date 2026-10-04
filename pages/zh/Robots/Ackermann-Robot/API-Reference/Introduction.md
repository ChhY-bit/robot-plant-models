# 阿克曼机器人简介 {#introduction}

`rpm.ackermann_robot` 是 MATLAB `handle` 类，用于在纯滚动、无侧滑假设下模拟平面前轮转向、后轮驱动的阿克曼机器人。模型积分五个状态：后轴中点在世界坐标系下的位姿，以及虚拟前轮转角和虚拟车轮角速度。两个虚拟执行器通过各自的一阶响应跟踪保持的指令；实际前轮转角和四轮转速由这些状态通过几何关系计算。

航向角从世界坐标系 x 轴起逆时针计量；虚拟转角为正表示左转，轮速为正表示前进。单位采用米、秒和弧度。只有 `Metadata` 是公开属性；状态、参数和仿真设置应通过方法读取或修改。将对象赋给另一个变量时，二者引用同一个实例。

## 1. API 组织 {#1-api-organization}

- [属性](Properties.md)：元数据、状态布局、YAML 参数、保持指令和私有仿真配置。
- [方法](Methods.md)：初始化、读取、配置设置、指令发送、积分和虚拟执行器与车体速度转换。
- [模型理论](../Modeling/ackermann-robot-model.md)：为详细理论推导预留，目前尚未编写。

## 2. 基本用法 {#2-basic-usage}

将项目根目录（`+rpm/` 的父目录）加入 MATLAB 搜索路径后，即可创建机器人、发送执行器目标、推进仿真并读取结果。仅调用 `sendCmd()` 不会使机器人运动；指令会保持到下一次发送或重置。参数加载和导出函数也通过同一根目录访问，不要单独添加 `+rpm/` 或其子目录。源码仓库中应从 `packaging/` 运行 `setup`；发布 ZIP 中应从解压后的顶层目录运行。

```matlab
robot = rpm.ackermann_robot();
robot.sendCmd(0.2, 5); % Virtual steering angle [rad] and wheel speed [rad/s]
for k = 1:100
    robot.step(0.005, (k - 1) * 0.005); % Suitable for the bundled parameters
end
pose = robot.getPose();
fprintf('Pose: x=%f m, y=%f m, theta=%f rad\n', pose(1), pose(2), pose(3));
```

## 3. 可选的命名空间导入 {#3-optional-namespace-import}

所有公开类和辅助函数均属于 `rpm` 命名空间。上面的示例使用完整名称以避免歧义。如需省略 `rpm.` 前缀，可在脚本或函数开头写入 `import rpm.*`，或在命令窗口中执行：

```matlab
import rpm.*
params = load_ackermann_params();
robot = ackermann_robot(params);
robot.step(0.001);
```

导入仅作用于声明它的作用域，不会自动应用到所有函数或未来 MATLAB 会话。命令窗口的导入不能代替函数内的导入；在哪个作用域使用短名称，就应在那里导入。导入也不会安装项目或将其加入搜索路径。`robot.step()` 等对象方法调用不变。

通配符导入可能造成名称冲突。可使用 `rpm.ackermann_robot()` 明确指定类，或只导入需要的名称，例如 `import rpm.ackermann_robot` 和 `import rpm.load_ackermann_params`。MATLAB 的导入与作用域规则见[官方 `import` 文档](https://www.mathworks.com/help/matlab/ref/import.html)。
