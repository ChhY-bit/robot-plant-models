function setup()
%SETUP 配置 Robot Plant Models 的 MATLAB 搜索路径。
%   本函数根据自身位置定位项目根目录，并添加 +rpm 命名空间的父目录。
%   添加完成后，本函数会询问是否调用 savepath 永久保存搜索路径。

    setup_dir = fileparts(mfilename("fullpath"));
    if isfolder(fullfile(setup_dir, "+rpm"))
        project_dir = setup_dir;             % 发布 ZIP 顶层
    elseif isfolder(fullfile(setup_dir, "..", "+rpm"))
        project_dir = fileparts(setup_dir);   % 源码仓库 packaging/
    else
        error("rpm:MissingSourceDirectory", ...
            "找不到 +rpm 源码目录，请检查安装目录是否完整。");
    end

    % 仅添加命名空间的父目录，不添加 +rpm 本身或其子目录。
    addpath(project_dir);

    fprintf("Robot Plant Models 已加入当前 MATLAB 会话的搜索路径。\n");

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
                error("rpm:SavePathFailed", ...
                    "无法永久保存搜索路径，请检查 pathdef.m 的写入权限。");
            end
            fprintf("当前完整的 MATLAB 搜索路径已永久保存。\n");
            break;
        end

        fprintf("请输入 y 或 n，直接按 Enter 表示 n。\n");
    end
end
