classdef wheel_robot < handle
    %WHEEL_ROBOT 带左右轮一阶转速响应的差速机器人仿真对象。
    %   本模型采用平面纯滚动假设且忽略侧滑。
    %   位姿参考点为驱动轴中点，theta 从世界坐标系 x 轴起算且逆时针为正。
    %   两轮正转均对应车体前进。
    %   长度、时间、角度的单位分别为 m、s、rad，左右轮始终先左后右。
    %   通过 sendCmd 更新并保持目标轮速，通过 step 推进连续状态。
    %   本类为 handle 类，赋值给另一变量后，两变量引用同一个对象。

    properties (Access = private)
        States
            % 状态为 7x1 double，排列为：
            % [px; py; theta; left_wheel_angle; left_wheel_speed; right_wheel_angle; right_wheel_speed]。
            % 单位依次为 [m; m; rad; rad; rad/s; rad; rad/s]。
            % 轮角累计不归一化；航向角是否归一化由 Config 控制。
        Params
            % wheelRadius 是 2x1 左右轮半径 [m]，必须为正数。
            % trackWidth 是轮距 [m]，必须为正数。
            % motorTimeConstant 是 2x1 左右轮一阶时间常数 [s]。
            % maxWheelSpeed 是 2x1 左右轮目标角速度绝对值上限 [rad/s]，必须为正数。
            % bodySize 是 3x1 主体长、宽、高 [m]，各项必须为正数。
            % wheelWidth 是 2x1 左右轮宽 [m]，各项必须为正数。
            % axleOffset 是驱动轴中点相对主体中心的前向偏移 [m]，可正可负。
            % bodySize、wheelWidth 和 axleOffset 是几何显示参数，当前不参与运动方程。
        Cmd
            % left 和 right 分别保存限幅后保持的左右轮目标角速度 [rad/s]。
            % sendCmd 写入 Cmd，step 读取 Cmd，两个指令的初值均为 0。
        Config
            % solution_method 指定 'euler' 或 'RK4'，默认值为 'RK4'。
            % wrap_heading 指定积分后是否归一化 theta，默认值为 false。
            % warn_on_saturation 指定指令限幅时是否警告，默认值为 true。
        StepSizeWarningActive
            % 标记上一步是否处于步长比值警告区间，用于避免连续 step 重复警告。
    end

    properties(Access = public)
        Metadata
            % 描述信息结构体，不参与计算，可添加自定义字段。
            % Name 保存对象名称，Number 保存对象编号，Description 保存对象说明。
    end

    %% 外部方法：供使用
    methods (Access = public)
        function obj = wheel_robot(Params, Ini_States, Metadata)
            %WHEEL_ROBOT 创建并初始化差速机器人。
            %   obj = rpm.wheel_robot(Params, ini_states, Metadata) 创建对象。
            %   三个入参均可省略或传 []，默认值依次为 rpm.load_wheel_params() 的结果、七维零状态和带默认描述字段的结构体。
            %   Params 必须为包含上述物理字段的标量结构体，双轮参数可用标量表示左右相同，也可传入双元素向量并由构造函数转成列向量。
            %   ini_states 接受七元素行向量或列向量，排列顺序见 States 属性说明。
            %   电机时间常数为零时会发出警告并替换为 1e-3 s，其他有效值原样保留。
            %   初始轮速原样保留，maxWheelSpeed 仅约束 sendCmd 写入的目标轮速。
            %   默认目标轮速为零，因此初始非零轮速会逐渐衰减。
            if nargin < 1 || isempty(Params)
                Params = rpm.load_wheel_params();
            end
            Params = obj.validateParams(Params);

            if nargin < 2 || isempty(Ini_States)
                Ini_States = zeros(7, 1);
            end
            if nargin < 3 || isempty(Metadata)
                Metadata = struct();
            end
            validateattributes(Metadata, {'struct'}, {'scalar'}, ...
                mfilename, 'Metadata');
            if ~isfield(Metadata, 'Name')
                Metadata.Name = 'wheel_robot';
            end
            if ~isfield(Metadata, 'Number')
                Metadata.Number = [];
            end
            if ~isfield(Metadata, 'Description')
                Metadata.Description = 'none';
            end

            obj.Params = Params;
            obj.Metadata = Metadata;
            obj.Config.solution_method = 'RK4';
            obj.Config.wrap_heading = false;
            obj.Config.warn_on_saturation = true;
            obj.reset(Ini_States);
        end

        function reset(obj, ini_states)
            %RESET 复位机器人状态和当前保持的轮速指令。
            %   obj.reset() 将七维状态和左右轮速指令全部复位为零。
            %   obj.reset(ini_states) 将状态复位为给定的七元素行向量或列向量，并将左右轮速指令清零。
            %   本方法保留 Params、Metadata 和 Config，不会改变物理参数、描述信息或求解设置。
            if nargin < 2 || isempty(ini_states)
                ini_states = zeros(7, 1);
            end
            validateattributes(ini_states, {'numeric'}, ...
                {'real','finite','vector','numel',7}, mfilename, 'ini_states');
            obj.States = double(ini_states(:));
            obj.Cmd.left = 0;
            obj.Cmd.right = 0;
            obj.StepSizeWarningActive = false;
        end
        
        % =============== 1. 外部获取接口 ===============

        % ---------- 1.1 获取完整状态 ----------
        function states = getStates(obj)
            %GETSTATES 获取机器人的完整七维状态。
            %   states = obj.getStates() 返回 7x1 状态向量 [px; py; theta; left_wheel_angle; left_wheel_speed; right_wheel_angle; right_wheel_speed]。
            %   单位依次为 [m; m; rad; rad; rad/s; rad; rad/s]，修改返回值不会改变对象内部状态。
            states = obj.States;
        end

        % ---------- 1.2 获取当前指令 ----------
        function cmd = getCmd(obj)
            %GETCMD 获取当前保持的左右轮目标角速度。
            %   cmd = obj.getCmd() 返回 2x1 [left_wheel_cmd; right_wheel_cmd]，单位为 rad/s。
            %   返回的是 sendCmd 限幅后实际写入 Cmd 的值，并会由后续 step 持续使用直至下一次 sendCmd 或 reset。
            cmd = [obj.Cmd.left; obj.Cmd.right];
        end

        % ---------- 1.3 获取位姿 ----------
        function pose = getPose(obj)
            %GETPOSE 获取驱动轴中点的世界坐标位姿。
            %   pose = obj.getPose() 返回 3x1 [px; py; theta]，单位为 [m; m; rad]。
            %   theta 默认累计，启用 wrap_heading 后会在每次 step 结束时归一化到 [-pi, pi)。
            pose = obj.States(1:3);
        end

        function velocity = getVel(obj)
            %GETVEL 获取车体前向线速度及偏航角速度。
            %   velocity = obj.getVel() 返回 2x1 [v; omega]，单位为 [m/s; rad/s]，并根据实际轮速计算。
            %   v 为车体前向有符号速度，omega 逆时针为正，两者都不是目标指令值。
            velocity = obj.wheel2body(obj.getWheelSpeed());
        end

        % ---------- 1.4 获取速度 ----------
        function pos_derivative = getPoseDot(obj)
            %GETPOSEDOT 获取世界坐标系下的瞬时位姿变化率。
            %   pos_derivative = obj.getPoseDot() 返回 3x1 [px_dot; py_dot; theta_dot]，单位为 [m/s; m/s; rad/s]。
            %   平移速度由车体前向速度旋转得到，theta_dot 是物理角速度，不包含航向角归一化时的数值跳变。
            u = obj.getVel();
            theta = obj.States(3);
            g = [cos(theta),0;sin(theta),0;0,1];
            pos_derivative = g * u;
        end

        % ---------- 1.5 获取轮速 ----------
        function wheel_speed = getWheelSpeed(obj)
            %GETWHEELSPEED 获取左右车轮的实际角速度。
            %   wheel_speed = obj.getWheelSpeed() 返回 2x1 [left_wheel_speed; right_wheel_speed]，单位为 rad/s。
            %   一阶响应可能使实际轮速与 Cmd 中保存的目标值不同。
            wheel_speed = obj.States([5; 7]);
        end

        % ---------- 1.6 获取轮角 ----------
        function wheel_angle = getWheelAngle(obj)
            %GETWHEELANGLE 获取左右车轮的累计转角。
            %   wheel_angle = obj.getWheelAngle() 返回 2x1 [left_wheel_angle; right_wheel_angle]，单位为 rad。
            %   转角由实际轮速积分得到，并且不执行模 2*pi 归一化。
            wheel_angle = obj.States([4; 6]);
        end

        % ---------- 1.7 获取物理参数 ----------
        function params = getParams(obj)
            %GETPARAMS 获取机器人当前采用的物理参数。
            %   params = obj.getParams() 返回 Params 结构体的副本，可供图形渲染、数据记录和外部计算使用。
            %   返回值包含构造函数规范化后的参数，以及零时间常数替换后的实际值。
            %   修改返回的结构体不会改变对象内部参数。
            params = obj.Params;
        end

        % =============== 2. 外部设置接口 ===============

        % ---------- 2.1 设置数值积分方法 ----------
        function setSolutionMethod(obj, solution_method)
            %SETSOLUTIONMETHOD 设置后续 step 使用的固定步长积分方法。
            %   obj.setSolutionMethod(solution_method) 接受字符行向量或字符串标量。
            %   'euler' 表示显式欧拉，'RK4' 表示经典四阶 Runge-Kutta，名称不区分大小写。
            %   无效输入会报错，并保持原有配置不变。
            is_text_scalar = (ischar(solution_method) && isrow(solution_method)) || ...
                (isstring(solution_method) && isscalar(solution_method));
            if ~is_text_scalar
                error('wheel_robot:InvalidSolutionMethod', ...
                    'solution_method 必须是字符向量或字符串标量。');
            end
            if ismissing(string(solution_method))
                error('wheel_robot:InvalidSolutionMethod', ...
                    'solution_method 不能为缺失字符串。');
            end

            switch lower(string(solution_method))
                case "euler"
                    obj.Config.solution_method = 'euler';
                case "rk4"
                    obj.Config.solution_method = 'RK4';
                otherwise
                    error('wheel_robot:InvalidSolutionMethod', ...
                        '不支持的求解方法：%s。可选值为 euler 或 RK4。', ...
                        string(solution_method));
            end
            obj.StepSizeWarningActive = false;
        end

        % ---------- 2.2 设置航向角归一化 ----------
        function setWrapHeading(obj, wrap_heading)
            %SETWRAPHEADING 设置是否在积分后归一化航向角。
            %   obj.setWrapHeading(true/false) 仅接受逻辑标量，true 表示每次 step 后将 theta 映射到 [-pi, pi)。
            %   本方法不立即更改状态；角度归一化会丢失累计旋转圈数，之后关闭选项也不会恢复已丢失的圈数。
            validateattributes(wrap_heading, {'logical'}, {'scalar'}, ...
                mfilename, 'wrap_heading');
            obj.Config.wrap_heading = wrap_heading;
        end

        % ---------- 2.3 设置轮速限幅警告 ----------
        function setWarnOnSaturation(obj, warn_on_saturation)
            %SETWARNONSATURATION 设置目标轮速限幅时是否发出警告。
            %   obj.setWarnOnSaturation(true/false) 仅接受逻辑标量。
            %   开启后，每次 sendCmd 遇到越界指令都会发出一次警告。
            %   关闭警告不影响限幅，本方法也不改变当前保持的 Cmd。
            validateattributes(warn_on_saturation, {'logical'}, {'scalar'}, ...
                mfilename, 'warn_on_saturation');
            obj.Config.warn_on_saturation = warn_on_saturation;
        end

        % =============== 3. 外部控制接口 ===============

        % ---------- 发送控制指令 ----------
        function sendCmd(obj,left_wheel_cmd,right_wheel_cmd)
            %SENDCMD 限幅并保存左右车轮的目标角速度。
            %   obj.sendCmd(left_wheel_cmd, right_wheel_cmd) 接受两个有限实数标量，单位为 rad/s。
            %   各轮按对应 maxWheelSpeed 对称限幅，是否警告由 Config.warn_on_saturation 决定。
            %   调用只更新 Cmd，不会直接改变实际轮速或位姿。
            %   下一次 sendCmd 到来前，每次 step 都使用最近保存的指令，实现零阶保持，控制更新时刻由外部循环安排。
            validateattributes(left_wheel_cmd, {'numeric'}, ...
                {'real','finite','scalar'}, mfilename, 'left_wheel_cmd');
            validateattributes(right_wheel_cmd, {'numeric'}, ...
                {'real','finite','scalar'}, mfilename, 'right_wheel_cmd');
            left_wheel_cmd = double(left_wheel_cmd);
            right_wheel_cmd = double(right_wheel_cmd);

            applied_left_cmd = min(max(left_wheel_cmd, ...
                -obj.Params.maxWheelSpeed(1)), obj.Params.maxWheelSpeed(1));
            applied_right_cmd = min(max(right_wheel_cmd, ...
                -obj.Params.maxWheelSpeed(2)), obj.Params.maxWheelSpeed(2));

            if obj.Config.warn_on_saturation && ...
                    (applied_left_cmd ~= left_wheel_cmd || ...
                     applied_right_cmd ~= right_wheel_cmd)
                warning('wheel_robot:CommandSaturated', ...
                    ['轮速指令发生限幅：输入 [%.6g, %.6g] rad/s，' ...
                     '限幅后目标 [%.6g, %.6g] rad/s。'], ...
                    left_wheel_cmd, right_wheel_cmd, ...
                    applied_left_cmd, applied_right_cmd);
            end

            obj.Cmd.left = applied_left_cmd;
            obj.Cmd.right = applied_right_cmd;
        end
    
        % =============== 4. 仿真接口 ===============

        % ---------- 4.1 一步仿真 ----------
        function step(obj,dt,t)
            %STEP 使用当前保持的目标轮速，将状态向前积分一步。
            %   obj.step(dt, t) 中 dt 为正的有限仿真步长 [s]，t 为本步起始时刻 [s]。
            %   t 可省略或传 []，此时按 0 处理；当前方程不显含时间，因此 t 不影响结果，时间也不会在类内累计。
            %   本方法更新七维 States，不修改 Cmd；RK4 的四次导数计算均使用同一目标指令和各自的中间状态。
            %   启用 wrap_heading 时，仅在完整积分步结束后归一化航向角。
            %   步长由外部提供，并应充分小于最小电机时间常数。
            %   对一阶衰减模态，欧拉法的线性稳定条件为 dt < 2*T，RK4 约为 dt < 2.785*T。
            %   数值稳定并不代表积分精度足够；max(dt/T) 大于 0.1 时会在进入该区间时警告一次。
            validateattributes(dt, {'numeric'}, ...
                {'real','finite','scalar','positive'}, mfilename, 'dt');
            dt = double(dt);
            if nargin < 3 || isempty(t)
                t = 0;
            end
            validateattributes(t, {'numeric'}, ...
                {'real','finite','scalar'}, mfilename, 't');
            t = double(t);

            time_constant_ratio = max(dt ./ obj.Params.motorTimeConstant);
            switch obj.Config.solution_method
                case 'euler'
                    stability_limit = 2;
                case 'RK4'
                    stability_limit = 2.785;
                otherwise
                    stability_limit = NaN;
            end
            if time_constant_ratio > 0.1
                if ~obj.StepSizeWarningActive
                    warning('wheel_robot:LargeStepSize', ...
                        ['当前 max(dt/T) = %.6g，超过推荐值 0.1，' ...
                         '积分精度可能不足；%s 的稳定性参考上限约为 %.4g。' ...
                         '请减小仿真步长 dt，或不要将 motorTimeConstant 设置为 0。'], ...
                        time_constant_ratio, obj.Config.solution_method, ...
                        stability_limit);
                end
                obj.StepSizeWarningActive = true;
            else
                obj.StepSizeWarningActive = false;
            end

            c = [obj.Cmd.left; obj.Cmd.right];
            z = obj.States;

            switch obj.Config.solution_method
                case 'euler'
                    obj.States = z + obj.stateDerivative(z,c,t)*dt;
                case 'RK4'
                    K1 = obj.stateDerivative(z,c,t);
                    K2 = obj.stateDerivative(z+K1*dt/2,c,t+dt/2);
                    K3 = obj.stateDerivative(z+K2*dt/2,c,t+dt/2);
                    K4 = obj.stateDerivative(z+K3*dt,c,t+dt);
                    obj.States = z+dt*(K1+2*K2+2*K3+K4)/6;
                otherwise
                    error('wheel_robot:UnknownSolutionMethod', ...
                        '未知的求解方法：%s', obj.Config.solution_method);
            end

            if obj.Config.wrap_heading
                obj.States(3) = mod(obj.States(3) + pi, 2*pi) - pi;
            end
        end

        % =============== 5. 工具接口 ===============

        % ---------- 5.1 车体速度转换为车轮角速度 ----------
        function wheel_speed = body2wheel(obj, body_velocity)
            %BODY2WHEEL 将 [线速度; 角速度] 转换为 [左轮; 右轮] 角速度。
            %   wheel_speed = obj.body2wheel(body_velocity)，输入为两元素行向量或列向量 [v; omega]，单位为 [m/s; rad/s]。
            %   返回 2x1 左右轮目标角速度 [rad/s]，使用当前物理参数计算。
            %   本方法不修改对象且不执行限幅，发送结果时由 sendCmd 限幅。
            validateattributes(body_velocity, {'numeric'}, ...
                {'real','finite','vector','numel',2}, ...
                mfilename, 'body_velocity');
            wheel_speed = obj.kin_inv() * double(body_velocity(:));
        end

        % ---------- 5.2 车轮角速度转换为车体速度 ----------
        function body_velocity = wheel2body(obj, wheel_speed)
            %WHEEL2BODY 将 [左轮; 右轮] 角速度转换为 [线速度; 角速度]。
            %   body_velocity = obj.wheel2body(wheel_speed)，输入为两元素行向量或列向量 [speed_L; speed_R]，单位为 rad/s。
            %   返回 2x1 [v; omega]，单位为 [m/s; rad/s]，线速度沿车体前向且角速度逆时针为正。
            %   本方法不读取或修改机器人的运动状态。
            validateattributes(wheel_speed, {'numeric'}, ...
                {'real','finite','vector','numel',2}, ...
                mfilename, 'wheel_speed');
            body_velocity = obj.kin_fwd() * double(wheel_speed(:));
        end

    end

    
    %% 内部方法：便于计算
    methods (Access = private)
        function Params = validateParams(~, Params)
            %VALIDATEPARAMS 校验并规范化构造函数接收的物理参数。
            %   Params = obj.validateParams(Params) 要求输入为标量结构体。
            %   本方法检查必需字段、维度、有限性和物理取值范围，并将必需数值字段转成 double。
            %   双轮标量扩展为 2x1，向量转成列向量，额外字段会保留。
            %   零时间常数会在警告后替换为 1e-3 s，本方法不读取或修改对象属性。
            validateattributes(Params, {'struct'}, {'scalar'}, ...
                mfilename, 'Params');
            names = {'wheelRadius', 'trackWidth', 'motorTimeConstant', ...
                'maxWheelSpeed', 'bodySize', 'wheelWidth', 'axleOffset'};
            counts = [2, 1, 2, 2, 3, 2, 1];
            for index = 1:numel(names)
                name = names{index};
                if ~isfield(Params, name)
                    error('wheel_robot:MissingParameter', ...
                        'Params 缺少必需字段：%s。', name);
                end
                value = Params.(name);
                validateattributes(value, {'numeric'}, ...
                    {'real','finite','vector','nonempty'}, mfilename, name);
                value = double(value(:));
                if counts(index) == 2 && isscalar(value)
                    value = repmat(value, 2, 1);
                end
                validateattributes(value, {'double'}, ...
                    {'numel',counts(index)}, mfilename, name);
                if strcmp(name, 'motorTimeConstant')
                    validateattributes(value, {'double'}, ...
                        {'nonnegative'}, mfilename, name);
                elseif ~strcmp(name, 'axleOffset')
                    validateattributes(value, {'double'}, ...
                        {'positive'}, mfilename, name);
                end
                Params.(name) = value;
            end

            zero_time_constant = Params.motorTimeConstant == 0;
            if any(zero_time_constant)
                warning('wheel_robot:ZeroMotorTimeConstant', ...
                    ['已将 motorTimeConstant 设置为 1e-3 s，' ...
                     '用于近似无惯性的理想执行器。']);
                Params.motorTimeConstant(zero_time_constant) = 1e-3;
            end
        end

        function dz = stateDerivative(obj, z, u, t) %#ok<INUSD>
            %STATEDERIVATIVE 计算给定状态和轮速指令对应的连续状态导数。
            %   dz = obj.stateDerivative(z, u, t) 返回与七维 States 排列一致的状态导数。
            %   z 是七维状态，u 是 2x1 左右轮目标角速度，时间参数预留给后续时变模型使用。
            L = obj.Params.trackWidth;                 % 轮距
            r_L = obj.Params.wheelRadius(1);           % 左轮半径
            r_R = obj.Params.wheelRadius(2);           % 右轮半径
            T_L = obj.Params.motorTimeConstant(1);     % 左电机时间常数
            T_R = obj.Params.motorTimeConstant(2);     % 右电机时间常数

            dz = [(r_L*z(5) + r_R*z(7))/2 * cos(z(3)); ...
                  (r_L*z(5) + r_R*z(7))/2 * sin(z(3)); ...
                  (r_R*z(7) - r_L*z(5))/L; ...
                  z(5); ...
                  (u(1) - z(5))/T_L; ...
                  z(7); ...
                  (u(2) - z(7))/T_R];
        end

        function Mr = kin_fwd(obj)
            %KIN_FWD 构造左右轮速到车体速度的正运动学矩阵。
            %   Mr = obj.kin_fwd() 返回 2x2 矩阵，满足 [v; omega] = Mr * [speed_L; speed_R]。
            %   本矩阵支持左右轮半径不同，轮半径和轮距由构造函数保证为正数。
            r_L = obj.Params.wheelRadius(1);    % 左轮半径
            r_R = obj.Params.wheelRadius(2);    % 右轮半径
            L = obj.Params.trackWidth;          % 轮距
            Mr = [r_L/2, r_R/2; -r_L/L, r_R/L];

        end

        function Mr_inv = kin_inv(obj)
            %KIN_INV 构造车体速度到左右轮速的逆运动学矩阵。
            %   Mr_inv = obj.kin_inv() 返回 2x2 解析逆矩阵，满足 [speed_L; speed_R] = Mr_inv * [v; omega]。
            %   该矩阵与 kin_fwd 的轮序和正方向一致，不执行数值求逆或限幅。
            r_L = obj.Params.wheelRadius(1);    % 左轮半径
            r_R = obj.Params.wheelRadius(2);    % 右轮半径
            L = obj.Params.trackWidth;          % 轮距
            Mr_inv = [1/r_L, -L/(2*r_L);
                      1/r_R,  L/(2*r_R)];
        end
        
    end
end
