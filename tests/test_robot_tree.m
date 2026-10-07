function test_robot_tree()
%TEST_ROBOT_TREE Check URDF integration, identity, traversal and bad inputs.
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    path = string(tempname) + ".urdf";
    cleanup = onCleanup(@() delete(path));
    % Both arrays are deliberately out of topological order; root is #2.
    xml = '<robot name="branched">' + ...
        "<link name=""tip""/><link name=""base"">" + ...
        "<visual><geometry><box size=""1 2 3""/></geometry></visual></link>" + ...
        "<link name=""arm""/><link name=""branch""/>" + ...
        "<joint name=""wrist"" type=""fixed""><parent link=""arm""/>" + ...
        "<child link=""tip""/><origin xyz=""1 2 3""/></joint>" + ...
        "<joint name=""branch_joint"" type=""floating""><parent link=""base""/>" + ...
        "<child link=""branch""/></joint>" + ...
        "<joint name=""shoulder"" type=""revolute""><parent link=""base""/>" + ...
        "<child link=""arm""/><axis xyz=""0 1 0""/>" + ...
        "<limit lower=""-1"" upper=""2"" effort=""3"" velocity=""4""/>" + ...
        "</joint></robot>";
    write_xml(path, xml);
    urdf = rpm.utils.load_urdf(path);
    tree = rpm.chain.robotTree(urdf);
    assert(isequal(properties(tree), {'baseLink'}));
    assert(isscalar(metaclass(tree).PropertyList));
    assert(tree.baseLink == tree.getLink("base"));
    assert(isempty(tree.baseLink.parentJoint));
    assert(isa(tree.baseLink.childJoint, 'rpm.chain.jointNode'));
    assert(numel(tree.baseLink.childJoint) == 2);
    % Dot access follows the same branch as kinematic propagation.
    branch = tree.baseLink.childJoint(1).childLink;
    arm = tree.baseLink.childJoint(2).childLink;
    tip = tree.baseLink.childJoint(2).childLink.childJoint(1).childLink;
    wrist = arm.childJoint(1);
    assert(branch == tree.getLink("branch") && arm == tree.getLink("arm"));
    assert(tip == tree.getLink("tip") && wrist == tree.getJoint("wrist"));
    assert(tip.parentJoint.parentLink.parentJoint.parentLink == tree.baseLink);
    assert(findprop(tip, 'name').Dependent);
    assert(findprop(wrist, 'name').Dependent && findprop(wrist, 'type').Dependent);
    for k = 1:numel(urdf.links)
        link = tree.getLink(urdf.links(k).name);
        assert(isequal(link.description, urdf.links(k)));
        assert(isempty(link.world_T));
    end
    for k = 1:numel(urdf.joints)
        joint = tree.getJoint(urdf.joints(k).name);
        assert(isa(joint, 'rpm.chain.jointNode'));
        assert(isequal(joint.description, urdf.joints(k)));
        assert(joint.type == urdf.joints(k).type);
        assert(joint.parentLink == tree.getLink(joint.description.parent));
        assert(joint.childLink == tree.getLink(joint.description.child));
        assert(joint.childLink.parentJoint == joint);
        assert(any(joint.parentLink.childJoint == joint));
        assert(isempty(joint.world_T));
        assert(isequal(joint.q, 0) && isequal(joint.dq, 0));
    end
    assert(isa(tip.childJoint, 'rpm.chain.jointNode') && isequal(size(tip.childJoint), [0, 1]));
    % A link and a joint may share a name: their namespaces are separate.
    shared = urdf; shared.joints(1).name = "arm";
    other = rpm.chain.robotTree(shared);
    assert(isa(other.getLink("arm"), 'rpm.chain.linkNode'));
    assert(other.getLink("arm").childJoint(1).description.name == "arm");
    assert(other.getJoint("arm") == other.getLink("arm").childJoint(1));
    assert(isa(other.getJoint("arm"), 'rpm.chain.jointNode'));
    shared = urdf; shared.joints(2).name = "arm";
    other = rpm.chain.robotTree(shared);
    assert(other.getJoint("arm") == other.baseLink.childJoint(1));
    assert(isa(other.getLink("arm"), 'rpm.chain.linkNode'));
    shared = urdf; shared.joints(1).name = "base";
    other = rpm.chain.robotTree(shared);
    assert(other.getJoint("base") == other.getLink("arm").childJoint(1));
    assert(other.getLink("base") == other.baseLink);
    assert(other.getLink("base") ~= tree.baseLink);
    must_error(@() tree.getLink("missing"), 'rpm:robotTree:UnknownLink');
    must_error(@() tree.getJoint("missing"), 'rpm:robotTree:UnknownJoint');
    must_error(@() tree.getLink("wrist"), 'rpm:robotTree:UnknownLink');
    must_error(@() tree.getJoint("base"), 'rpm:robotTree:UnknownJoint');
    must_error(@() tree.getJoint("tip"), 'rpm:robotTree:UnknownJoint');
    must_error(@() tree.getLink(["base", "arm"]), 'rpm:robotTree:InvalidName');
    must_error(@() tree.getJoint(" "), 'rpm:robotTree:InvalidName');
    % Topology cannot be modified through public node properties/methods.
    must_fail(@() change_parent(tip, wrist));
    must_fail(@() tip.setParentJoint(wrist));
    must_fail(@() wrist.connect(tree.baseLink, tip));

    write_xml(path, '<robot name="single"><link name="only"/></robot>');
    single = rpm.chain.robotTree(rpm.utils.load_urdf(path));
    assert(isempty(single.baseLink.childJoint));
    assert(isempty(single.baseLink.parentJoint));
    assert(isa(single.baseLink.childJoint, 'rpm.chain.jointNode'));
    assert(single.getLink("only") == single.baseLink);
    must_error(@() single.getJoint("only"), 'rpm:robotTree:UnknownJoint');
    must_error(@() single.getJoint("missing"), 'rpm:robotTree:UnknownJoint');

    bad = urdf; bad.links(1).name = "base";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.joints(1).name = "shoulder";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.joints(1).child = "unknown";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.joints(1).child = "arm";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.joints(1).child = "branch";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.rootLinkIndex = 1;
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.joints = bad.joints(1);
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    % One root plus a disconnected cycle must also be rejected.
    bad = urdf; bad.joints(3).parent = "tip";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.rootLinkIndex = NaN;
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidInput');
    must_error(@() rpm.chain.robotTree(struct()), 'rpm:robotTree:InvalidInput');
    % Direct structs receive the same axis guarantees as URDF-loaded nodes.
    for joint_type = ["revolute", "continuous", "prismatic", "planar"]
        node = rpm.chain.jointNode(struct('name', "axis_test", 'type', joint_type));
        assert(isequal(node.description.axis, [1;0;0]));
        for axis_scale = [1, 1e300, 1e-300]
            node = rpm.chain.jointNode(struct('name', "axis_test", 'type', joint_type, ...
                'axis', axis_scale*[0,-2,0]));
            assert(isequal(node.description.axis, [0;-1;0]));
        end
    end
    bad = urdf; bad.joints(3).axis = [0;0;0];
    must_error(@() rpm.chain.robotTree(bad), 'rpm:jointNode:InvalidAxis');
    bad = urdf; bad.joints(3).axis = [NaN;0;1];
    must_fail(@() rpm.chain.robotTree(bad));
    bad.joints(3).axis = [1,0];
    must_fail(@() rpm.chain.robotTree(bad));
    fprintf('test_robot_tree passed.\n');
end

function write_xml(path, xml)
    fid = fopen(path, 'w');
    assert(fid ~= -1);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', char(xml));
end

function change_parent(link, joint)
    link.parentJoint = joint;
end

function must_fail(action)
    try
        action();
    catch
        return;
    end
    error('Expected access to be denied.');
end

function must_error(action, identifier)
    try
        action();
    catch cause
        assert(strcmp(cause.identifier, identifier), '%s', cause.message);
        return;
    end
    error('Expected error %s.', identifier);
end
