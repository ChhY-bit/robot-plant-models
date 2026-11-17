function params = load_quadruple_tank_params(file_path)
%LOAD_QUADRUPLE_TANK_PARAMS 从 YAML 文件读取并校验四水箱参数。
%   PARAMS = rpm.utils.load_quadruple_tank_params() 读取 +rpm/config 下的
%   quadruple_tank.yaml；指定 FILE_PATH 时读取对应的 YAML 文件。
%
%   返回普通 MATLAB 结构体，字段名与 YAML 一致：TankArea_1 至
%   TankArea_4、HoleArea_1 至 HoleArea_4、g、gamma_1、gamma_2、
%   TankHeight_1 至 TankHeight_4、PumpMaxFlow_1 至 PumpMaxFlow_2、
%   PumpFlowSpeed_1 至 PumpFlowSpeed_2，所有字段均为必需字段。
%   面积单位为 m^2，g 为 m/s^2，水箱高度为 m，泵最大流量为 m^3/s，
%   泵出口总管在最大流量下的平均流速为 m/s。
%   所有值均为有限实数 double 标量；gamma_1、gamma_2 在 [0, 1] 内，
%   其余参数均为正数。

    arguments
        file_path (1, 1) string = ""
    end

    if strlength(file_path) == 0
        function_dir = fileparts(mfilename("fullpath"));
        file_path = fullfile(fileparts(function_dir), "config", ...
            "quadruple_tank.yaml");
    end

    if ~isfile(file_path)
        error("quadruple_tank:ParameterFileNotFound", ...
            "找不到四水箱参数文件：%s", file_path);
    end

    if exist("readyaml", "file") ~= 0
        yaml_data = readyaml(file_path);
    else
        % 与现有加载器一致，为基础 MATLAB 提供平铺数值 YAML 回退读取器。
        yaml_data = read_flat_numeric_yaml(file_path);
    end

    params = struct();
    positive_fields = ["TankArea_1", "TankArea_2", "TankArea_3", "TankArea_4", ...
        "HoleArea_1", "HoleArea_2", "HoleArea_3", "HoleArea_4", "g", ...
        "TankHeight_1", "TankHeight_2", "TankHeight_3", "TankHeight_4", ...
        "PumpMaxFlow_1", "PumpMaxFlow_2", "PumpFlowSpeed_1", "PumpFlowSpeed_2"];
    for field_name = positive_fields
        value = normalize_scalar(require_field(yaml_data, field_name), field_name);
        if value <= 0
            error("quadruple_tank:InvalidParameterValue", ...
                "参数 '%s' 必须是正数。", field_name);
        end
        params.(field_name) = value;
    end

    for field_name = ["gamma_1", "gamma_2"]
        value = normalize_scalar(require_field(yaml_data, field_name), field_name);
        if value < 0 || value > 1
            error("quadruple_tank:InvalidParameterValue", ...
                "参数 '%s' 必须在 [0, 1] 范围内。", field_name);
        end
        params.(field_name) = value;
    end
end

function data = read_flat_numeric_yaml(file_path)
%READ_FLAT_NUMERIC_YAML 读取由顶层键和数值组成的简化 YAML 配置。
%   此回退读取器有意只支持本项目参数文件使用的 YAML 子集：
%   KEY: NUMBER 或 KEY: [NUMBER, ...]。完整 YAML 应使用 readyaml。

    lines = readlines(file_path);
    data = struct();

    for line_index = 1:numel(lines)
        line = strtrim(lines(line_index));

        if line == "" || startsWith(line, "#")
            continue;
        end

        colon_index = strfind(line, ":");
        if isempty(colon_index)
            error("quadruple_tank:InvalidYAML", ...
                "YAML 第 %d 行缺少冒号分隔符。", line_index);
        end

        colon_index = colon_index(1);
        field_name = strtrim(extractBefore(line, colon_index));
        value_text = strtrim(extractAfter(line, colon_index));

        if field_name == "" || ~isvarname(field_name)
            error("quadruple_tank:InvalidYAML", ...
                "YAML 第 %d 行包含无效字段名 '%s'。", ...
                line_index, field_name);
        end

        if value_text == ""
            error("quadruple_tank:UnsupportedYAML", ...
                "YAML 第 %d 行的字段 '%s' 没有行内数值。" + ...
                "当前回退读取器不支持嵌套 YAML。", ...
                line_index, field_name);
        end

        if isfield(data, field_name)
            error("quadruple_tank:DuplicateParameter", ...
                "YAML 第 %d 行重复定义了字段 '%s'。", ...
                line_index, field_name);
        end

        try
            value = jsondecode(value_text);
        catch cause
            exception = MException("quadruple_tank:InvalidYAMLValue", ...
                "无法解析 YAML 第 %d 行中字段 '%s' 的数值。", ...
                line_index, field_name);
            exception = addCause(exception, cause);
            throw(exception);
        end

        if ~isnumeric(value)
            error("quadruple_tank:UnsupportedYAMLValue", ...
                "YAML 字段 '%s' 必须是数值标量或数值数组。", field_name);
        end

        data.(field_name) = value;
    end
end

function value = require_field(data, field_name)
%REQUIRE_FIELD 读取必需字段，并给出明确的缺失字段错误。
    try
        value = data.(field_name);
    catch cause
        exception = MException("quadruple_tank:MissingParameter", ...
            "YAML 参数文件缺少必需字段 '%s'。", field_name);
        exception = addCause(exception, cause);
        throw(exception);
    end
end

function value = normalize_scalar(value, field_name)
%NORMALIZE_SCALAR 将参数规范为有限实数 double 标量。
    if ~isnumeric(value)
        error("quadruple_tank:InvalidParameterType", ...
            "参数 '%s' 必须是数值。", field_name);
    end

    if ~isscalar(value)
        error("quadruple_tank:InvalidParameterSize", ...
            "参数 '%s' 必须是标量。", field_name);
    end

    value = double(value);
    if ~isreal(value) || ~isfinite(value)
        error("quadruple_tank:InvalidParameterValue", ...
            "参数 '%s' 必须是有限实数。", field_name);
    end
end
