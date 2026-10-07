function rotation = rpy2rot(rpy)
%RPY2ROT 将弧度制 [roll; pitch; yaw] 转为 3x3 主动旋转矩阵。
%   R = rpm.utils.rpy2rot(RPY) 接受三个元素的行向量或列向量。
%   使用 URDF 约定 R = Rz(yaw) * Ry(pitch) * Rx(roll)，返回 double。

    validateattributes(rpy, {'numeric'}, ...
        {'real', 'finite', 'vector', 'numel', 3}, mfilename, 'rpy');
    c = cos(double(rpy));
    s = sin(double(rpy));
    Rx = [1,0,0; 0,c(1),-s(1); 0,s(1),c(1)];
    Ry = [c(2),0,s(2); 0,1,0; -s(2),0,c(2)];
    Rz = [c(3),-s(3),0; s(3),c(3),0; 0,0,1];
    rotation = Rz * Ry * Rx;
end
