function test_wheel_robot()
%TEST_WHEEL_ROBOT 检查机器人输入边界、运动学与积分结果。
%   运行 test_wheel_robot，不绘图；失败时由 assert 报告。
    test_dir = fileparts(mfilename('fullpath'));
    project_dir = fileparts(test_dir);
    addpath(project_dir);
    params = rpm.utils.load_wheel_params();
    params.wheelRadius = [0.08; 0.12];
    params.motorTimeConstant = [0.1; 0.2];
    params.maxWheelSpeed = [3.5; 5.5];

    % 行向量、整数输入应规范化，且左右不对称参数的换算互逆。
    robot = rpm.wheel_robot(params, int16([0, 0, 1, 0, 3, 0, 5]));
    assert(isequal(robot.getStates(), [0; 0; 1; 0; 3; 0; 5]));
    assert(isequal(robot.getCmd(), [0; 0]));
    expected_body = [(0.08*3 + 0.12*5)/2; (0.12*5 - 0.08*3)/0.45];
    assert(norm(robot.getVel() - expected_body) < 1e-12);
    assert(norm(robot.wheel2body(int16([3, 5])) - expected_body) < 1e-12);
    assert(norm(robot.body2wheel(expected_body) - [3; 5]) < 1e-12);
    assert(norm(robot.body2wheel(int16([1, 0])) - [1/0.08; 1/0.12]) < 1e-12);
    expected_dot = [cos(1)*expected_body(1); sin(1)*expected_body(1); expected_body(2)];
    assert(norm(robot.getPoseDot() - expected_dot) < 1e-12);

    % 参数接口应返回对象实际采用的参数，且外部修改返回值不影响对象。
    returned_params = robot.getParams();
    assert(isequal(returned_params, params));
    returned_params.trackWidth = 99;
    assert(robot.getParams().trackWidth == params.trackWidth);

    % 导出的 YAML 模板应能重新读入，且不得覆盖已有目标文件。
    exported_path = string(tempname) + ".yaml";
    exported_cleanup = onCleanup(@() delete_if_file(exported_path));
    actual_path = rpm.utils.export_wheel_params(exported_path);
    assert(isfile(actual_path));
    assert(isequal(rpm.utils.load_wheel_params(actual_path), rpm.utils.load_wheel_params()));
    must_reject(@() rpm.utils.export_wheel_params(actual_path));

    for method = ["euler", "RK4"]
        row_robot = rpm.wheel_robot(params, 0:6);
        col_robot = rpm.wheel_robot(params, (0:6)');
        row_robot.setSolutionMethod(method);
        col_robot.setSolutionMethod(method);
        row_robot.step(1e-4);
        col_robot.step(1e-4, []);
        assert(isequal(size(row_robot.getPose()), [3, 1]));
        assert(isequal(row_robot.getPose(), col_robot.getPose()));
        assert(isequal(row_robot.getWheelSpeed(), col_robot.getWheelSpeed()));
    end

    % 只发送一次指令：对照一阶转速及其转角积分的解析解。
    robot = rpm.wheel_robot(params);
    robot.sendCmd(2, 4);
    dt = 1e-3;
    duration = 0.5;
    for k = 1:round(duration/dt)
        robot.step(dt, (k-1)*dt);
    end
    decay = exp(-duration ./ params.motorTimeConstant);
    expected_speed = [2; 4] .* (1 - decay);
    expected_angle = [2; 4] .* (duration - params.motorTimeConstant .* (1-decay));
    assert(norm(robot.getWheelSpeed() - expected_speed) < 1e-9);
    assert(norm(robot.getWheelAngle() - expected_angle) < 1e-9);

    % 恒定轮速圆弧：用解析轨迹校验位置、航向和 RK4 状态耦合。
    robot = rpm.wheel_robot(params, [0; 0; 0; 0; 2; 0; 4]);
    robot.sendCmd(2, 4);
    for k = 1:100
        robot.step(0.01);
    end
    v = (0.08*2 + 0.12*4)/2;
    omega = (0.12*4 - 0.08*2)/params.trackWidth;
    expected_pose = [v/omega*sin(omega); v/omega*(1-cos(omega)); omega];
    assert(norm(robot.getPose() - expected_pose) < 1e-10);

    % 默认饱和警告，整数指令对非整数上限限幅时不应发生取整。
    saved_warning = warning('on', 'wheel_robot:CommandSaturated');
    restore_warning = onCleanup(@() warning(saved_warning));
    robot = rpm.wheel_robot(params);
    robot.setSolutionMethod('Euler');
    lastwarn('');
    robot.sendCmd(int16(100), int16(-100));
    [~, warning_id] = lastwarn();
    assert(strcmp(warning_id, 'wheel_robot:CommandSaturated'));
    assert(isequal(robot.getCmd(), [3.5; -5.5]));
    robot.step(dt);
    assert(norm(robot.getWheelSpeed() - dt*[3.5; -5.5]./params.motorTimeConstant) < 1e-12);
    robot.setWarnOnSaturation(false);
    lastwarn('');
    robot.sendCmd(100, -100);
    [message, ~] = lastwarn();
    assert(isempty(message));

    robot = rpm.wheel_robot(params, [0; 0; 4; 0; 0; 0; 0]);
    robot.step(dt);
    pose = robot.getPose();
    assert(pose(3) == 4);
    robot.setWrapHeading(true);
    robot.step(dt);
    pose = robot.getPose();
    assert(abs(pose(3) - (4 - 2*pi)) < 1e-12);

    % reset 应设置给定状态并清零保持指令，同时保留现有配置。
    robot.sendCmd(1, 2);
    reset_state = [1, 2, 4, 5, 6, 7, 8];
    robot.reset(reset_state);
    assert(isequal(robot.getStates(), reset_state'));
    assert(isequal(robot.getCmd(), [0; 0]));
    robot.step(dt);
    reset_pose = robot.getPose();
    assert(reset_pose(3) >= -pi && reset_pose(3) < pi);

    % dt/T 超过推荐值时只在进入警告区间时提示，避免连续积分刷屏。
    warning_params = params;
    warning_params.motorTimeConstant = [0.1; 0.2];
    warning_robot = rpm.wheel_robot(warning_params);
    warning_robot.setSolutionMethod('euler');
    saved_step_warning = warning('on', 'wheel_robot:LargeStepSize');
    restore_step_warning = onCleanup(@() warning(saved_step_warning));
    lastwarn('');
    warning_robot.step(0.02);
    [~, warning_id] = lastwarn();
    assert(strcmp(warning_id, 'wheel_robot:LargeStepSize'));
    lastwarn('');
    warning_robot.step(0.02);
    [message, ~] = lastwarn();
    assert(isempty(message));
    warning_robot.step(0.001);
    lastwarn('');
    warning_robot.step(0.02);
    [~, warning_id] = lastwarn();
    assert(strcmp(warning_id, 'wheel_robot:LargeStepSize'));

    % 零时间常数替换后应等价于显式设置 1e-3 s。
    params.motorTimeConstant = [0; 0.2];
    robot = rpm.wheel_robot(params);
    params.motorTimeConstant(1) = 1e-3;
    reference = rpm.wheel_robot(params);
    robot.sendCmd(1, 1);
    reference.sendCmd(1, 1);
    robot.step(1e-4);
    reference.step(1e-4);
    assert(isequal(robot.getWheelSpeed(), reference.getWheelSpeed()));

    must_reject(@() rpm.wheel_robot(params, zeros(7)));
    must_reject(@() rpm.wheel_robot(params, [NaN; zeros(6, 1)]));
    must_reject(@() rpm.wheel_robot(params, [], 'invalid'));
    must_reject(@() rpm.wheel_robot(rmfield(params, 'wheelRadius')));
    params.trackWidth = 0;
    must_reject(@() rpm.wheel_robot(params));
    must_reject(@() robot.step(0));
    must_reject(@() robot.step(1e-4, NaN));
    must_reject(@() robot.sendCmd(Inf, 0));
    must_reject(@() robot.body2wheel([1, 2, 3]));
    must_reject(@() robot.reset(zeros(7)));
    must_reject(@() robot.setSolutionMethod(string(missing)));
    must_reject(@() robot.setWrapHeading(1));
    disp('wheel_robot regression checks passed');
end

function must_reject(action)
%MUST_REJECT 验证无效输入被拒绝，而非继续进入计算。
%   action 为不带参数的函数句柄；没有抛出异常时测试失败。
    rejected = false;
    try
        action();
    catch
        rejected = true;
    end
    assert(rejected, '无效输入未被拒绝。');
end

function delete_if_file(file_path)
%DELETE_IF_FILE 删除本测试创建的临时文件。
    if isfile(file_path)
        delete(file_path);
    end
end
