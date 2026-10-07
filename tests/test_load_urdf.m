function test_load_urdf(reference_file)
%TEST_LOAD_URDF Check conversion; optionally also read the G1 reference URDF.
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    path = string(tempname) + ".urdf";
    cleanup = onCleanup(@() delete(path));
    xml = "<robot name=""fixture"">" + ...
        "<mujoco><compiler meshdir=""meshes""/></mujoco><gazebo/>" + ...
        "<material name=""dark""><color rgba=""0.2 0.2 0.2 1""/></material>" + ...
        "<!-- <joint name=""ignored""/> -->" + ...
        "<joint name=""hinge"" type=""revolute""><parent link=""base""/>" + ...
        "<child link=""tip""/><origin xyz=""1 2 3"" rpy=""0 0.2 0""/>" + ...
        "<axis xyz=""0 1 0""/><limit lower=""-1"" upper=""2"" effort=""3"" velocity=""4""/>" + ...
        "<mimic joint=""other"" multiplier=""2"" offset=""0.1""/></joint>" + ...
        "<link name=""base""><inertial><mass value=""2""/>" + ...
        "<inertia ixx=""1"" ixy=""2.1E-06"" ixz=""0"" iyy=""2"" iyz=""0"" izz=""3""/>" + ...
        "</inertial><visual><geometry><mesh filename=""meshes/base.STL""/></geometry>" + ...
        "<material name=""dark""/></visual><visual><geometry><box size=""1 2 3""/>" + ...
        "</geometry></visual><collision><geometry><sphere radius=""1""/></geometry>" + ...
        "</collision><collision><geometry><cylinder radius=""1"" length=""2""/>" + ...
        "</geometry></collision></link><link name=""tip""/></robot>";
    write_xml(path, xml);
    lastwarn('');
    u = rpm.utils.load_urdf(char(path));
    [warning_message, ~] = lastwarn();
    assert(isempty(warning_message));
    assert(isequal(fieldnames(u), {'name';'sourceFile';'links';'joints';'rootLinkIndex'}));
    assert(u.rootLinkIndex == 1 && u.links(u.rootLinkIndex).name == "base");
    assert(u.name == "fixture" && isfile(u.sourceFile));
    assert(numel(u.links) == 2 && isscalar(u.joints));
    assert(u.joints.parent == "base" && u.joints.child == "tip");
    assert(isequal(u.joints.origin.xyz, [1;2;3]));
    assert(isequal(u.joints.axis, [0;1;0]));
    assert(u.joints.mimic.joint == "other" && u.joints.mimic.multiplier == 2);
    assert(u.links(1).inertial.inertia.ixy == 2.1e-6);
    assert(numel(u.links(1).visual) == 2 && numel(u.links(1).collision) == 2);
    assert(isequal(u.links(1).visual(1).material.color.rgba, [0.2;0.2;0.2;1]));
    assert(isempty(u.links(1).visual(1).geometry.mesh.scale));
    assert(isempty(u.links(2).inertial) && isempty(u.links(2).visual));
    % Every existing pose-bearing element has a complete origin.
    must_zero_origin(u.links(1).inertial.origin);
    for i = 1:numel(u.links(1).visual)
        must_zero_origin(u.links(1).visual(i).origin);
    end
    for i = 1:numel(u.links(1).collision)
        must_zero_origin(u.links(1).collision(i).origin);
    end
    % Omitted origin, empty origin, xyz-only and rpy-only all get defaults.
    origin_cases = {"", "<origin/>", '<origin xyz="1 2 3"/>', '<origin rpy="0.1 0.2 0.3"/>'};
    for i = 1:numel(origin_cases)
        origin_xml = string(origin_cases{i});
        xml_defaults = '<robot><link name="a"><inertial>' + origin_xml + ...
            '</inertial><visual>' + origin_xml + '</visual><collision>' + ...
            origin_xml + '</collision></link><link name="b"/>' + ...
            '<joint name="j" type="fixed"><parent link="a"/><child link="b"/>' + ...
            origin_xml + '</joint></robot>';
        write_xml(path, xml_defaults);
        defaults = rpm.utils.load_urdf(path);
        expected_xyz = zeros(3,1); expected_rpy = zeros(3,1);
        if i == 3, expected_xyz = [1;2;3]; end
        if i == 4, expected_rpy = [0.1;0.2;0.3]; end
        origins = {defaults.joints.origin, defaults.links(1).inertial.origin, ...
            defaults.links(1).visual.origin, defaults.links(1).collision.origin};
        for j = 1:numel(origins)
            assert(isequal(origins{j}.xyz, expected_xyz));
            assert(isequal(origins{j}.rpy, expected_rpy));
        end
        % Missing physical data is distinct from a known zero value.
        assert(isempty(defaults.links(1).inertial.mass));
        assert(isempty(defaults.links(1).inertial.inertia));
        assert(isempty(defaults.joints.limit) && isempty(defaults.joints.axis));
        assert(isempty(defaults.links(2).inertial));
        tree = rpm.chain.robotTree(defaults);
        assert(isequal(tree.getJoint("j").description.origin, defaults.joints.origin));
    end
    write_xml(path, "<robot><link name=""a""/><link name=""b""/><joint name=""j"" type=""fixed"">" + ...
        '<parent link="a"/><child link="b"/><origin/><origin/></joint></robot>');
    must_error(@() rpm.utils.load_urdf(path), 'rpm:load_urdf:DuplicateElement');
    write_xml(path, '<robot><link name="a"><visual><origin xyz=""/></visual></link></robot>');
    must_error(@() rpm.utils.load_urdf(path), 'rpm:load_urdf:InvalidAttribute');
    % Omitted axes use the URDF default for each axis-based joint type.
    for joint_type = ["revolute", "continuous", "prismatic", "planar", "fixed", "floating"]
        write_xml(path, "<robot><link name=""a""/><link name=""b""/>" + ...
            "<joint name=""j"" type=""" + joint_type + """><parent link=""a""/>" + ...
            "<child link=""b""/></joint></robot>");
        axis_defaults = rpm.utils.load_urdf(path);
        if any(joint_type == ["fixed", "floating"])
            assert(isempty(axis_defaults.joints.axis));
        else
            assert(isequal(axis_defaults.joints.axis, [1;0;0]));
        end
    end
    % Explicit axes are preserved by the reader and normalized by the node.
    write_xml(path, '<robot><link name="a"/><link name="b"/>' + ...
        "<joint name=""j"" type=""prismatic""><parent link=""a""/>" + ...
        "<child link=""b""/><axis xyz=""0 2 0""/></joint></robot>");
    axis_defaults = rpm.utils.load_urdf(path);
    assert(isequal(axis_defaults.joints.axis, [0;2;0]));
    axis_tree = rpm.chain.robotTree(axis_defaults);
    assert(isequal(axis_tree.getJoint("j").description.axis, [0;1;0]));
    axis_robot = rpm.humanoid_robot(axis_defaults);
    axis_robot.kinematic_update();
    assert(isequal(axis_robot.Tree.getLink("b").world_T, eye(4)));
    write_xml(path, '<robot><joint><axis xyz="1 bad 0"/></joint></robot>');
    must_error(@() rpm.utils.load_urdf(path), 'rpm:load_urdf:InvalidAttribute');
    write_xml(path, '<not_robot/>');
    must_error(@() rpm.utils.load_urdf(path), 'rpm:load_urdf:InvalidRoot');
    write_xml(path, '<robot><link><inertial/><inertial/></link></robot>');
    must_error(@() rpm.utils.load_urdf(path), 'rpm:load_urdf:DuplicateElement');
    write_xml(path, '<robot><link name="only"/></robot>');
    single = rpm.utils.load_urdf(path);
    assert(single.rootLinkIndex == 1);
    chain = '<robot><link name="pelvis"/><link name="world"/>' + ...
        "<joint name=""base"" type=""floating""><parent link=""world""/>" + ...
        "<child link=""pelvis""/></joint></robot>";
    write_xml(path, chain);
    floating = rpm.utils.load_urdf(path);
    assert(floating.rootLinkIndex == 2);
    write_xml(path, '<robot><link name="pelvis"/><!-- <link name="world"/> -->' + ...
        "<!-- <joint name=""base"" type=""floating""><parent link=""world""/>" + ...
        "<child link=""pelvis""/></joint> --></robot>");
    commented = rpm.utils.load_urdf(path);
    assert(commented.links(commented.rootLinkIndex).name == "pelvis");
    invalid = {
        '<robot/>'
        '<robot><link name="a"/><link name="a"/></robot>'
        '<robot><link name="a"/><link name="b"/></robot>'
        '<robot><link name="a"/><joint name="j"><parent link="a"/><child link="missing"/></joint></robot>'
        '<robot><link name="a"/><joint name="j"><parent link="a"/><child link="a"/></joint></robot>'
        '<robot><link name="a"/><joint name="j"/></robot>'
        '<robot><link name="root"/><link name="a"/><link name="b"/><joint name="j1"><parent link="a"/><child link="b"/></joint><joint name="j2"><parent link="b"/><child link="a"/></joint></robot>'
        '<robot><link name="a"/><link name="b"/><joint name="j1"><parent link="a"/><child link="b"/></joint><joint name="j2"><parent link="a"/><child link="b"/></joint></robot>'
    };
    for i = 1:numel(invalid)
        write_xml(path, invalid{i});
        must_error(@() rpm.utils.load_urdf(path), 'rpm:load_urdf:InvalidTopology');
    end
    if nargin > 0
        g1 = rpm.utils.load_urdf(reference_file);
        assert(g1.name == "g1_23dof");
        has_world = any([g1.links.name] == "world");
        if has_world
            assert(g1.links(g1.rootLinkIndex).name == "world");
            assert(any([g1.joints.name] == "floating_base_joint"));
        else
            assert(g1.links(g1.rootLinkIndex).name == "pelvis");
        end
        assert(numel(g1.links) == 33 + has_world && numel(g1.joints) == 32 + has_world);
        assert(sum([g1.joints.type] == "revolute") == 23);
        assert(sum([g1.joints.type] == "fixed") == 9);
    end
    fprintf('test_load_urdf passed.\n');
end

function must_zero_origin(origin)
    assert(isequal(origin.xyz, zeros(3,1)));
    assert(isequal(origin.rpy, zeros(3,1)));
end

function write_xml(path, xml)
    fid = fopen(path, 'w');
    assert(fid ~= -1);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', char(xml));
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

