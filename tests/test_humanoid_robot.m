function test_humanoid_robot()
%TEST_HUMANOID_ROBOT Check composition with the shared robot tree.
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    links = struct('name', {"tip", "pelvis"});
    joint = struct('name', "hip", 'type', "revolute", ...
        'parent', "pelvis", 'child', "tip", ...
        'origin', struct('xyz', [1; 0; 0], 'rpy', []));
    urdf = struct('name', "fixture", 'links', links, 'joints', joint, 'rootLinkIndex', 2);
    robot = rpm.humanoid_robot(urdf);
    tree = robot.Tree;
    assert(isa(tree, 'rpm.chain.robotTree'));
    assert(tree.baseLink == tree.getLink("pelvis"));
    assert(tree.baseLink.childJoint(1) == tree.getJoint("hip"));
    assert(tree.getJoint("hip").childLink == tree.getLink("tip"));
    hip = tree.getJoint("hip");
    assert(isequal(hip.q, 0) && isequal(hip.dq, 0));
    % Verify main-class write access without relying on in-progress recursion.
    rootOnly = rpm.humanoid_robot(struct('links', links(2), 'joints', [], 'rootLinkIndex', 1));
    rootOnly.kinematic_update();
    assert(isequal(rootOnly.Tree.baseLink.world_T, eye(4)));
    assert(isempty(tree.baseLink.world_T));
    assert(isempty(hip.world_T) && isempty(tree.getLink("tip").world_T));
    % Even a reference returned by lookup must remain externally read-only.
    nodes = {tree, tree.baseLink, hip};
    fields = {{'baseLink'}, {'description', 'parentJoint', 'childJoint', 'world_T'}, ...
        {'description', 'parentLink', 'childLink', 'world_T', 'q', 'dq'}};
    for i = 1:numel(nodes)
        for j = 1:numel(fields{i})
            must_deny_assignment(nodes{i}, fields{i}{j});
        end
    end
    must_deny_assignment(tree.baseLink, 'name');
    must_deny_assignment(hip, 'name');
    must_deny_assignment(hip, 'type');
    fig = figure('Visible', 'off');
    cleanup = onCleanup(@() delete(fig));
    tree.show_frames([], [], fig);
    q = findall(fig, 'Type', 'quiver', 'Tag', 'rpm.chain.robotTree.frame');
    assert(numel(q) == 3);
    assert(isequal(q(1).XData(:), [0; 1]));
    % Invalid topology fails during construction, rather than during display.
    bad = urdf; bad.joints.child = "missing";
    try
        rpm.humanoid_robot(bad);
    catch cause
        assert(strcmp(cause.identifier, 'rpm:robotTree:InvalidTopology'));
        fprintf('test_humanoid_robot passed.\n');
        return;
    end
    error('Expected invalid topology to be rejected.');
end

function must_deny_assignment(node, property)
    value = node.(property);
    try
        node.(property) = value;
    catch cause
        assert(contains(cause.identifier, 'SetProhibited'), '%s', cause.message);
        return;
    end
    error('External assignment to %s must be denied.', property);
end
