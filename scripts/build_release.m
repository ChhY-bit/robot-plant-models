function artifacts = build_release(options)
%BUILD_RELEASE 从根目录 VERSION 构建源码 ZIP 和 MATLAB 工具箱。
%   addpath('scripts'); artifacts = build_release();
%   默认要求工作区干净且 HEAD 带有 v<VERSION> 标签。
%   build_release(RequireTag=false) 可用于本地预览，不执行提交、打标签或上传。
%   目标 dist/v<VERSION> 已存在时拒绝覆盖，包括历史版本产物。

    arguments
        options.RequireTag (1, 1) logical = true
    end

    project_dir = fileparts(fileparts(mfilename('fullpath')));
    saved_path = path;
    path_cleanup = onCleanup(@() path(saved_path));
    addpath(project_dir, '-begin');
    release_version = rpm.version();
    info = git_snapshot(project_dir);
    expected_tag = "v" + release_version;
    if options.RequireTag
        if ~info.Available || ~any(info.Tags == expected_tag)
            error('rpm:ReleaseTagMismatch', ...
                '正式构建要求 HEAD 带有标签 %s。', expected_tag);
        end
        if info.Dirty
            error('rpm:DirtyRelease', '正式构建要求工作区没有未提交或未跟踪的更改。');
        end
    end

    release_dir = fullfile(project_dir, 'dist', expected_tag);
    if isfolder(release_dir) || isfile(release_dir)
        error('rpm:ReleaseTargetExists', '发布目录已存在，不会覆盖：%s', release_dir);
    end
    stage_dir = fullfile(release_dir, "build-" + release_version);
    mkdir(stage_dir);
    copyfile(fullfile(project_dir, '+rpm'), fullfile(stage_dir, '+rpm'));
    for name = ["VERSION", "LICENSE", "README.md", "RELEASING.md", "setup.m"]
        copyfile(fullfile(project_dir, name), fullfile(stage_dir, name));
    end

    % Git 元信息与基础版本分开保存；安装后查询版本不需要 Git。
    manifest = struct('Version', release_version, 'Commit', info.Commit, ...
        'GitAvailable', info.Available, 'Dirty', info.Dirty, ...
        'Tags', info.Tags, 'ReleaseChecked', options.RequireTag);
    writelines(string(jsonencode(manifest, PrettyPrint=true)), ...
        fullfile(stage_dir, 'BUILD_INFO.json'), Encoding='UTF-8');

    basename = "robot-plant-models-" + release_version;
    toolbox_path = fullfile(release_dir, basename + ".mltbx");
    toolbox_options = matlab.addons.toolbox.ToolboxOptions(stage_dir, ...
        '01f41360-b799-4f70-81ea-2df94b3e7a0c');
    toolbox_options.ToolboxName = 'Robot Plant Models';
    toolbox_options.ToolboxVersion = char(release_version);
    toolbox_options.AuthorName = 'ChhY-bit';
    toolbox_options.AuthorCompany = 'Beijing Institute of Technology';
    toolbox_options.Summary = 'Open-source MATLAB plant models for robots and liquid-level systems.';
    toolbox_options.MinimumMatlabRelease = 'R2024a';
    toolbox_options.ToolboxMatlabPath = string(stage_dir);
    toolbox_options.OutputFile = toolbox_path;
    matlab.addons.toolbox.packageToolbox(toolbox_options);

    % 核对打包元数据与包内 VERSION；任一不一致都停止构建。
    actual_version = string(matlab.addons.toolbox.toolboxVersion(toolbox_path));
    staged_version = strtrim(string(fileread(fullfile(stage_dir, 'VERSION'))));
    if actual_version ~= release_version || staged_version ~= release_version
        error('rpm:ReleaseVersionMismatch', '工具箱、源码和 VERSION 的版本不一致。');
    end
    zip_path = fullfile(release_dir, basename + ".zip");
    zip(zip_path, {'+rpm', 'VERSION', 'LICENSE', 'README.md', 'RELEASING.md', ...
        'setup.m', 'BUILD_INFO.json'}, stage_dir);
    artifacts = struct('Version', release_version, 'Toolbox', toolbox_path, ...
        'Zip', zip_path, 'Stage', stage_dir);
    fprintf('已构建 Robot Plant Models %s：\n%s\n%s\n', ...
        release_version, toolbox_path, zip_path);
end

function info = git_snapshot(project_dir)
    info = struct('Available', false, 'Commit', "", ...
        'Dirty', false, 'Tags', strings(0, 1));
    if ~isfolder(fullfile(project_dir, '.git')) && ~isfile(fullfile(project_dir, '.git'))
        return;
    end
    original_dir = pwd;
    directory_cleanup = onCleanup(@() cd(original_dir));
    cd(project_dir);
    [commit_status, commit] = system('git rev-parse HEAD');
    [status_status, changes] = system('git status --porcelain --untracked-files=normal');
    [tag_status, tags] = system('git tag --points-at HEAD');
    if any([commit_status, status_status, tag_status] ~= 0)
        return;
    end
    info.Available = true;
    info.Commit = strtrim(string(commit));
    info.Dirty = strlength(strtrim(string(changes))) > 0;
    info.Tags = strip(splitlines(string(tags)));
    info.Tags(info.Tags == "") = [];
end
