function rpy = rot2rpy(rotation)
%ROT2RPY 将 Rz(yaw)*Ry(pitch)*Rx(roll) 旋转矩阵转为弧度制 RPY。
%   RPY = rpm.utils.rot2rpy(R) 返回 double 列向量 [roll; pitch; yaw]。
%   pitch 位于 [-pi/2, pi/2]，roll/yaw 位于 [-pi, pi]。
%   R 必须为正交且行列式为 +1 的实数有限 3x3 矩阵，容差为 1e-6。
%   万向节锁时固定 roll=0；等价姿态的 RPY 不一定与原输入相同。

    validateattributes(rotation, {'numeric'}, ...
        {'real', 'finite', 'size', [3, 3]}, mfilename, 'rotation');
    rotation = double(rotation);
    if norm(rotation.' * rotation - eye(3), 'fro') > 1e-6 || ...
            abs(det(rotation) - 1) > 1e-6
        error('rpm:utils:rot2rpy:InvalidRotationMatrix', ...
            'rotation 必须为正交且行列式为 +1 的 3x3 旋转矩阵（容差 1e-6）。');
    end

    cosPitch = hypot(rotation(1,1), rotation(2,1));
    pitch = atan2(-rotation(3,1), cosPitch);
    if cosPitch > 1e-10
        roll = atan2(rotation(3,2), rotation(3,3));
        yaw = atan2(rotation(2,1), rotation(1,1));
    else
        roll = 0;
        yaw = atan2(-rotation(1,2), rotation(2,2));
    end
    rpy = [roll; pitch; yaw];
end
