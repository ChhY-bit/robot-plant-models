classdef ackermann_robot < handle
    %ACKERMANN_ROBOT 带一阶执行器响应的阿克曼机器人仿真对象。
    %   本模型采用前轮转向、后轮驱动结构，并假设平面纯滚动、
    %   各车轮不侧滑且四个车轮的有效滚动半径相同。
    %   位姿参考点为后轮轴中点，theta 从世界坐标系 x 轴起算且
    %   逆时针为正。虚拟转角为正表示左转，虚拟轮速为正表示前进。
    %   动态状态为 [px; py; theta; virtual_steering; virtual_wheel_speed]。
    %   左右前轮转角和四个实体轮速由虚拟状态实时计算，不是独立
    %   动态状态，也不参与数值积分。
    %   长度、时间、角度和角速度的单位分别为 m、s、rad 和 rad/s。
    %   通过 sendCmd 更新并保持虚拟执行器指令，通过 step 推进连续状态。
    %   本类为 handle 类，赋值给另一变量后，两个变量引用同一对象。

    properties (Access = private)
        States
            % 状态为 5x1 double，排列为：
            % [px; py; theta; virtual_steering; virtual_wheel_speed]。
            % 单位依次为 [m; m; rad; rad; rad/s]。
            % 航向角是否归一化由 Config 控制；虚拟转角和轮速
            % 分别按各自的一阶执行器动态响应。
        Params
            % wheelRadius 是四轮共用的有效滚动半径 [m]。
            % wheelBase 是前后轮轴中心线间距，trackWidth 是左右轮距 [m]。
            % wheelTimeConstant 和 steeringTimeConstant 分别是虚拟轮速
            % 与虚拟转角的一阶时间常数 [s]。
            % maxPhysicalWheelSpeed 是任一实体轮的转速绝对值上限 [rad/s]。
            % maxPhysicalSteeringAngle 是任一前轮的转角绝对值上限 [rad]。
            % bodySize、wheelWidth 和 rearAxleOffset 是几何显示参数，
            % 当前不参与运动方程。
        Cmd
            % 2x1 double，排列为：
            % [virtual_steering_cmd; virtual_wheel_speed_cmd]。
            % sendCmd 写入限幅后的指令，step 持续读取该值，
            % 两个指令的初值均为 0。
        Config
            % solution_method 指定 'euler' 或 'RK4'，默认值为 'RK4'。
            % wrap_heading 指定积分后是否归一化 theta，默认值为 false。
            % warn_on_saturation 指定指令限幅时是否警告，默认值为 true。
        StepSizeWarningActive
            % 标记上一步是否处于步长比值警告区间，用于避免
            % 连续 step 重复发出相同警告。
    end

    properties (Access = public)
        Metadata
            % 描述信息结构体，不参与计算，可添加自定义字段。
            % Name 保存对象名称，Number 保存对象编号，
            % Description 保存对象说明。
    end

    %% 外部方法：供使用
    methods (Access = public)
        function obj = ackermann_robot(Params, Ini_States, Metadata)
            %ACKERMANN_ROBOT 创建并初始化阿克曼机器人。
            %   obj = ackermann_robot(Params, ini_states, Metadata) 创建对象。
            %   三个入参均可省略或传 []，默认值依次为
            %   load_ackermann_params() 的结果、五维零状态和带默认描述字段的结构体。
            %   Params 必须是包含所需物理字段的标量结构体，构造函数会将
            %   数值字段规范为 double 标量或列向量。
            %   ini_states 接受五元素行向量或列向量，顺序见 States 属性说明。
            %   初始虚拟转角必须满足 |delta| < atan(2*wheelBase/trackWidth)，
            %   以保证 Ackermann 实体轮映射位于正常几何域。
            %   初始虚拟转角与轮速还必须位于 getCmdLimits 返回的保守瞬态范围内，
            %   允许等于边界；超限时报错并提示允许范围，不自动裁剪。
            %   任一时间常数为零时会发出警告并替换为 1e-3 s。
            %   默认指令为零，因此初始非零虚拟执行器状态会逐渐衰减。
            if nargin < 1 || isempty(Params)
                class_dir = fileparts(mfilename('fullpath'));
                project_dir = fileparts(class_dir);
                utils_dir = fullfile(project_dir, 'utils');
                utils_on_path = any(strcmpi(strsplit(path, pathsep), utils_dir));
                if ~utils_on_path
                    addpath(utils_dir);
                    path_cleanup = onCleanup(@() rmpath(utils_dir));
                end
                Params = load_ackermann_params();
            end
            Params = obj.validateParams(Params);

            if nargin < 2 || isempty(Ini_States)
                Ini_States = zeros(5, 1);
            end
            if nargin < 3 || isempty(Metadata)
                Metadata = struct();
            end
            validateattributes(Metadata, {'struct'}, {'scalar'}, mfilename, 'Metadata');
            if ~isfield(Metadata, 'Name'), Metadata.Name = 'ackermann_robot'; end
            if ~isfield(Metadata, 'Number'), Metadata.Number = []; end
            if ~isfield(Metadata, 'Description'), Metadata.Description = 'none'; end

            obj.Params = Params;
            obj.Metadata = Metadata;
            obj.Config.solution_method = 'RK4';
            obj.Config.wrap_heading = false;
            obj.Config.warn_on_saturation = true;
            obj.reset(Ini_States);
        end

        function reset(obj, ini_states)
            %RESET 复位状态并清零当前保持的指令，其他设置不变。
            %   obj.reset() 将五维状态和两个虚拟执行器指令全部复位为零。
            %   obj.reset(ini_states) 将状态复位为给定的五元素行向量或列向量，
            %   并将当前保持的虚拟转角和轮速指令清零。
            %   初始虚拟转角与轮速必须满足 getCmdLimits 返回的对称范围，
            %   超限时抛出 ackermann_robot:InvalidInitialState，不自动裁剪。
            %   本方法保留 Params、Metadata 和 Config。校验失败时，
            %   对象原有状态和指令均不会改变。
            if nargin < 2 || isempty(ini_states)
                ini_states = zeros(5, 1);
            end
            obj.States = obj.validateInitialStates(ini_states);
            obj.Cmd = zeros(2, 1);
            obj.StepSizeWarningActive = false;
        end

        % =============== 1. 外部获取接口 ===============

        % ---------- 1.1 获取完整状态 ----------
        function states = getStates(obj)
            %GETSTATES 获取机器人的完整五维动态状态。
            %   states = obj.getStates() 返回 5x1 列向量
            %   [px; py; theta; virtual_steering; virtual_wheel_speed]。
            %   单位依次为 [m; m; rad; rad; rad/s]，修改返回值不会改变对象内部状态。
            states = obj.States;
        end

        % ---------- 1.2 获取当前指令 ----------
        function cmd = getCmd(obj)
            %GETCMD 获取当前保持的虚拟执行器指令。
            %   cmd = obj.getCmd() 返回 2x1
            %   [virtual_steering_cmd; virtual_wheel_speed_cmd]，单位为 [rad; rad/s]。
            %   返回 sendCmd 限幅后实际写入的值，后续 step 持续使用该值，
            %   直至下一次 sendCmd 或 reset。
            cmd = obj.Cmd;
        end

        % ---------- 1.3 获取位姿 ----------
        function pose = getPose(obj)
            %GETPOSE 获取后轮轴中点的世界坐标位姿。
            %   pose = obj.getPose() 返回 3x1 [px; py; theta]，
            %   单位为 [m; m; rad]。theta 默认累计，启用 wrap_heading 后会在
            %   每次 step 结束时归一化到 [-pi, pi)。
            pose = obj.States(1:3);
        end

        % ---------- 1.4 获取车体速度 ----------
        function velocity = getVel(obj)
            %GETVEL 获取后轮轴中点的车体速度。
            %   velocity = obj.getVel() 返回 2x1 [v; omega]，
            %   单位为 [m/s; rad/s]，并根据实际虚拟执行器状态计算。
            %   v 为车体前向有符号速度，omega 逆时针为正，两者都不是指令值。
            virtual_state = [obj.getVirtualSteeringAngle(); ...
                             obj.getVirtualWheelSpeed()];
            velocity = obj.virtual2body(virtual_state);
        end

        % ---------- 1.5 获取位姿变化率 ----------
        function pose_derivative = getPoseDot(obj)
            %GETPOSEDOT 获取世界坐标系下的瞬时位姿变化率。
            %   pose_derivative = obj.getPoseDot() 返回 3x1
            %   [px_dot; py_dot; theta_dot]，单位为 [m/s; m/s; rad/s]。
            %   平移速度由车体前向速度旋转到世界坐标系，theta_dot 是
            %   物理偏航角速度，不包含航向角归一化时的数值跳变。
            velocity = obj.getVel();
            theta = obj.States(3);
            pose_derivative = [cos(theta), 0; sin(theta), 0; 0, 1] * velocity;
        end

        % ---------- 1.6 获取虚拟转角 ----------
        function value = getVirtualSteeringAngle(obj)
            %GETVIRTUALSTEERINGANGLE 获取虚拟前轮的实际转角。
            %   value = obj.getVirtualSteeringAngle() 返回标量转角 [rad]。
            %   正值表示左转；一阶响应可能使实际转角与 Cmd 中的目标值不同。
            value = obj.States(4);
        end

        % ---------- 1.7 获取虚拟轮速 ----------
        function value = getVirtualWheelSpeed(obj)
            %GETVIRTUALWHEELSPEED 获取虚拟车轮的实际角速度。
            %   value = obj.getVirtualWheelSpeed() 返回标量轮速 [rad/s]。
            %   正值表示前进；一阶响应可能使实际轮速与 Cmd 中的目标值不同。
            value = obj.States(5);
        end

        % ---------- 1.8 获取实体前轮转角 ----------
        function value = getPhysicalSteeringAngle(obj)
            %GETPHYSICALSTEERINGANGLE 获取左右实体前轮转角。
            %   value = obj.getPhysicalSteeringAngle() 返回 2x1
            %   [left_front; right_front]，单位为 rad。
            %   转角根据当前虚拟转角和 Ackermann 几何关系实时计算，
            %   它们不是独立状态，也不会被分别限幅。
            physical_values = obj.physicalWheelMap(obj.States);
            value = physical_values(1:2);
        end

        % ---------- 1.9 获取实体轮速 ----------
        function value = getPhysicalWheelSpeed(obj)
            %GETPHYSICALWHEELSPEED 获取四个实体车轮的角速度。
            %   value = obj.getPhysicalWheelSpeed() 返回 4x1
            %   [left_front; right_front; left_rear; right_rear]，单位为 rad/s。
            %   四轮速根据当前虚拟转角和虚拟轮速实时计算，
            %   正值表示车轮滚动方向对应车体前进。
            physical_values = obj.physicalWheelMap(obj.States);
            value = physical_values([5; 6; 3; 4]);
        end

        % ---------- 1.10 获取物理参数 ----------
        function params = getParams(obj)
            %GETPARAMS 获取机器人当前采用的物理参数。
            %   params = obj.getParams() 返回 Params 结构体的副本，
            %   可供图形渲染、数据记录和外部计算使用。
            %   返回值包含构造函数规范化后的参数，以及零时间常数
            %   替换后的实际值。修改返回结构体不会改变对象内部参数。
            params = obj.Params;
        end

        % ---------- 1.11 获取指令上限 ----------
        function limits = getCmdLimits(obj)
            %GETCMDLIMITS 获取 sendCmd 当前使用的对称指令上限。
            %   limits = obj.getCmdLimits() 返回 2x1
            %   [virtual_steering_limit; virtual_wheel_speed_limit]，单位为 [rad; rad/s]。
            %   sendCmd 将每个输入分别限制在对应的 [-limit, limit] 内。
            %   该方法只读取 Params，不修改状态或当前指令。
            limits = obj.commandLimits();
        end

        % =============== 2. 外部设置接口 ===============

        % ---------- 2.1 设置数值积分方法 ----------
        function setSolutionMethod(obj, solution_method)
            %SETSOLUTIONMETHOD 设置后续 step 使用的固定步长积分方法。
            %   obj.setSolutionMethod(solution_method) 接受字符行向量或字符串标量。
            %   'euler' 表示显式欧拉，'RK4' 表示经典四阶 Runge-Kutta，名称不区分大小写。
            %   无效输入会抛出 ackermann_robot:InvalidSolutionMethod，
            %   并保持原有求解方法不变。成功设置会重置步长警告状态。
            is_text_scalar = (ischar(solution_method) && isrow(solution_method)) || ...
                (isstring(solution_method) && isscalar(solution_method));
            if ~is_text_scalar || ismissing(string(solution_method))
                error('ackermann_robot:InvalidSolutionMethod', ...
                    'solution_method 必须是非缺失字符向量或字符串标量。');
            end
            switch lower(string(solution_method))
                case "euler"
                    obj.Config.solution_method = 'euler';
                case "rk4"
                    obj.Config.solution_method = 'RK4';
                otherwise
                    error('ackermann_robot:InvalidSolutionMethod', ...
                        '不支持的求解方法：%s。可选值为 euler 或 RK4。', ...
                        string(solution_method));
            end
            obj.StepSizeWarningActive = false;
        end

        % ---------- 2.2 设置航向角归一化 ----------
        function setWrapHeading(obj, wrap_heading)
            %SETWRAPHEADING 设置是否在积分后归一化航向角。
            %   obj.setWrapHeading(true/false) 仅接受逻辑标量。
            %   true 表示每次 step 后将 theta 映射到 [-pi, pi)。
            %   本方法不立即更改状态；角度归一化会丢失累计旋转圈数，
            %   之后关闭选项也不会恢复已丢失的圈数。
            validateattributes(wrap_heading, {'logical'}, {'scalar'}, ...
                mfilename, 'wrap_heading');
            obj.Config.wrap_heading = wrap_heading;
        end

        % ---------- 2.3 设置指令限幅警告 ----------
        function setWarnOnSaturation(obj, warn_on_saturation)
            %SETWARNONSATURATION 设置虚拟执行器指令限幅时是否警告。
            %   obj.setWarnOnSaturation(true/false) 仅接受逻辑标量。
            %   开启后，每次 sendCmd 遇到越界指令都会发出
            %   ackermann_robot:CommandSaturated 警告。
            %   关闭警告不影响限幅，也不会关闭零时间常数或大步长警告。
            validateattributes(warn_on_saturation, {'logical'}, {'scalar'}, ...
                mfilename, 'warn_on_saturation');
            obj.Config.warn_on_saturation = warn_on_saturation;
        end

        % =============== 3. 外部控制接口 ===============

        % ---------- 发送虚拟执行器指令 ----------
        function sendCmd(obj, steering_angle_cmd, wheel_speed_cmd)
            %SENDCMD 限幅并保持虚拟转角、虚拟轮速指令。
            %   obj.sendCmd(steering_angle_cmd, wheel_speed_cmd) 接受两个有限实数标量，
            %   单位分别为 rad 和 rad/s。转角为正表示左转，轮速为正表示前进。
            %   两个输入按 getCmdLimits() 返回的对称上限分别限幅，
            %   不分别裁剪左右前轮转角或四个实体轮速，以保持 Ackermann 几何关系。
            %   是否在限幅时警告由 Config.warn_on_saturation 决定。
            %   调用只更新 Cmd，不会直接改变实际执行器状态或位姿。
            %   下一次 sendCmd 到来前，每次 step 都使用最近保存的指令，
            %   实现零阶保持，控制更新时刻由外部循环安排。
            validateattributes(steering_angle_cmd, {'numeric'}, ...
                {'real','finite','scalar'}, mfilename, 'steering_angle_cmd');
            validateattributes(wheel_speed_cmd, {'numeric'}, ...
                {'real','finite','scalar'}, mfilename, 'wheel_speed_cmd');
            input_cmd = double([steering_angle_cmd; wheel_speed_cmd]);
            limits = obj.commandLimits();
            applied_cmd = min(max(input_cmd, -limits), limits);
            if obj.Config.warn_on_saturation && any(applied_cmd ~= input_cmd)
                warning('ackermann_robot:CommandSaturated', ...
                    ['指令发生限幅：输入 [%.6g rad, %.6g rad/s]，' ...
                     '限幅后 [%.6g rad, %.6g rad/s]。'], ...
                    input_cmd(1), input_cmd(2), applied_cmd(1), applied_cmd(2));
            end
            obj.Cmd = applied_cmd;
        end

        % =============== 4. 仿真接口 ===============

        % ---------- 4.1 一步仿真 ----------
        function step(obj, dt, t)
            %STEP 使用当前保持指令，将五维状态向前积分一步。
            %   obj.step(dt, t) 中 dt 为正的有限仿真步长 [s]，
            %   t 为本步起始时刻 [s]。t 可省略或传 []，此时按 0 处理。
            %   当前方程不显含时间，因此 t 不影响结果，时间也不会在类内累计。
            %   本方法更新五维 States，不修改 Cmd；RK4 的四次导数计算
            %   均使用同一保持指令和各自的中间状态。
            %   启用 wrap_heading 时，仅在完整积分步结束后归一化航向角。
            %   步长由外部提供，并应充分小于转向与轮速时间常数的较小者。
            %   对一阶衰减模态，欧拉法的线性稳定条件为 dt < 2*T，
            %   RK4 约为 dt < 2.785*T。数值稳定不代表积分精度充足。
            %   max(dt/T) 大于 0.1 时会在进入该区间时发出一次
            %   ackermann_robot:LargeStepSize 警告，连续大步长不会重复刷屏。
            validateattributes(dt, {'numeric'}, ...
                {'real','finite','scalar','positive'}, mfilename, 'dt');
            dt = double(dt);
            if nargin < 3 || isempty(t), t = 0; end
            validateattributes(t, {'numeric'}, ...
                {'real','finite','scalar'}, mfilename, 't');
            t = double(t);

            ratio = max(dt ./ [obj.Params.steeringTimeConstant; ...
                              obj.Params.wheelTimeConstant]);
            switch obj.Config.solution_method
                case 'euler', stability_limit = 2;
                case 'RK4', stability_limit = 2.785;
                otherwise, stability_limit = NaN;
            end
            if ratio > 0.1
                if ~obj.StepSizeWarningActive
                    warning('ackermann_robot:LargeStepSize', ...
                        ['当前 max(dt/T) = %.6g，超过推荐值 0.1，' ...
                         '积分精度可能不足；%s 的稳定性参考上限约为 %.4g。'], ...
                        ratio, obj.Config.solution_method, stability_limit);
                end
                obj.StepSizeWarningActive = true;
            else
                obj.StepSizeWarningActive = false;
            end

            z = obj.States;
            cmd = obj.Cmd;
            switch obj.Config.solution_method
                case 'euler'
                    obj.States = z + obj.stateDerivative(z, cmd, t)*dt;
                case 'RK4'
                    k1 = obj.stateDerivative(z, cmd, t);
                    k2 = obj.stateDerivative(z+k1*dt/2, cmd, t+dt/2);
                    k3 = obj.stateDerivative(z+k2*dt/2, cmd, t+dt/2);
                    k4 = obj.stateDerivative(z+k3*dt, cmd, t+dt);
                    obj.States = z + dt*(k1+2*k2+2*k3+k4)/6;
                otherwise
                    error('ackermann_robot:UnknownSolutionMethod', ...
                        '未知的求解方法：%s', obj.Config.solution_method);
            end
            if obj.Config.wrap_heading
                obj.States(3) = mod(obj.States(3)+pi, 2*pi)-pi;
            end
        end

        % =============== 5. 工具接口 ===============

        % ---------- 5.1 虚拟执行器状态转换为车体速度 ----------
        function body_velocity = virtual2body(obj, virtual_state)
            %VIRTUAL2BODY 将 [虚拟转角; 虚拟轮速] 转为 [v; omega]。
            %   body_velocity = obj.virtual2body(virtual_state) 接受两元素行向量
            %   或列向量 [virtual_steering; virtual_wheel_speed]，单位为 [rad; rad/s]。
            %   返回 2x1 [v; omega]，单位为 [m/s; rad/s]，其中 v 是后轮轴
            %   中点的前向速度，omega 逆时针为正。
            %   本方法只读取物理参数，不读取或修改运动状态，也不限幅。
            validateattributes(virtual_state, {'numeric'}, ...
                {'real','finite','vector','numel',2}, mfilename, 'virtual_state');
            virtual_state = double(virtual_state(:));
            linear_speed = obj.Params.wheelRadius*virtual_state(2);
            body_velocity = [linear_speed; ...
                linear_speed*tan(virtual_state(1))/obj.Params.wheelBase];
        end

        % ---------- 5.2 车体速度转换为虚拟执行器状态 ----------
        function virtual_state = body2virtual(obj, body_velocity)
            %BODY2VIRTUAL 将 [v; omega] 转为 [虚拟转角; 虚拟轮速]。
            %   virtual_state = obj.body2virtual(body_velocity) 接受两元素行向量或
            %   列向量 [v; omega]，单位为 [m/s; rad/s]。
            %   返回 2x1 [virtual_steering; virtual_wheel_speed]，单位为 [rad; rad/s]。
            %   [0; 0] 映射为零转角和零轮速。v = 0 但 omega ~= 0 表示原地
            %   转动，该运动无法由本 Ackermann 模型表达，因此会抛出
            %   ackermann_robot:InfeasibleBodyVelocity。
            %   本方法不修改对象且不执行指令限幅，发送返回值时
            %   仍由 sendCmd 进行限幅和保持。
            validateattributes(body_velocity, {'numeric'}, ...
                {'real','finite','vector','numel',2}, mfilename, 'body_velocity');
            body_velocity = double(body_velocity(:));
            linear_speed = body_velocity(1);
            yaw_rate = body_velocity(2);
            if linear_speed == 0
                if yaw_rate ~= 0
                    error('ackermann_robot:InfeasibleBodyVelocity', ...
                        '阿克曼模型不能表达线速度为零的原地转动。');
                end
                virtual_state = zeros(2, 1);
                return;
            end
            virtual_state = [atan(obj.Params.wheelBase*yaw_rate/linear_speed); ...
                             linear_speed/obj.Params.wheelRadius];
        end
    end

    %% 内部方法：校验、动力学与映射
    methods (Access = private)
        % =============== 6. 内部校验与模型计算 ===============

        % ---------- 6.1 初始状态校验 ----------
        function states = validateInitialStates(obj, states)
            %VALIDATEINITIALSTATES 校验并规范化五维初始状态。
            %   states 必须是五元素有限实数行向量或列向量，返回值统一为
            %   5x1 double。位置与航向角不设范围限制，任何状态均不自动裁剪。
            %   虚拟转角必须位于 Ackermann 输出映射的正常几何域
            %   |W*tan(delta)/(2L)| < 1 的主值分支内，等价于
            %   |delta| < atan(2L/W)。越界时抛出 ackermann_robot:InvalidInitialState。
            %   虚拟转角与轮速还必须位于 commandLimits 给出的保守瞬态矩形
            %   范围内（含边界）；超限时使用同一错误标识并提示允许范围。
            validateattributes(states, {'numeric'}, ...
                {'real','finite','vector','numel',5}, mfilename, 'ini_states');
            states = double(states(:));

            steering_domain = atan(2 * obj.Params.wheelBase / ...
                obj.Params.trackWidth);
            if abs(states(4)) >= steering_domain
                error('ackermann_robot:InvalidInitialState', ...
                    ['初始虚拟转角必须满足 |trackWidth*tan(delta)/' ...
                     '(2*wheelBase)| < 1；当前参数对应 |delta| < %.6g rad。'], ...
                    steering_domain);
            end

            limits = obj.commandLimits();
            if any(abs(states(4:5)) > limits)
                error('ackermann_robot:InvalidInitialState', ...
                    ['初始虚拟执行器状态超出保守瞬态范围：' ...
                     '虚拟转角允许范围为 [%.17g, %.17g] rad，' ...
                     '虚拟轮速允许范围为 [%.17g, %.17g] rad/s；' ...
                     '当前值为 [%.17g rad, %.17g rad/s]。'], ...
                    -limits(1), limits(1), -limits(2), limits(2), ...
                    states(4), states(5));
            end
        end

        % ---------- 6.2 物理参数校验 ----------
        function Params = validateParams(~, Params)
            %VALIDATEPARAMS 校验并规范化构造参数。
            %   Params 必须是标量结构体，且包含 names 中列出的全部字段。
            %   数值字段必须为有限实数，并会被转换为 double 列向量或标量。
            %   两个时间常数允许为零，零值会在警告后替换为 1e-3 s；
            %   其他尺寸和限值参数必须为正数，rearAxleOffset 可正可负。
            %   maxPhysicalSteeringAngle 还必须严格小于 pi/2。
            validateattributes(Params, {'struct'}, {'scalar'}, mfilename, 'Params');
            names = {'wheelRadius', 'wheelBase', 'trackWidth', ...
                'wheelTimeConstant', 'steeringTimeConstant', ...
                'maxPhysicalWheelSpeed', 'maxPhysicalSteeringAngle', ...
                'bodySize', 'wheelWidth', 'rearAxleOffset'};
            counts = [1, 1, 1, 1, 1, 1, 1, 3, 1, 1];
            for index = 1:numel(names)
                name = names{index};
                if ~isfield(Params, name)
                    error('ackermann_robot:MissingParameter', ...
                        'Params 缺少必需字段：%s。', name);
                end
                value = Params.(name);
                validateattributes(value, {'numeric'}, ...
                    {'real','finite','vector','nonempty'}, mfilename, name);
                value = double(value(:));
                validateattributes(value, {'double'}, ...
                    {'numel',counts(index)}, mfilename, name);
                if any(strcmp(name, {'wheelTimeConstant', 'steeringTimeConstant'}))
                    validateattributes(value, {'double'}, {'nonnegative'}, mfilename, name);
                elseif ~strcmp(name, 'rearAxleOffset')
                    validateattributes(value, {'double'}, {'positive'}, mfilename, name);
                end
                Params.(name) = value;
            end
            if Params.maxPhysicalSteeringAngle >= pi/2
                error('ackermann_robot:InvalidParameterValue', ...
                    '参数 maxPhysicalSteeringAngle 必须小于 pi/2 rad。');
            end
            zero_wheel = Params.wheelTimeConstant == 0;
            zero_steering = Params.steeringTimeConstant == 0;
            if zero_wheel || zero_steering
                warning('ackermann_robot:ZeroTimeConstant', ...
                    ['已将为零的 wheelTimeConstant 或 steeringTimeConstant ' ...
                     '设置为 1e-3 s，用于近似无惯性的理想执行器。']);
                if zero_wheel, Params.wheelTimeConstant = 1e-3; end
                if zero_steering, Params.steeringTimeConstant = 1e-3; end
            end
        end

        % ---------- 6.3 连续状态方程 ----------
        function dz = stateDerivative(obj, z, u, t) %#ok<INUSD>
            %STATEDERIVATIVE 计算五维连续状态导数。
            %   z 为当前或 RK4 中间状态，cmd 为本步保持的虚拟执行器指令。
            %   位姿导数采用后轮轴中点自行车模型，虚拟转角和轮速
            %   分别采用一阶执行器动态。参数 t 为求解器统一接口保留，
            %   当前自治方程不显式使用它。
            linear_speed = obj.Params.wheelRadius*z(5);
            dz = [linear_speed*cos(z(3)); ...
                  linear_speed*sin(z(3)); ...
                  linear_speed*tan(z(4))/obj.Params.wheelBase; ...
                  (u(1)-z(4))/obj.Params.steeringTimeConstant; ...
                  (u(2)-z(5))/obj.Params.wheelTimeConstant];
        end

        % ---------- 6.4 虚拟状态到实体车轮量的映射 ----------
        function physical_values = physicalWheelMap(obj, z)
            %PHYSICALWHEELMAP 根据虚拟状态计算六个实体车轮物理量。
            %   内部顺序为 [左前转角; 右前转角; 左后轮速; 右后轮速;
            %   左前轮速; 右前轮速]。
            %   前两项单位为 rad，后四项单位为 rad/s。转角映射使左右
            %   前轮共享同一瞬时转动中心，轮速映射使四轮符合纯滚动速度关系。
            %   该方法是纯代数映射，不保存输出，也不修改任何对象状态。
            tangent = tan(z(4));
            wheel_speed = z(5);
            lambda = obj.Params.trackWidth/(2*obj.Params.wheelBase);
            left_factor = 1-lambda*tangent;
            right_factor = 1+lambda*tangent;
            left_radicand = 1-2*lambda*tangent+(1+lambda^2)*tangent^2;
            right_radicand = 1+2*lambda*tangent+(1+lambda^2)*tangent^2;
            physical_values = [atan(tangent/left_factor); ...
                               atan(tangent/right_factor); ...
                               wheel_speed*left_factor; ...
                               wheel_speed*right_factor; ...
                               wheel_speed*sqrt(left_radicand); ...
                               wheel_speed*sqrt(right_radicand)];
        end

        % ---------- 6.5 虚拟执行器指令上限 ----------
        function limits = commandLimits(obj)
            %COMMANDLIMITS 计算文档 U_tr 中的保守瞬态矩形上限。
            %   返回 2x1 [virtual_steering_limit; virtual_wheel_speed_limit]。
            %   先将任一实体前轮的最大转角换算为对称虚拟转角上限，
            %   再在该转角范围内将任一实体轮的最大轮速换算为与转角
            %   解耦的虚拟轮速上限。本方法仅读取 Params，不修改对象。
            wheel_base = obj.Params.wheelBase;
            track_width = obj.Params.trackWidth;
            tangent_limit = tan(obj.Params.maxPhysicalSteeringAngle);
            steering_limit = atan(2*wheel_base*tangent_limit / ...
                (2*wheel_base+track_width*tangent_limit));
            lambda = track_width/(2*wheel_base);
            virtual_tangent_limit = tan(steering_limit);
            gamma = 1+2*lambda*virtual_tangent_limit + ...
                (1+lambda^2)*virtual_tangent_limit^2;
            wheel_speed_limit = obj.Params.maxPhysicalWheelSpeed/sqrt(gamma);
            limits = [steering_limit; wheel_speed_limit];
        end
    end
end
