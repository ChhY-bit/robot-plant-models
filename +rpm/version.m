function value = version()
%VERSION 查询 Robot Plant Models 版本，返回字符串标量。
%   VALUE = rpm.version() 从 +rpm 父目录的 VERSION 文件读取版本。
%   不依赖 Git，也不受当前工作目录影响；调用时请使用完整命名空间。

    project_dir = fileparts(fileparts(mfilename('fullpath')));
    version_path = fullfile(project_dir, 'VERSION');
    if ~isfile(version_path)
        error('rpm:VersionFileNotFound', '找不到版本文件：%s', version_path);
    end
    value = strtrim(string(fileread(version_path)));
    if isempty(regexp(value, ...
            '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$', 'once'))
        error('rpm:InvalidVersion', ...
            'VERSION 必须包含一个 major.minor.patch 格式的版本号。');
    end
end
