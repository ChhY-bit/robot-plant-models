function test_rpy_rotation()
%TEST_RPY_ROTATION Check axis convention, equivalent poses and invalid inputs.
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    assert(isequal(rpm.utils.rpy2rot([0; 0; 0]), eye(3)));
    assert(isequal(rpm.utils.rot2rpy(eye(3)), zeros(3,1)));
    % Known rotations pin down axis signs, order and radians.
    must_close(rpm.utils.rpy2rot([pi/2, 0, 0]), [1,0,0; 0,0,-1; 0,1,0]);
    must_close(rpm.utils.rpy2rot([0, pi/2, 0]), [0,0,1; 0,1,0; -1,0,0]);
    must_close(rpm.utils.rpy2rot([0, 0, pi/2]), [0,-1,0; 1,0,0; 0,0,1]);
    must_close(rpm.utils.rpy2rot([pi/2, 0, pi/2]), [0,0,1; 1,0,0; 0,1,0]);
    must_close(rpm.utils.rot2rpy([0,-1,0; 1,0,0; 0,0,1]), [0; 0; pi/2]);

    % Include angles outside the inverse's canonical pitch range.
    poses = [0.3,-0.4,1.2; -2.1,0.7,-2.8; pi,0,-pi; ...
        0.2,2.0,-0.9; -0.5,-2.3,0.8];
    for k = 1:size(poses,1)
        rotation = rpm.utils.rpy2rot(poses(k,:));
        restored = rpm.utils.rot2rpy(rotation);
        assert(isequal(size(restored), [3,1]));
        assert(abs(restored(2)) <= pi/2);
        must_close(rpm.utils.rpy2rot(restored), rotation);
    end
    % At both gimbal locks, compare rotations because RPY is not unique.
    for pitch = [-pi/2, pi/2]
        rotation = rpm.utils.rpy2rot([0.7; pitch; -1.1]);
        restored = rpm.utils.rot2rpy(rotation);
        assert(restored(1) == 0);
        must_close(rpm.utils.rpy2rot(restored), rotation);
        for offset = [-1e-7, 1e-7]
            rotation = rpm.utils.rpy2rot([0.7; pitch+offset; -1.1]);
            must_close(rpm.utils.rpy2rot(rpm.utils.rot2rpy(rotation)), rotation);
        end
    end
    % Both vector orientations and numeric classes are supported.
    must_close(rpm.utils.rpy2rot([0.3; -0.4; 1.2]), rpm.utils.rpy2rot(poses(1,:)));
    assert(isa(rpm.utils.rpy2rot(single([0,0,0])), 'double'));
    assert(isa(rpm.utils.rot2rpy(single(eye(3))), 'double'));
    assert(isequal(rpm.utils.rpy2rot(int32([0;0;0])), eye(3)));

    badRpy = {[], [0,0], zeros(3,3), [NaN,0,0], [Inf,0,0], [1i,0,0], "abc"};
    for k = 1:numel(badRpy), must_fail(@() rpm.utils.rpy2rot(badRpy{k})); end
    badRot = {[], eye(4), [NaN,0,0;0,1,0;0,0,1], ...
        [Inf,0,0;0,1,0;0,0,1], eye(3)+1i, "abc"};
    for k = 1:numel(badRot), must_fail(@() rpm.utils.rot2rpy(badRot{k})); end
    must_fail(@() rpm.utils.rot2rpy(diag([-1,1,1])), ...
        'rpm:utils:rot2rpy:InvalidRotationMatrix');
    must_fail(@() rpm.utils.rot2rpy(diag([2,1,1])), ...
        'rpm:utils:rot2rpy:InvalidRotationMatrix');
    fprintf('test_rpy_rotation passed.\n');
end

function must_close(actual, expected)
    assert(norm(actual-expected, 'fro') < 1e-12);
end

function must_fail(action, identifier)
    try
        action();
    catch cause
        if nargin > 1, assert(strcmp(cause.identifier, identifier), '%s', cause.message); end
        return;
    end
    error('Expected invalid input to be rejected.');
end
