function test_quadruple_tank_params()
%TEST_QUADRUPLE_TANK_PARAMS 检查四水箱配置加载、物理范围与模板导出。
    project_dir = fileparts(fileparts(mfilename('fullpath')));
    addpath(project_dir);
    params = rpm.utils.load_quadruple_tank_params();
    expected_fields = {'TankArea_1'; 'TankArea_2'; 'TankArea_3'; 'TankArea_4'; ...
        'HoleArea_1'; 'HoleArea_2'; 'HoleArea_3'; 'HoleArea_4'; ...
        'g'; 'gamma_1'; 'gamma_2'};
    assert(isequal(fieldnames(params), expected_fields));
    assert(params.TankArea_1 == 2.8e-3 && params.HoleArea_4 == 5.7e-6);
    assert(params.g == 9.81 && params.gamma_1 == 0.5);
    for k = 1:numel(expected_fields)
        assert(isa(params.(expected_fields{k}), 'double'));
        assert(isscalar(params.(expected_fields{k})));
    end

    % 在其他工作目录中仍能加载默认配置；默认导出使用当前工作目录。
    original_dir = pwd;
    work_dir = tempname;
    mkdir(work_dir);
    work_cleanup = onCleanup(@() cleanup_work_dir(original_dir, work_dir));
    cd(work_dir);
    assert(isequal(rpm.utils.load_quadruple_tank_params(), params));
    exported = rpm.utils.export_quadruple_tank_params();
    assert(exported == fullfile(string(pwd), "quadruple_tank.yaml"));
    source = fullfile(project_dir, '+rpm', 'config', 'quadruple_tank.yaml');
    assert(strcmp(fileread(exported), fileread(source)));
    assert(isequal(rpm.utils.load_quadruple_tank_params(exported), params));
    must_error(@() rpm.utils.export_quadruple_tank_params(exported), ...
        'quadruple_tank:ExportTargetExists');
    assert(strcmp(fileread(exported), fileread(source)));
    must_error(@() rpm.utils.export_quadruple_tank_params(string(work_dir)), ...
        'quadruple_tank:ExportTargetExists');
    custom_path = fullfile(work_dir, 'custom.yaml');
    rpm.utils.export_quadruple_tank_params(custom_path);
    assert(isequal(rpm.utils.load_quadruple_tank_params(custom_path), params));
    must_error(@() rpm.utils.load_quadruple_tank_params("missing.yaml"), ...
        'quadruple_tank:ParameterFileNotFound');

    template = string(fileread(source));
    input_path = fullfile(work_dir, 'input.yaml');
    writelines(replace(replace(template, "gamma_1: 0.5", "gamma_1: 0"), ...
        "gamma_2: 0.5", "gamma_2: 1"), input_path);
    boundary = rpm.utils.load_quadruple_tank_params(input_path);
    assert(boundary.gamma_1 == 0 && boundary.gamma_2 == 1);

    invalid_values = ["0", "-1", "[1, 2]", "1e999"];
    for value = invalid_values
        writelines(replace(template, "TankArea_1: 2.8e-3", ...
            "TankArea_1: " + value), input_path);
        must_error(@() rpm.utils.load_quadruple_tank_params(input_path), ...
            ["quadruple_tank:InvalidParameterValue", ...
             "quadruple_tank:InvalidParameterSize"]);
    end
    for field = ["HoleArea_1", "g", "gamma_1", "gamma_2"]
        lines = splitlines(template);
        index = startsWith(lines, field + ":");
        lines(index) = field + ": -0.1";
        writelines(lines, input_path);
        must_error(@() rpm.utils.load_quadruple_tank_params(input_path), ...
            'quadruple_tank:InvalidParameterValue');
    end
    writelines(replace(template, "gamma_2: 0.5", "gamma_2: 1.1"), input_path);
    must_error(@() rpm.utils.load_quadruple_tank_params(input_path), ...
        'quadruple_tank:InvalidParameterValue');
    writelines(replace(template, "g: 9.81", ""), input_path);
    must_error(@() rpm.utils.load_quadruple_tank_params(input_path), ...
        'quadruple_tank:MissingParameter');

    if exist('readyaml', 'file') == 0
        writelines(template + newline + "g: 10", input_path);
        must_error(@() rpm.utils.load_quadruple_tank_params(input_path), ...
            'quadruple_tank:DuplicateParameter');
        writelines("g 9.81", input_path);
        must_error(@() rpm.utils.load_quadruple_tank_params(input_path), ...
            'quadruple_tank:InvalidYAML');
        writelines(replace(template, "g: 9.81", "g: true"), input_path);
        must_error(@() rpm.utils.load_quadruple_tank_params(input_path), ...
            'quadruple_tank:UnsupportedYAMLValue');
    end
    fprintf('test_quadruple_tank_params passed.\n');
end

function must_error(action, expected_ids)
    try
        action();
    catch cause
        assert(any(string(cause.identifier) == string(expected_ids)), ...
            'Unexpected error: %s (%s)', cause.message, cause.identifier);
        return;
    end
    error('test_quadruple_tank_params:ExpectedError', 'Expected an error.');
end

function cleanup_work_dir(original_dir, work_dir)
    cd(original_dir);
    rmdir(work_dir, 's');
end
