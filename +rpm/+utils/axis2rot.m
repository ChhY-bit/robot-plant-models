function rotation = axis2rot(axis, theta)
%AXIS2ROT 将旋转轴和弧度制转角转换为 3x3 主动旋转矩阵。
%   R = rpm.utils.axis2rot(AXIS, THETA) 接受三个元素的行/列轴向量，
%   自动归一化非零 AXIS。THETA 是绕该轴按右手定则旋转的弧度数。
%   使用 Rodrigues 公式直接返回 double 旋转矩阵，无 RPY 中间转换。
%   零轴向量无效，包括 THETA=0 时。

    validateattributes(axis, {'numeric'}, ...
        {'real', 'finite', 'vector', 'numel', 3}, mfilename, 'axis');
    validateattributes(theta, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'theta');
    axis = double(axis(:));
    scale = max(abs(axis));
    if scale == 0
        error('rpm:utils:axis2rot:InvalidAxis', '旋转轴必须为非零向量。');
    end
    % Scale first to avoid overflow/underflow when normalizing the axis.
    axis = axis / scale;
    axis = axis / norm(axis);
    theta = double(theta);
    K = [0, -axis(3), axis(2); ...
         axis(3), 0, -axis(1); ...
         -axis(2), axis(1), 0];
    c = cos(theta);
    rotation = c * eye(3) + (1-c) * (axis * axis.') + sin(theta) * K;
end
