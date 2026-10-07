function test_axis2rot()
%TEST_AXIS2ROT Check known axis-angle rotations, normalization and bad inputs.
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    assert(isequal(rpm.utils.axis2rot([1;0;0], 0), eye(3)));
    must_close(rpm.utils.axis2rot([1,0,0], pi/2), [1,0,0; 0,0,-1; 0,1,0]);
    must_close(rpm.utils.axis2rot([0,1,0], pi/2), [0,0,1; 0,1,0; -1,0,0]);
    must_close(rpm.utils.axis2rot([0,1,0], -pi/2), [0,0,-1; 0,1,0; 1,0,0]);
    must_close(rpm.utils.axis2rot([0,0,1], pi/2), [0,-1,0; 1,0,0; 0,0,1]);
    % A 120-degree rotation around [1,1,1] cycles the coordinate axes.
    expected = [0,0,1; 1,0,0; 0,1,0];
    rotation = rpm.utils.axis2rot([1;1;1], 2*pi/3);
    assert(isa(rotation, 'double') && isequal(size(rotation), [3,3]));
    must_close(rotation, expected);
    must_close(rpm.utils.axis2rot([1;1;1], pi), ...
        [-1,2,2; 2,-1,2; 2,2,-1]/3);
    must_close(rpm.utils.axis2rot([5,5,5], 2*pi/3), rotation);
    must_close(rpm.utils.axis2rot([1e300,1e300,1e300], 2*pi/3), rotation);
    must_close(rpm.utils.axis2rot([1e-300,1e-300,1e-300], 2*pi/3), rotation);
    must_close(rpm.utils.axis2rot([1;2;-3], -0.7), ...
        rpm.utils.axis2rot([-1;-2;3], 0.7));
    assert(isa(rpm.utils.axis2rot(single([0,0,1]), single(0)), 'double'));
    % The axis is invariant, and a general rotation must be proper orthogonal.
    axis = [1;2;-3];
    rotation = rpm.utils.axis2rot(axis, 0.7);
    must_close(rotation * axis, axis);
    must_close(rotation.' * rotation, eye(3));
    assert(abs(det(rotation)-1) < 1e-12);

    badAxes = {[], [1,0], zeros(3,3), [NaN,0,1], [Inf,0,1], [1i,0,1], "xyz"};
    for k = 1:numel(badAxes), must_fail(@() rpm.utils.axis2rot(badAxes{k}, 1)); end
    badAngles = {[], [0,1], NaN, Inf, 1i, "1"};
    for k = 1:numel(badAngles), must_fail(@() rpm.utils.axis2rot([0;0;1], badAngles{k})); end
    must_fail(@() rpm.utils.axis2rot([0;0;0], 0), 'rpm:utils:axis2rot:InvalidAxis');
    fprintf('test_axis2rot passed.\n');
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
