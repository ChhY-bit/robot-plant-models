function file_path = export_wheel_params(file_path)
%EXPORT_WHEEL_PARAMS 导出差速轮式机器人参数配置模板。
%   FILE_PATH = EXPORT_WHEEL_PARAMS() 将内置 YAML 模板导出到当前工作
%   目录下的 wheel_robot.yaml，并返回目标文件的完整路径。
%
%   FILE_PATH = EXPORT_WHEEL_PARAMS(FILE_PATH) 将内置 YAML 模板导出到
%   指定位置。目标文件已存在时不会覆盖，而是抛出错误。

    arguments
        file_path (1, 1) string = ""
    end

    if strlength(file_path) == 0
        file_path = fullfile(pwd, "wheel_robot.yaml");
    end

    function_dir = fileparts(mfilename("fullpath"));
    source_path = fullfile(function_dir, "config", ...
        "wheel_robot.yaml");

    if ~isfile(source_path)
        error("wheel_robot:TemplateFileNotFound", ...
            "找不到内置机器人参数模板：%s", source_path);
    end

    if isfile(file_path) || isfolder(file_path)
        error("wheel_robot:ExportTargetExists", ...
            "导出目标已经存在，不会覆盖：%s", file_path);
    end

    [success, message] = copyfile(source_path, file_path);
    if ~success
        error("wheel_robot:ExportFailed", ...
            "无法导出机器人参数模板到 '%s'：%s", file_path, message);
    end

    [~, attributes] = fileattrib(file_path);
    file_path = string(attributes.Name);
end
