classdef quadruple_tank < handle
    %QUADRUPLE_TANK 带输入限幅、水位边界和液位变化率扰动的四水箱模型。
    %   send 保持两台泵的流量，step 用 RK4 推进水位，reset 复位水位、输入和扰动。

    properties(Access=private)
        Params
            %   Params - 包含四水箱物理、约束与几何参数的标量结构体
            %       .TankArea_1      - 水箱 1 的恒定截面积 [m^2]
            %       .TankArea_2      - 水箱 2 的恒定截面积 [m^2]
            %       .TankArea_3      - 水箱 3 的恒定截面积 [m^2]
            %       .TankArea_4      - 水箱 4 的恒定截面积 [m^2]
            %       .HoleArea_1      - 水箱 1 底部出水孔的截面积 [m^2]
            %       .HoleArea_2      - 水箱 2 底部出水孔的截面积 [m^2]
            %       .HoleArea_3      - 水箱 3 底部出水孔的截面积 [m^2]
            %       .HoleArea_4      - 水箱 4 底部出水孔的截面积 [m^2]
            %       .g               - 重力加速度 [m/s^2]
            %       .gamma_1         - 泵 1 流向水箱 1 的比例，其余流向水箱 4 [0, 1]
            %       .gamma_2         - 泵 2 流向水箱 2 的比例，其余流向水箱 3 [0, 1]
            %       .TankHeight_1    - 水箱 1 的高度，即水位上限 [m]
            %       .TankHeight_2    - 水箱 2 的高度，即水位上限 [m]
            %       .TankHeight_3    - 水箱 3 的高度，即水位上限 [m]
            %       .TankHeight_4    - 水箱 4 的高度，即水位上限 [m]
            %       .PumpMaxFlow_1   - 泵 1 分流前的最大体积流量 [m^3/s]
            %       .PumpMaxFlow_2   - 泵 2 分流前的最大体积流量 [m^3/s]
            %       .PumpFlowSpeed_1 - 泵 1 在最大流量下出口总管的平均流速 [m/s]
            %       .PumpFlowSpeed_2 - 泵 2 在最大流量下出口总管的平均流速 [m/s]
            %   字段名与 YAML 一致，所有数值均为有限实数 double 标量；
            %   gamma_1、gamma_2 在 [0, 1] 内，其余参数均为正数。

        u1, u2              % 进水流量

        disturbance = [0;0;0;0]     % 扰动
    end

    properties(SetAccess=private)
        x1, x2, x3, x4      % 水位高度
    end

    methods
        function obj = quadruple_tank(Params, Ini_States)
            %QUADRUPLE_TANK 创建四水箱对象，参数与水位均可省略或传 []。
            %   Params 为含全部 19 个必需字段的标量结构体，默认从 YAML 加载。
            %   Ini_States 为四元素有限实数向量，顺序为水箱 1 至 4，单位 m。
            %   初始水位须位于 [0, 对应箱高]，默认全零；输入、扰动初值为零。
            if nargin < 1 || isempty(Params)
                Params = rpm.utils.load_quadruple_tank_params();
            end
            Params = obj.validateParams(Params);
            if nargin < 2 || isempty(Ini_States)
                Ini_States = [];
            end

            % ---------- 主逻辑  ----------
            obj.Params = Params;
            obj.reset(Ini_States);
        end

        function reset(obj, Ini_States)
            %RESET 复位水位并清零输入、扰动，保留参数及当前阀门分配比。
            %   省略 Ini_States 或传 [] 时水位归零，否则接受四元素行或列向量 [m]。
            %   各水位须在 [0, 对应箱高] 内，超限报错；校验失败时对象不变。
            if nargin < 2 || isempty(Ini_States)
                Ini_States = zeros(4, 1);
            end

            % ---------- 主逻辑  ----------
            Ini_States = obj.validateInitialStates(Ini_States);
            obj.x1 = Ini_States(1);
            obj.x2 = Ini_States(2);
            obj.x3 = Ini_States(3);
            obj.x4 = Ini_States(4);
            obj.u1 = 0;
            obj.u2 = 0;
            obj.disturbance = zeros(4, 1);
        end

        function send(obj,u1,u2)
            %SEND 设置并保持两台泵分流前的体积流量 [m^3/s]。
            %   输入须为有限实数非负标量，超过 PumpMaxFlow 时限幅。
            %   两个输入均校验通过后才更新对象；非法输入被拒绝时保留原值。
            [u1, u2] = obj.validateAndLimitInput(u1, u2);

            % ---------- 主逻辑  ----------
            obj.u1 = u1;
            obj.u2 = u2;
        end

        function step(obj,dt,t)
            %STEP 使用保持的输入和扰动，以 RK4 推进四个水位一个积分步。
            %   dt 为有限实数正标量步长 [s]，t 为有限实数标量起始时间 [s]。
            %   两者均为必填参数，规范为 double；不存储或累加仿真时钟。
            %   步末水位截断至 [0, 对应箱高]，结果通过 x1 至 x4 读取。
            [dt, t] = obj.validateStepArguments(dt, t);
            % ---------- 主逻辑  ----------
            c = [obj.u1; obj.u2];
            z = [obj.x1;obj.x2;obj.x3;obj.x4];

            K1 = obj.stateDerivative(z,c,t);
            K2 = obj.stateDerivative(z+K1*dt/2,c,t+dt/2);
            K3 = obj.stateDerivative(z+K2*dt/2,c,t+dt/2);
            K4 = obj.stateDerivative(z+K3*dt,c,t+dt);

            % 边界位置限幅
            States = obj.limitStates(z+dt*(K1+2*K2+2*K3+K4)/6);

            obj.x1 = States(1);
            obj.x2 = States(2);
            obj.x3 = States(3);
            obj.x4 = States(4);
        end

        function setValve(obj,gamma_1,gamma_2)
            %SETVALVE 设置两台泵的分流比例，均须为 [0, 1] 内的有限实数标量。
            %   两个比例均校验通过后更新 Params，不改变水位、输入和扰动。
            [gamma_1, gamma_2] = obj.validateValve(gamma_1, gamma_2);

            % ---------- 主逻辑  ----------
            obj.Params.gamma_1 = gamma_1;
            obj.Params.gamma_2 = gamma_2;
        end

        function addDisturbance(obj,d)
            %ADDDISTURBANCE 替换并保持四个水箱的液位变化率扰动 [m/s]。
            %   d 为四元素有限实数行或列向量，允许正负，规范为 4x1 double。
            %   扰动直接加到导数，不除以面积；传零向量可清除，非法输入不改变原值。
            d = obj.validateDisturbance(d);

            % ---------- 主逻辑  ----------
            obj.disturbance = d;
        end

    end

    methods(Access = private)
        function [dt, t] = validateStepArguments(~, dt, t)
            %VALIDATESTEPARGUMENTS 校验步长和起始时间并转为 double，不修改对象。
            validateattributes(dt, {'numeric'}, ...
                {'real', 'finite', 'scalar', 'positive'}, mfilename, 'dt');
            validateattributes(t, {'numeric'}, ...
                {'real', 'finite', 'scalar'}, mfilename, 't');
            dt = double(dt);
            t = double(t);
        end

        function States = limitStates(obj, States)
            %LIMITSTATES 将积分后的水位逐元素截断至 [0, 对应箱高]。
            %   输入为内部积分得到的 4x1 水位向量，不修改对象。
            ub = [obj.Params.TankHeight_1;
                  obj.Params.TankHeight_2;
                  obj.Params.TankHeight_3;
                  obj.Params.TankHeight_4];
            States = min(max(States, 0), ub);
        end

        function [gamma_1, gamma_2] = validateValve(~, gamma_1, gamma_2)
            %VALIDATEVALVE 校验两个分配比并规范为 double 标量，不修改对象。
            validateattributes(gamma_1, {'numeric'}, ...
                {'real', 'finite', 'scalar', '>=', 0, '<=', 1}, ...
                mfilename, 'gamma_1');
            validateattributes(gamma_2, {'numeric'}, ...
                {'real', 'finite', 'scalar', '>=', 0, '<=', 1}, ...
                mfilename, 'gamma_2');
            gamma_1 = double(gamma_1);
            gamma_2 = double(gamma_2);
        end

        function d = validateDisturbance(~, d)
            %VALIDATEDISTURBANCE 校验扰动并规范为 4x1 double，不修改对象。
            validateattributes(d, {'numeric'}, ...
                {'real', 'finite', 'vector', 'numel', 4}, ...
                mfilename, 'd');
            d = double(d(:));
        end

        function Ini_States = validateInitialStates(obj, Ini_States)
            %VALIDATEINITIALSTATES 校验水位范围并规范为 4x1 double，不修改对象。
            validateattributes(Ini_States, {'numeric'}, ...
                {'real', 'finite', 'vector', 'numel', 4, 'nonnegative'}, ...
                mfilename, 'Ini_States');
            Ini_States = double(Ini_States(:));
            tank_heights = [obj.Params.TankHeight_1; obj.Params.TankHeight_2; ...
                            obj.Params.TankHeight_3; obj.Params.TankHeight_4];
            invalid_index = find(Ini_States > tank_heights, 1);
            if ~isempty(invalid_index)
                error('quadruple_tank:InvalidInitialState', ...
                    '水箱 %d 的初始水位为 %g m，允许范围为 [0, %g] m。', ...
                    invalid_index, Ini_States(invalid_index), tank_heights(invalid_index));
            end
        end

        function [u1, u2] = validateAndLimitInput(obj, u1, u2)
            %VALIDATEANDLIMITINPUT 校验两个输入并按泵最大流量限幅，不修改对象。
            validateattributes(u1, {'numeric'}, ...
                {'real', 'finite', 'scalar', 'nonnegative'}, mfilename, 'u1');
            validateattributes(u2, {'numeric'}, ...
                {'real', 'finite', 'scalar', 'nonnegative'}, mfilename, 'u2');
            u1 = min(double(u1), obj.Params.PumpMaxFlow_1);
            u2 = min(double(u2), obj.Params.PumpMaxFlow_2);
        end

        function Params = validateParams(~, Params)
            %VALIDATEPARAMS 校验直接传入的参数，防止绕过 YAML 加载器的检查。
            validateattributes(Params, {'struct'}, {'scalar'}, mfilename, 'Params');
            positive_fields = ["TankArea_1", "TankArea_2", "TankArea_3", "TankArea_4", ...
                "HoleArea_1", "HoleArea_2", "HoleArea_3", "HoleArea_4", "g", ...
                "TankHeight_1", "TankHeight_2", "TankHeight_3", "TankHeight_4", ...
                "PumpMaxFlow_1", "PumpMaxFlow_2", "PumpFlowSpeed_1", "PumpFlowSpeed_2"];
            valve_fields = ["gamma_1", "gamma_2"];
            for field_name = [positive_fields, valve_fields]
                if ~isfield(Params, field_name)
                    error("quadruple_tank:MissingParameter", ...
                        "Params 缺少必需字段 '%s'。", field_name);
                end
            end
            for field_name = positive_fields
                validateattributes(Params.(field_name), {'numeric'}, ...
                    {'real', 'finite', 'scalar', 'positive'}, ...
                    mfilename, char("Params." + field_name));
                Params.(field_name) = double(Params.(field_name));
            end
            for field_name = valve_fields
                validateattributes(Params.(field_name), {'numeric'}, ...
                    {'real', 'finite', 'scalar', '>=', 0, '<=', 1}, ...
                    mfilename, char("Params." + field_name));
                Params.(field_name) = double(Params.(field_name));
            end
        end

        function dz = stateDerivative(obj, z, u, t) %#ok<INUSD>
            p = obj.Params;
            z = max(z, 0); % 防止 RK4 中间阶段的负水位进入平方根。
            dz = [...
            -p.HoleArea_1/p.TankArea_1*sqrt(2*p.g*z(1)) + p.HoleArea_3/p.TankArea_1*sqrt(2*p.g*z(3)) + p.gamma_1/p.TankArea_1*u(1); ...
            -p.HoleArea_2/p.TankArea_2*sqrt(2*p.g*z(2)) + p.HoleArea_4/p.TankArea_2*sqrt(2*p.g*z(4)) + p.gamma_2/p.TankArea_2*u(2); ...
            -p.HoleArea_3/p.TankArea_3*sqrt(2*p.g*z(3)) + (1-p.gamma_2)/p.TankArea_3*u(2); ...
            -p.HoleArea_4/p.TankArea_4*sqrt(2*p.g*z(4)) + (1-p.gamma_1)/p.TankArea_4*u(1)...
            ];
            dz = dz + obj.disturbance;      % 加入扰动
        end
    end
end
