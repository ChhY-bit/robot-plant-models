function setup()
%SETUP 配置 Robot Plant Models 的 MATLAB 搜索路径。
%   本函数根据自身位置定位项目根目录，并添加 +rpm 命名空间的父目录。
%   检测当前工作目录和搜索路径中的其他 +rpm 来源，询问是否切换。
%   切换只移除旧路径，不删除文件或卸载工具箱；取消时不修改环境。
%   添加完成后显示实际解析位置，再询问是否调用 savepath 永久保存路径。

    setup_dir = fileparts(mfilename("fullpath"));
    if isfolder(fullfile(setup_dir, "+rpm"))
        project_dir = setup_dir;             % 发布 ZIP 顶层
    elseif isfolder(fullfile(setup_dir, "..", "+rpm"))
        project_dir = fileparts(setup_dir);   % 源码仓库 packaging/
    else
        error("rpm:MissingSourceDirectory", ...
            "找不到 +rpm 源码目录，请检查安装目录是否完整。");
    end

    project_dir = normalize_directory(project_dir);
    original_path = path;
    original_dir = pwd;
    path_dirs = split(string(original_path), pathsep);
    candidates = [string(original_dir); path_dirs(:)];
    old_dirs = strings(0, 1);
    already_configured = false;
    for k = 1:numel(candidates)
        folder = candidates(k);
        if strlength(folder) == 0 || ~isfolder(fullfile(folder, "+rpm"))
            continue;
        end
        folder = normalize_directory(folder);
        if same_directory(folder, project_dir)
            % 当前目录可被隐式搜索，但不代表已显式加入 path。
            if k > 1
                already_configured = true;
            end
        elseif ~any(arrayfun(@(item) same_directory(item, folder), old_dirs))
            old_dirs(end+1, 1) = folder; %#ok<AGROW>
        end
    end

    fprintf("待配置 RPM：%s\n版本：%s\n", project_dir, read_version(project_dir));
    change_directory = any(arrayfun(@(item) same_directory(item, original_dir), old_dirs));
    if ~isempty(old_dirs)
        fprintf("检测到其他 +rpm 来源：\n");
        for k = 1:numel(old_dirs)
            fprintf("  %s（版本：%s）\n", old_dirs(k), read_version(old_dirs(k)));
        end
        fprintf("切换会移除上述目录的搜索路径，保留所有文件及已安装工具箱。\n");
        if change_directory
            fprintf("当前工作目录也是旧来源，切换时将工作目录改为：%s\n", project_dir);
        end
        if ~ask_yes_no("是否切换到本目录的 RPM？[y/N]: ")
            fprintf("已取消，工作目录和搜索路径未修改。\n");
            return;
        end
    elseif already_configured
        fprintf("本目录已配置，将确认路径优先级。\n");
    end

    % 修改失败时恢复环境；仅移除检测到的命名空间父目录。
    try
        if change_directory
            cd(project_dir);
        end
        for k = 1:numel(path_dirs)
            if strlength(path_dirs(k)) > 0 && isfolder(path_dirs(k))
                folder = normalize_directory(path_dirs(k));
                if any(arrayfun(@(item) same_directory(item, folder), old_dirs))
                    rmpath(path_dirs(k));
                end
            end
        end
        addpath(project_dir, '-begin');
        rehash;
        active_file = string(which('rpm.version'));
        if active_file == "" || ~same_directory(fileparts(fileparts(active_file)), project_dir)
            error("rpm:SetupSourceConflict", ...
                "RPM 解析位置与目标目录不一致：%s。请检查路径或重启 MATLAB 后重试。", active_file);
        end
    catch cause
        cd(original_dir);
        path(original_path);
        rethrow(cause);
    end

    fprintf("RPM 已配置到当前 MATLAB 会话。\n实际解析位置：%s\n版本：%s\n", ...
        active_file, read_version(project_dir));
    if ~isempty(old_dirs)
        fprintf("切换后请重新创建 RPM 对象；若已加载旧类仍有冲突，请重启 MATLAB。\n");
        fprintf("通过附加功能管理器安装的旧工具箱仍保留，重启或启用时可能重新加入路径。\n");
    end

    if ask_yes_no("是否永久保存当前完整的 MATLAB 搜索路径？[y/N]: ")
        save_status = savepath;
        if save_status ~= 0
            error("rpm:SavePathFailed", ...
                "无法永久保存搜索路径；当前会话已配置，请检查 pathdef.m 的写入权限。");
        end
        fprintf("当前完整的 MATLAB 搜索路径已永久保存。\n");
    else
        fprintf("未写入永久路径；本次路径变更仅用于当前会话，原有永久配置不变。\n");
    end
end

function answer = ask_yes_no(prompt)
%ASK_YES_NO 默认取消／不保存，非法回答时重新询问。
    while true
        reply = lower(strtrim(string(input(prompt, "s"))));
        if reply == "" || any(reply == ["n", "no", "否"])
            answer = false;
            return;
        end
        if any(reply == ["y", "yes", "是"])
            answer = true;
            return;
        end
        fprintf("请输入 y 或 n，直接按 Enter 表示 n。\n");
    end
end

function folder = normalize_directory(folder)
%NORMALIZE_DIRECTORY 转为绝对目录，供路径比较使用。
    [success, attributes] = fileattrib(folder);
    if ~success
        error("rpm:InvalidSetupDirectory", "无法读取目录：%s", folder);
    end
    folder = string(attributes.Name);
end

function result = same_directory(left, right)
%SAME_DIRECTORY Windows 路径比较忽略大小写。
    left = normalize_directory(left);
    right = normalize_directory(right);
    if ispc
        result = strcmpi(left, right);
    else
        result = strcmp(left, right);
    end
end

function value = read_version(folder)
%READ_VERSION 直接读取来源目录，避免调用到另一份 RPM 的版本函数。
    value = "未知（无有效 VERSION）";
    version_file = fullfile(folder, "VERSION");
    if ~isfile(version_file)
        return;
    end
    try
        candidate = strtrim(string(fileread(version_file)));
        if ~isempty(regexp(candidate, ...
                '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$', 'once'))
            value = candidate;
        end
    catch
        value = "未知（VERSION 无法读取）";
    end
end
