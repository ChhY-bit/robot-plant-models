function setup()
%SETUP 配置 robot_plant 源码的 MATLAB 搜索路径。
%   本函数根据自身位置定位项目根目录，并添加公开类和工具函数目录。
%   添加完成后，本函数会询问是否调用 savepath 永久保存搜索路径。

    project_dir = fileparts(mfilename("fullpath"));
    source_dirs = [
        fullfile(project_dir, "plants")
        fullfile(project_dir, "utils")
    ];

    for index = 1:numel(source_dirs)
        if ~isfolder(source_dirs(index))
            error("robot_plant:MissingSourceDirectory", ...
                "找不到源码目录：%s", source_dirs(index));
        end
        addpath(source_dirs(index));
    end

    fprintf("robot_plant 已加入当前 MATLAB 会话的搜索路径。\n");

    while true
        reply = lower(strtrim(string(input( ...
            "是否永久保存当前完整的 MATLAB 搜索路径？[y/N]: ", "s"))));

        if reply == "" || any(reply == ["n", "no", "否"])
            fprintf("搜索路径未永久保存，关闭 MATLAB 后本次设置失效。\n");
            break;
        end

        if any(reply == ["y", "yes", "是"])
            save_status = savepath;
            if save_status ~= 0
                error("robot_plant:SavePathFailed", ...
                    "无法永久保存搜索路径，请检查 pathdef.m 的写入权限。");
            end
            fprintf("当前完整的 MATLAB 搜索路径已永久保存。\n");
            break;
        end

        fprintf("请输入 y 或 n，直接按 Enter 表示 n。\n");
    end
end
