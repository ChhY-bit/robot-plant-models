function file_path = export_ackermann_params(file_path)
%EXPORT_ACKERMANN_PARAMS 导出阿克曼机器人参数配置模板。
%   FILE_PATH = EXPORT_ACKERMANN_PARAMS() 将内置 YAML 模板导出到当前
%   工作目录下的 ackermann_robot.yaml，并返回目标文件的完整路径。
%
%   FILE_PATH = EXPORT_ACKERMANN_PARAMS(FILE_PATH) 将内置 YAML 模板导出
%   到指定位置。目标文件或目录已存在时不会覆盖，而是抛出错误。

    arguments
        file_path (1, 1) string = ""
    end

    if strlength(file_path) == 0
        file_path = fullfile(pwd, "ackermann_robot.yaml");
    end

    function_dir = fileparts(mfilename("fullpath"));
    source_path = fullfile(function_dir, "config", ...
        "ackermann_robot.yaml");

    if ~isfile(source_path)
        error("ackermann_robot:TemplateFileNotFound", ...
            "找不到内置机器人参数模板：%s", source_path);
    end

    if isfile(file_path) || isfolder(file_path)
        error("ackermann_robot:ExportTargetExists", ...
            "导出目标已经存在，不会覆盖：%s", file_path);
    end

    [success, message] = copyfile(source_path, file_path);
    if ~success
        error("ackermann_robot:ExportFailed", ...
            "无法导出机器人参数模板到 '%s'：%s", file_path, message);
    end

    [~, attributes] = fileattrib(file_path);
    file_path = string(attributes.Name);
end
