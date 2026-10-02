function test_ackermann_robot()
%TEST_ACKERMANN_ROBOT 检查参数加载器和对象初始化框架。
    test_dir = fileparts(mfilename('fullpath'));
    project_dir = fileparts(test_dir);
    addpath(project_dir);

    params = rpm.load_ackermann_params();
    expected_fields = {'wheelRadius', 'wheelBase', 'trackWidth', ...
        'wheelTimeConstant', 'steeringTimeConstant', ...
        'maxPhysicalWheelSpeed', 'maxPhysicalSteeringAngle', ...
        'bodySize', 'wheelWidth', 'rearAxleOffset'};
    assert(isequal(fieldnames(params), expected_fields'));
    assert(isa(params.wheelRadius, 'double') && isscalar(params.wheelRadius));
    assert(isequal(size(params.bodySize), [3, 1]));
    assert(params.maxPhysicalSteeringAngle > 0);
    assert(params.maxPhysicalSteeringAngle < pi / 2);

    % 导出的内置模板应可重新加载，且不得覆盖已有文件或目录。
    exported_path = string(tempname) + ".yaml";
    exported_cleanup = onCleanup(@() delete_if_file(exported_path));
    actual_path = rpm.export_ackermann_params(exported_path);
    assert(isfile(actual_path));
    assert(isequal(rpm.load_ackermann_params(actual_path), params));
    must_reject(@() rpm.export_ackermann_params(actual_path));
    must_reject(@() rpm.export_ackermann_params(string(tempdir)));

    % 默认构造、行状态规范化和元数据默认字段。
    initial_states = int16([0, 1, 2, 0, 4]);
    robot = rpm.ackermann_robot(params, initial_states);
    assert(isequal(robot.getStates(), double(initial_states')));
    assert(isequal(robot.getCmd(), zeros(2, 1)));
    assert(strcmp(robot.Metadata.Name, 'ackermann_robot'));
    assert(isequal(robot.getParams(), params));

    % 加载器允许零时间常数但不替换；替换属于对象构造职责。
    zero_params = params;
    zero_params.wheelTimeConstant = 0;
    zero_params.steeringTimeConstant = 0;
    yaml_path = write_params_yaml(zero_params);
    yaml_cleanup = onCleanup(@() delete_if_file(yaml_path));
    loaded_zero_params = rpm.load_ackermann_params(yaml_path);
    assert(loaded_zero_params.wheelTimeConstant == 0);
    assert(loaded_zero_params.steeringTimeConstant == 0);

    saved_warning = warning('on', 'ackermann_robot:ZeroTimeConstant');
    warning_cleanup = onCleanup(@() warning(saved_warning));
    lastwarn('');
    zero_robot = rpm.ackermann_robot(loaded_zero_params);
    [~, warning_id] = lastwarn();
    assert(strcmp(warning_id, 'ackermann_robot:ZeroTimeConstant'));
    actual_params = zero_robot.getParams();
    assert(actual_params.wheelTimeConstant == 1e-3);
    assert(actual_params.steeringTimeConstant == 1e-3);

    % 状态读取、虚拟执行器换算和六维代数输出。
    steering = 0.2;
    wheel_speed = 4;
    heading = 0.3;
    robot = rpm.ackermann_robot(params, [1; 2; heading; steering; wheel_speed]);
    expected_velocity = [params.wheelRadius*wheel_speed; ...
        params.wheelRadius*wheel_speed*tan(steering)/params.wheelBase];
    assert(isequal(robot.getPose(), [1; 2; heading]));
    assert(robot.getVirtualSteeringAngle() == steering);
    assert(robot.getVirtualWheelSpeed() == wheel_speed);
    assert(norm(robot.getVel()-expected_velocity) < 1e-12);
    expected_pose_dot = [expected_velocity(1)*cos(heading); ...
        expected_velocity(1)*sin(heading); expected_velocity(2)];
    assert(norm(robot.getPoseDot()-expected_pose_dot) < 1e-12);

    lambda = params.trackWidth/(2*params.wheelBase);
    tangent = tan(steering);
    expected_output = [atan(tangent/(1-lambda*tangent)); ...
        atan(tangent/(1+lambda*tangent)); ...
        wheel_speed*(1-lambda*tangent); ...
        wheel_speed*(1+lambda*tangent); ...
        wheel_speed*sqrt(1-2*lambda*tangent+(1+lambda^2)*tangent^2); ...
        wheel_speed*sqrt(1+2*lambda*tangent+(1+lambda^2)*tangent^2)];
    assert(isequal(robot.getPhysicalSteeringAngle(), expected_output(1:2)));
    assert(isequal(robot.getPhysicalWheelSpeed(), ...
        expected_output([5; 6; 3; 4])));
    assert(norm(robot.virtual2body(robot.body2virtual(expected_velocity)) - ...
        expected_velocity) < 1e-12);
    assert(isequal(robot.body2virtual([0; 0]), [0; 0]));

    % sendCmd 使用文档中的保守瞬态矩形限幅，并维持 Ackermann 关系。
    steering_limit = atan(2*params.wheelBase*tan(params.maxPhysicalSteeringAngle) / ...
        (2*params.wheelBase+params.trackWidth*tan(params.maxPhysicalSteeringAngle)));
    gamma = 1+2*lambda*tan(steering_limit) + ...
        (1+lambda^2)*tan(steering_limit)^2;
    wheel_speed_limit = params.maxPhysicalWheelSpeed/sqrt(gamma);
    assert(norm(robot.getCmdLimits()-[steering_limit; wheel_speed_limit]) < 1e-12);
    saved_saturation_warning = warning('on', 'ackermann_robot:CommandSaturated');
    saturation_cleanup = onCleanup(@() warning(saved_saturation_warning));
    lastwarn('');
    robot.sendCmd(100, -100);
    [~, warning_id] = lastwarn();
    assert(strcmp(warning_id, 'ackermann_robot:CommandSaturated'));
    assert(norm(robot.getCmd()-[steering_limit; -wheel_speed_limit]) < 1e-12);
    boundary_robot = rpm.ackermann_robot(params, ...
        [0; 0; 0; steering_limit; wheel_speed_limit]);
    assert(max(abs(boundary_robot.getPhysicalSteeringAngle())) <= ...
        params.maxPhysicalSteeringAngle+1e-12);
    assert(max(abs(boundary_robot.getPhysicalWheelSpeed())) <= ...
        params.maxPhysicalWheelSpeed+1e-12);

    % 构造与 reset 接受正负边界，拒绝超限状态且不自动裁剪。
    limits = robot.getCmdLimits();
    for steering_sign = [-1, 1]
        for speed_sign = [-1, 1]
            boundary_states = [1; 2; 3; steering_sign*limits(1); speed_sign*limits(2)];
            boundary_robot = rpm.ackermann_robot(params, boundary_states);
            assert(isequal(boundary_robot.getStates(), boundary_states));
            boundary_robot.sendCmd(0.1, 1);
            boundary_robot.reset(boundary_states');
            assert(isequal(boundary_robot.getStates(), boundary_states));
            assert(isequal(boundary_robot.getCmd(), zeros(2, 1)));
            assert(max(abs(boundary_robot.getPhysicalSteeringAngle())) <= ...
                params.maxPhysicalSteeringAngle+1e-12);
            assert(max(abs(boundary_robot.getPhysicalWheelSpeed())) <= ...
                params.maxPhysicalWheelSpeed+1e-12);
        end
    end
    preserved_states = robot.getStates();
    preserved_cmd = robot.getCmd();
    for state_index = 4:5
        for state_sign = [-1, 1]
            invalid_states = zeros(5, 1);
            invalid_states(state_index) = state_sign * ...
                (limits(state_index-3) + eps(limits(state_index-3)));
            must_reject_initial_state(@() rpm.ackermann_robot(params, invalid_states));
            must_reject_initial_state(@() robot.reset(invalid_states));
            assert(isequal(robot.getStates(), preserved_states));
            assert(isequal(robot.getCmd(), preserved_cmd));
        end
    end
    robot.setWarnOnSaturation(false);
    lastwarn('');
    robot.sendCmd(-100, 100);
    [message, ~] = lastwarn();
    assert(isempty(message));

    % 一阶执行器响应应与解析解一致；固定执行器状态形成圆弧轨迹。
    robot = rpm.ackermann_robot(params);
    robot.sendCmd(0.25, 3);
    dt = 1e-3;
    duration = 0.5;
    for k = 1:round(duration/dt)
        robot.step(dt, (k-1)*dt);
    end
    expected_actuator = [0.25*(1-exp(-duration/params.steeringTimeConstant)); ...
        3*(1-exp(-duration/params.wheelTimeConstant))];
    actual_actuator = [robot.getVirtualSteeringAngle(); ...
        robot.getVirtualWheelSpeed()];
    assert(norm(actual_actuator-expected_actuator) < 1e-11);

    steering = 0.2;
    wheel_speed = 3;
    robot = rpm.ackermann_robot(params, [0; 0; 0; steering; wheel_speed]);
    robot.sendCmd(steering, wheel_speed);
    for k = 1:100
        robot.step(0.01);
    end
    velocity = robot.getVel();
    expected_pose = [velocity(1)/velocity(2)*sin(velocity(2)); ...
        velocity(1)/velocity(2)*(1-cos(velocity(2))); velocity(2)];
    assert(norm(robot.getPose()-expected_pose) < 1e-11);

    % reset 和公共配置接口与 wheel_robot 保持一致。
    robot.setWrapHeading(true);
    robot.reset([0; 0; 4; 0; 0]);
    assert(isequal(robot.getCmd(), zeros(2, 1)));
    robot.step(1e-3);
    wrapped_pose = robot.getPose();
    assert(wrapped_pose(3) >= -pi && wrapped_pose(3) < pi);
    robot.setSolutionMethod('Euler');
    robot.sendCmd(0.1, 1);
    robot.step(1e-3);
    actual_actuator = [robot.getVirtualSteeringAngle(); ...
        robot.getVirtualWheelSpeed()];
    assert(norm(actual_actuator-[0.001; 0.005]) < 1e-12);

    % 缺失字段、非法范围、错误维度和非法 YAML 都必须被拒绝。
    must_reject(@() rpm.load_ackermann_params( ...
        fullfile(project_dir, '+rpm', 'config', 'missing.yaml')));
    must_reject(@() rpm.ackermann_robot(rmfield(params, 'wheelBase')));
    must_reject(@() rpm.ackermann_robot(params, zeros(6, 1)));
    must_reject(@() rpm.ackermann_robot(params, [NaN; zeros(4, 1)]));
    must_reject(@() rpm.ackermann_robot(params, [], 'invalid'));
    must_reject(@() robot.step(0));
    must_reject(@() robot.step(1e-3, NaN));
    must_reject(@() robot.sendCmd(Inf, 0));
    must_reject(@() robot.body2virtual([0; 1]));
    must_reject(@() robot.virtual2body([1; 2; 3]));
    must_reject(@() robot.reset(zeros(5)));
    must_reject(@() robot.setSolutionMethod(string(missing)));
    must_reject(@() robot.setWrapHeading(1));

    invalid_params = params;
    invalid_params.wheelRadius = 0;
    must_reject(@() rpm.ackermann_robot(invalid_params));
    invalid_params = params;
    invalid_params.wheelTimeConstant = -1;
    must_reject(@() rpm.ackermann_robot(invalid_params));
    invalid_params = params;
    invalid_params.maxPhysicalSteeringAngle = pi / 2;
    must_reject(@() rpm.ackermann_robot(invalid_params));

    % 初始虚拟转角必须位于 Ackermann 映射的正常几何域。
    steering_domain = atan(2*params.wheelBase/params.trackWidth);
    must_reject(@() rpm.ackermann_robot(params, ...
        [0; 0; 0; steering_domain; 0]));
    must_reject(@() rpm.ackermann_robot(params, [0; 0; 0; pi; 0]));
    preserved_states = robot.getStates();
    preserved_cmd = robot.getCmd();
    must_reject(@() robot.reset([0; 0; 0; -steering_domain; 0]));
    assert(isequal(robot.getStates(), preserved_states));
    assert(isequal(robot.getCmd(), preserved_cmd));

    invalid_yaml = replace(readlines(yaml_path), ...
        "wheelRadius: 0.1", "wheelRadius: [0.1, 0.1]");
    invalid_yaml_path = string(tempname) + ".yaml";
    invalid_cleanup = onCleanup(@() delete_if_file(invalid_yaml_path));
    writelines(invalid_yaml, invalid_yaml_path);
    must_reject(@() rpm.load_ackermann_params(invalid_yaml_path));

    disp('ackermann_robot regression checks passed');
end

function file_path = write_params_yaml(params)
%WRITE_PARAMS_YAML 为加载器回归测试创建完整的临时配置。
    file_path = string(tempname) + ".yaml";
    lines = [
        "wheelRadius: " + string(params.wheelRadius)
        "wheelBase: " + string(params.wheelBase)
        "trackWidth: " + string(params.trackWidth)
        "wheelTimeConstant: " + string(params.wheelTimeConstant)
        "steeringTimeConstant: " + string(params.steeringTimeConstant)
        "maxPhysicalWheelSpeed: " + string(params.maxPhysicalWheelSpeed)
        "maxPhysicalSteeringAngle: " + string(params.maxPhysicalSteeringAngle)
        "bodySize: [" + join(string(params.bodySize'), ", ") + "]"
        "wheelWidth: " + string(params.wheelWidth)
        "rearAxleOffset: " + string(params.rearAxleOffset)
    ];
    writelines(lines, file_path);
end

function must_reject(action)
%MUST_REJECT 验证无效输入被拒绝。
    rejected = false;
    try
        action();
    catch
        rejected = true;
    end
    assert(rejected, '无效输入未被拒绝。');
end

function must_reject_initial_state(action)
%MUST_REJECT_INITIAL_STATE 验证超限错误标识和允许范围提示。
    rejected = false;
    try
        action();
    catch cause
        assert(strcmp(cause.identifier, 'ackermann_robot:InvalidInitialState'));
        assert(contains(cause.message, '虚拟转角允许范围'));
        assert(contains(cause.message, '虚拟轮速允许范围'));
        rejected = true;
    end
    assert(rejected, '超限初始状态未被拒绝。');
end

function delete_if_file(file_path)
%DELETE_IF_FILE 删除本测试创建的临时文件。
    if isfile(file_path)
        delete(file_path);
    end
end
