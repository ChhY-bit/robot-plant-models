classdef quadruple_tank < handle

    properties(Access=private)
        A1, A2, A3, A4      % 容器截面积
        a1, a2, a3, a4      % 出水孔截面积
        g                   % 重力加速度
        gamma_1, gamma_2    % 阀门分配比

        u1, u2              % 进水速率
    end

    properties(SetAccess=private)
        x1, x2, x3, x4      % 水位高度
    end

    methods
        function obj = quadruple_tank(Params, Ini_States)
            %QUADRUPLE_TANK 初始化物理参数与水位 [x1; x2; x3; x4]。
            %   省略参数或传 [] 时，使用默认 YAML 参数和四维零水位。
            %   Params 必须为包含全部物理字段的标量结构体；面积与 g 为
            %   正数，阀门分配比在 [0, 1] 内，均规范为 double 标量。
            if nargin < 1 || isempty(Params)
                Params = rpm.utils.load_quadruple_tank_params();
            end
            Params = obj.validateParams(Params);
            if nargin < 2 || isempty(Ini_States)
                Ini_States = zeros(4, 1);
            end
            validateattributes(Ini_States, {'numeric'}, ...
                {'real', 'finite', 'vector', 'numel', 4, 'nonnegative'}, ...
                mfilename, 'Ini_States');
            Ini_States = double(Ini_States(:));

            % 将 YAML 字段名映射到模型方程使用的属性名。
            obj.A1 = Params.TankArea_1;
            obj.A2 = Params.TankArea_2;
            obj.A3 = Params.TankArea_3;
            obj.A4 = Params.TankArea_4;
            obj.a1 = Params.HoleArea_1;
            obj.a2 = Params.HoleArea_2;
            obj.a3 = Params.HoleArea_3;
            obj.a4 = Params.HoleArea_4;
            obj.g = Params.g;
            obj.gamma_1 = Params.gamma_1;
            obj.gamma_2 = Params.gamma_2;

            obj.x1 = Ini_States(1);
            obj.x2 = Ini_States(2);
            obj.x3 = Ini_States(3);
            obj.x4 = Ini_States(4);
            obj.u1 = 0;
            obj.u2 = 0;
        end

        function send(obj,u1,u2)
            %SEND 设置非负进水速率 [m^3/s]，两个输入均须为有限实数标量。
            validateattributes(u1, {'numeric'}, ...
                {'real', 'finite', 'scalar', 'nonnegative'}, mfilename, 'u1');
            validateattributes(u2, {'numeric'}, ...
                {'real', 'finite', 'scalar', 'nonnegative'}, mfilename, 'u2');
            obj.u1 = double(u1);
            obj.u2 = double(u2);
        end

        function step(obj,dt,t)
            c = [obj.u1; obj.u2];
            z = [obj.x1;obj.x2;obj.x3;obj.x4];

            K1 = obj.stateDerivative(z,c,t);
            K2 = obj.stateDerivative(z+K1*dt/2,c,t+dt/2);
            K3 = obj.stateDerivative(z+K2*dt/2,c,t+dt/2);
            K4 = obj.stateDerivative(z+K3*dt,c,t+dt);
            States = max(z+dt*(K1+2*K2+2*K3+K4)/6,0);
            obj.x1 = States(1);
            obj.x2 = States(2);
            obj.x3 = States(3);
            obj.x4 = States(4);

        end

        function setValve(obj,gamma_1,gamma_2)
            %SETVALVE 设置阀门分配比，两个输入均须为 [0, 1] 内的有限实数标量。
            validateattributes(gamma_1, {'numeric'}, ...
                {'real', 'finite', 'scalar', '>=', 0, '<=', 1}, ...
                mfilename, 'gamma_1');
            validateattributes(gamma_2, {'numeric'}, ...
                {'real', 'finite', 'scalar', '>=', 0, '<=', 1}, ...
                mfilename, 'gamma_2');
            obj.gamma_1 = double(gamma_1);
            obj.gamma_2 = double(gamma_2);
        end

    end

    methods(Access = private)
        function Params = validateParams(~, Params)
            %VALIDATEPARAMS 校验直接传入的参数，防止绕过 YAML 加载器的检查。
            validateattributes(Params, {'struct'}, {'scalar'}, mfilename, 'Params');
            positive_fields = ["TankArea_1", "TankArea_2", "TankArea_3", "TankArea_4", ...
                "HoleArea_1", "HoleArea_2", "HoleArea_3", "HoleArea_4", "g"];
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
            z = max(z, 0); % 防止 RK4 中间阶段的负水位进入平方根。
            dz = [...
            -obj.a1/obj.A1*sqrt(2*obj.g*z(1)) + obj.a3/obj.A1*sqrt(2*obj.g*z(3)) + obj.gamma_1/obj.A1*u(1); ...
            -obj.a2/obj.A2*sqrt(2*obj.g*z(2)) + obj.a4/obj.A2*sqrt(2*obj.g*z(4)) + obj.gamma_2/obj.A2*u(2); ...
            -obj.a3/obj.A3*sqrt(2*obj.g*z(3)) + (1-obj.gamma_2)/obj.A3*u(2); ...
            -obj.a4/obj.A4*sqrt(2*obj.g*z(4)) + (1-obj.gamma_1)/obj.A4*u(1)...
            ];
        end
    end
end
