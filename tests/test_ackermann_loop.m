%% Ackermann 机器人公共 API 仿真测试循环
% 本脚本只通过 ackermann_robot 的公共方法下发指令、推进仿真
% 和读取结果，覆盖静止、原地转向、前进/倒车直行、左右转弯与停车。

clear;
clc;

test_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(test_dir);
addpath(fullfile(project_dir, 'plants'));

dt = 1e-3;                 % 仿真步长 [s]
simulation_duration = 38;  % 仿真时长 [s]
control_period = 0.05;     % 控制更新周期 [s]

num_steps = round(simulation_duration / dt);
control_steps = round(control_period / dt);
time = (0:num_steps) * dt;

robot = ackermann_robot();
cmd_limits = robot.getCmdLimits();

states = zeros(5, num_steps + 1);
pose_dot = zeros(3, num_steps + 1);
commands = zeros(2, num_steps + 1);
physical_steering = zeros(2, num_steps + 1);
physical_wheel_speed = zeros(4, num_steps + 1);

states(:, 1) = robot.getStates();
pose_dot(:, 1) = robot.getPoseDot();
commands(:, 1) = robot.getCmd();
physical_steering(:, 1) = robot.getPhysicalSteeringAngle();
physical_wheel_speed(:, 1) = robot.getPhysicalWheelSpeed();

for step_index = 1:num_steps
    current_time = (step_index - 1) * dt;

    if mod(step_index - 1, control_steps) == 0
        normalized_cmd = command_at_time(current_time);
        command = normalized_cmd .* cmd_limits;
        robot.sendCmd(command(1), command(2));
    end

    robot.step(dt, current_time);

    states(:, step_index + 1) = robot.getStates();
    pose_dot(:, step_index + 1) = robot.getPoseDot();
    commands(:, step_index + 1) = robot.getCmd();
    physical_steering(:, step_index + 1) = ...
        robot.getPhysicalSteeringAngle();
    physical_wheel_speed(:, step_index + 1) = ...
        robot.getPhysicalWheelSpeed();
end

assert(all(isfinite(states), 'all'));
assert(all(isfinite(pose_dot), 'all'));
assert(all(isfinite(physical_steering), 'all'));
assert(all(isfinite(physical_wheel_speed), 'all'));

%% 平面运动轨迹
figure('Name', 'Ackermann 机器人平面运动', 'Color', 'w');
plot(states(1, :), states(2, :), 'b-', 'LineWidth', 1.2);
hold on;

pose_sample_steps = round(1 / dt);
pose_indices = 1:pose_sample_steps:(num_steps + 1);
if pose_indices(end) ~= num_steps + 1
    pose_indices(end + 1) = num_steps + 1;
end

x_span = max(states(1, :)) - min(states(1, :));
y_span = max(states(2, :)) - min(states(2, :));
arrow_length = max(0.15, 0.06 * max(x_span, y_span));

plot(states(1, pose_indices), states(2, pose_indices), ...
    'ko', 'MarkerSize', 4, 'MarkerFaceColor', 'k');
quiver(states(1, pose_indices), states(2, pose_indices), ...
    arrow_length * cos(states(3, pose_indices)), ...
    arrow_length * sin(states(3, pose_indices)), ...
    0, 'r', 'LineWidth', 1.1, 'MaxHeadSize', 0.8);
plot(states(1, 1), states(2, 1), 'go', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'g');
plot(states(1, end), states(2, end), 'ms', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'm');

hold off;
axis equal;
grid on;
xlabel('x [m]');
ylabel('y [m]');
title('Ackermann 机器人运动轨迹与航向');
legend('运动轨迹', '采样位置', '航向', '起点', '终点', ...
    'Location', 'best');

%% 位姿状态
figure('Name', 'Ackermann 位姿状态', 'Color', 'w');
layout = tiledlayout(3, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile;
plot(time, states(1, :), 'LineWidth', 1.1);
grid on;
ylabel('x [m]');
title('x 位置');

nexttile;
plot(time, states(2, :), 'LineWidth', 1.1);
grid on;
ylabel('y [m]');
title('y 位置');

nexttile;
plot(time, states(3, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('\theta [rad]');
title('航向角 \theta');

title(layout, '后轮轴中点位姿 Pose');

%% 位姿变化率
figure('Name', 'Ackermann 位姿变化率', 'Color', 'w');
layout = tiledlayout(3, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile;
plot(time, pose_dot(1, :), 'LineWidth', 1.1);
grid on;
ylabel('dx/dt [m/s]');
title('x 方向速度');

nexttile;
plot(time, pose_dot(2, :), 'LineWidth', 1.1);
grid on;
ylabel('dy/dt [m/s]');
title('y 方向速度');

nexttile;
plot(time, pose_dot(3, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('d\theta/dt [rad/s]');
title('航向角速度');

title(layout, '世界坐标系下的 PoseDot');

%% 虚拟执行器指令与实际状态
figure('Name', 'Ackermann 虚拟执行器', 'Color', 'w');
layout = tiledlayout(2, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile;
plot(time, commands(1, :), '--', 'LineWidth', 1.0);
hold on;
plot(time, states(4, :), 'LineWidth', 1.2);
hold off;
grid on;
ylabel('转角 [rad]');
legend('指令', '实际', 'Location', 'best');
title('虚拟转向角');

nexttile;
plot(time, commands(2, :), '--', 'LineWidth', 1.0);
hold on;
plot(time, states(5, :), 'LineWidth', 1.2);
hold off;
grid on;
xlabel('时间 [s]');
ylabel('轮速 [rad/s]');
legend('指令', '实际', 'Location', 'best');
title('虚拟轮速');
title(layout, '虚拟执行器的一阶响应');

%% 实体前轮转角
figure('Name', 'Ackermann 实体前轮转角', 'Color', 'w');
plot(time, physical_steering(1, :), 'LineWidth', 1.2);
hold on;
plot(time, physical_steering(2, :), 'LineWidth', 1.2);
hold off;
grid on;
xlabel('时间 [s]');
ylabel('转角 [rad]');
title('左右前轮转角');
legend('左前轮', '右前轮', 'Location', 'best');

%% 四个实体车轮的角速度
figure('Name', 'Ackermann 实体轮速', 'Color', 'w');
plot(time, physical_wheel_speed, 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('角速度 [rad/s]');
title('四个实体车轮的角速度');
legend('左前轮', '右前轮', '左后轮', '右后轮', ...
    'Location', 'best');

disp('Ackermann loop test completed');

function normalized_cmd = command_at_time(time)
%COMMAND_AT_TIME 返回按对称指令上限归一化的 [转角; 轮速]。
    if time < 2
        normalized_cmd = [0; 0];          % 静止
    elseif time < 5
        normalized_cmd = [0.55; 0];       % 停车时原地转向
    elseif time < 9
        normalized_cmd = [0; 0.55];       % 直线前进
    elseif time < 13
        normalized_cmd = [0.65; 0.60];    % 前进左转
    elseif time < 17
        normalized_cmd = [-0.65; 0.60];   % 前进右转
    elseif time < 20
        normalized_cmd = [0; 0.30];       % 回正并减速前进
    elseif time < 23
        normalized_cmd = [0; 0];          % 停车并回正
    elseif time < 27
        normalized_cmd = [0; -0.50];      % 直线倒车
    elseif time < 31
        normalized_cmd = [0.60; -0.55];   % 倒车左打方向
    elseif time < 35
        normalized_cmd = [-0.60; -0.55];  % 倒车右打方向
    else
        normalized_cmd = [0; 0];          % 最终停车
    end
end
