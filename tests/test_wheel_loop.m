%% 差速轮式机器人仿真测试循环

clear;
clc;

test_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(test_dir);
addpath(project_dir);

dt = 1e-4;                 % 仿真步长 [s]
simulation_duration = 30;  % 仿真时长 [s]
control_period = 0.1;      % 控制周期 [s]

num_steps = round(simulation_duration / dt);
control_steps = round(control_period / dt);
time = (0:num_steps) * dt;

robot = rpm.wheel_robot();

% 状态顺序：[x; y; theta; angle_L; speed_L; angle_R; speed_R]
states = zeros(7, num_steps + 1);
pose_dot = zeros(3, num_steps + 1);
states(:, 1) = robot.getStates();
pose_dot(:, 1) = robot.getPoseDot();

for step_index = 1:num_steps
    current_time = (step_index - 1) * dt;

    % 每个控制周期更新一次左右轮角速度指令。
    if mod(step_index - 1, control_steps) == 0
        wheel_cmd = command_at_time(current_time);
        robot.sendCmd(wheel_cmd(1), wheel_cmd(2));
    end

    robot.step(dt,[]);

    states(:, step_index + 1) = robot.getStates();
    pose_dot(:, step_index + 1) = robot.getPoseDot();
end
%% 各状态量随时间变化
figure('Name', '车体位姿状态', 'Color', 'w');
layout = tiledlayout(3, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile;
plot(time, states(1, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('x [m]');
title('x 位置');

nexttile;
plot(time, states(2, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('y [m]');
title('y 位置');

nexttile;
plot(time, states(3, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('\theta [rad]');
title('航向角 \theta');

title(layout, '车体位姿状态');

figure('Name', '车体速度状态', 'Color', 'w');
layout = tiledlayout(3, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile;
plot(time, pose_dot(1, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('dx/dt [m/s]');
title('x 方向速度');

nexttile;
plot(time, pose_dot(2, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('dy/dt [m/s]');
title('y 方向速度');

nexttile;
plot(time, pose_dot(3, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('d\theta/dt [rad/s]');
title('航向角速度');

title(layout, '车体速度状态');

figure('Name', '车轮转角', 'Color', 'w');
layout = tiledlayout(2, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile;
plot(time, states(4, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('角度 [rad]');
title('左轮转角 \alpha_L');

nexttile;
plot(time, states(6, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('角度 [rad]');
title('右轮转角 \alpha_R');

title(layout, '左右车轮转角');

figure('Name', '车轮角速度', 'Color', 'w');
layout = tiledlayout(2, 1, 'TileSpacing', 'compact', ...
    'Padding', 'compact');

nexttile;
plot(time, states(5, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('角速度 [rad/s]');
title('左轮角速度 \Omega_L');

nexttile;
plot(time, states(7, :), 'LineWidth', 1.1);
grid on;
xlabel('时间 [s]');
ylabel('角速度 [rad/s]');
title('右轮角速度 \Omega_R');

title(layout, '左右车轮角速度');

%% 平面运动示意图
figure('Name', '轮式机器人平面运动', 'Color', 'w');
plot(states(1, :), states(2, :), 'b-', 'LineWidth', 1.2);
hold on;

% 每隔 1 s 绘制一个质点和航向箭头。
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
title('小车平面运动轨迹与航向');
legend('运动轨迹', '采样位置', '航向', '起点', '终点', ...
    'Location', 'best');

function wheel_cmd = command_at_time(time)
%COMMAND_AT_TIME 生成覆盖典型运动方式的左右轮角速度指令。
%   返回顺序为 [左轮; 右轮]，单位为 rad/s。
    if time < 5
        wheel_cmd = [8; 8];       % 直线前进
    elseif time < 10
        wheel_cmd = [-6; 6];      % 原地逆时针转向
    elseif time < 15
        wheel_cmd = [4; 10];      % 前进左转弧线
    elseif time < 20
        wheel_cmd = [-8; -8];     % 直线倒车
    elseif time < 25
        wheel_cmd = [-10; -4];    % 倒车弧线
    elseif time < 27.5
        wheel_cmd = [6; -6];      % 原地顺时针转向
    else
        wheel_cmd = [0; 0];       % 停车
    end
end
