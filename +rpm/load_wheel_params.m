function params = load_wheel_params(file_path)
%LOAD_WHEEL_PARAMS 从 YAML 文件读取并校验差速轮式机器人参数。
%   PARAMS = LOAD_WHEEL_PARAMS() 读取项目 config 目录下的
%   wheel_robot.yaml。
%
%   PARAMS = LOAD_WHEEL_PARAMS(FILE_PATH) 读取指定 YAML 文件。
%
%   返回值 PARAMS 是普通 MATLAB 结构体，可直接传入：
%       robot = rpm.wheel_robot(params, initial_states);

    arguments
        file_path (1, 1) string = ""
    end

    if strlength(file_path) == 0
        function_dir = fileparts(mfilename("fullpath"));
        file_path = fullfile(function_dir, "config", ...
            "wheel_robot.yaml");
    end

    if ~isfile(file_path)
        error("wheel_robot:ParameterFileNotFound", ...
            "找不到机器人参数文件：%s", file_path);
    end

    if exist("readyaml", "file") ~= 0
        yaml_data = readyaml(file_path);
    else
        % R2024a 基础 MATLAB 不自带 readyaml。当前参数文件只使用
        % 顶层键以及 JSON 兼容的数值标量/数组，因此可以无依赖读取。
        yaml_data = read_flat_numeric_yaml(file_path);
    end

    params = struct();
    params.wheelRadius = normalize_pair( ...
        require_field(yaml_data, "wheelRadius"), "wheelRadius", false);
    params.trackWidth = normalize_scalar( ...
        require_field(yaml_data, "trackWidth"), "trackWidth", false);
    params.motorTimeConstant = normalize_pair( ...
        require_field(yaml_data, "motorTimeConstant"), ...
        "motorTimeConstant", true);
    params.maxWheelSpeed = normalize_pair( ...
        require_field(yaml_data, "maxWheelSpeed"), "maxWheelSpeed", false);

    params.bodySize = normalize_vector( ...
        require_field(yaml_data, "bodySize"), "bodySize", 3, false);
    params.wheelWidth = normalize_pair( ...
        require_field(yaml_data, "wheelWidth"), "wheelWidth", false);
    params.axleOffset = normalize_finite_scalar( ...
        require_field(yaml_data, "axleOffset"), "axleOffset");
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
            error("wheel_robot:InvalidYAML", ...
                "YAML 第 %d 行缺少冒号分隔符。", line_index);
        end

        colon_index = colon_index(1);
        field_name = strtrim(extractBefore(line, colon_index));
        value_text = strtrim(extractAfter(line, colon_index));

        if field_name == "" || ~isvarname(field_name)
            error("wheel_robot:InvalidYAML", ...
                "YAML 第 %d 行包含无效字段名 '%s'。", ...
                line_index, field_name);
        end

        if value_text == ""
            error("wheel_robot:UnsupportedYAML", ...
                "YAML 第 %d 行的字段 '%s' 没有行内数值。" + ...
                "当前回退读取器不支持嵌套 YAML。", ...
                line_index, field_name);
        end

        try
            value = jsondecode(value_text);
        catch cause
            exception = MException("wheel_robot:InvalidYAMLValue", ...
                "无法解析 YAML 第 %d 行中字段 '%s' 的数值。", ...
                line_index, field_name);
            exception = addCause(exception, cause);
            throw(exception);
        end

        if ~isnumeric(value)
            error("wheel_robot:UnsupportedYAMLValue", ...
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
        exception = MException("wheel_robot:MissingParameter", ...
            "YAML 参数文件缺少必需字段 '%s'。", field_name);
        exception = addCause(exception, cause);
        throw(exception);
    end
end

function value = normalize_pair(value, field_name, allow_zero)
%NORMALIZE_PAIR 将标量或双元素参数规范为 2×1 列向量。
    value = to_numeric(value, field_name);

    if isscalar(value)
        value = repmat(value, 2, 1);
    elseif numel(value) == 2
        value = value(:);
    else
        error("wheel_robot:InvalidParameterSize", ...
            "参数 '%s' 必须是标量或包含两个元素。", field_name);
    end

    validate_range(value, field_name, allow_zero);
end

function value = normalize_vector(value, field_name, element_count, allow_zero)
%NORMALIZE_VECTOR 将指定长度的参数规范为列向量。
    value = to_numeric(value, field_name);

    if ~isvector(value) || numel(value) ~= element_count
        error("wheel_robot:InvalidParameterSize", ...
            "参数 '%s' 必须包含 %d 个元素。", field_name, element_count);
    end

    value = value(:);
    validate_range(value, field_name, allow_zero);
end

function value = normalize_scalar(value, field_name, allow_zero)
%NORMALIZE_SCALAR 将参数规范为有限实数标量。
    value = to_numeric(value, field_name);

    if ~isscalar(value)
        error("wheel_robot:InvalidParameterSize", ...
            "参数 '%s' 必须是标量。", field_name);
    end

    validate_range(value, field_name, allow_zero);
end

function value = normalize_finite_scalar(value, field_name)
%NORMALIZE_FINITE_SCALAR 允许正负号的有限实数标量。
    value = to_numeric(value, field_name);

    if ~isscalar(value)
        error("wheel_robot:InvalidParameterSize", ...
            "参数 '%s' 必须是标量。", field_name);
    end
end

function value = to_numeric(value, field_name)
%TO_NUMERIC 将 YAML 序列或标量转换为 double 数值。
    if iscell(value)
        try
            value = cell2mat(value);
        catch cause
            exception = MException("wheel_robot:InvalidParameterType", ...
                "参数 '%s' 必须由数值组成。", field_name);
            exception = addCause(exception, cause);
            throw(exception);
        end
    end

    if ~isnumeric(value)
        error("wheel_robot:InvalidParameterType", ...
            "参数 '%s' 必须是数值。", field_name);
    end

    value = double(value);

    if ~isreal(value) || any(~isfinite(value), "all")
        error("wheel_robot:InvalidParameterValue", ...
            "参数 '%s' 必须是有限实数。", field_name);
    end
end

function validate_range(value, field_name, allow_zero)
%VALIDATE_RANGE 检查参数为正数或非负数。
    if allow_zero
        invalid = any(value < 0, "all");
        requirement = "非负数";
    else
        invalid = any(value <= 0, "all");
        requirement = "正数";
    end

    if invalid
        error("wheel_robot:InvalidParameterValue", ...
            "参数 '%s' 必须全部为%s。", field_name, requirement);
    end
end
