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
    assert(numel(u.links) == 2 && numel(u.joints) == 1);
    assert(u.joints.parent == "base" && u.joints.child == "tip");
    assert(isequal(u.joints.origin.xyz, [1;2;3]));
    assert(isequal(u.joints.axis, [0;1;0]));
    assert(u.joints.mimic.joint == "other" && u.joints.mimic.multiplier == 2);
    assert(u.links(1).inertial.inertia.ixy == 2.1e-6);
    assert(numel(u.links(1).visual) == 2 && numel(u.links(1).collision) == 2);
    assert(isequal(u.links(1).visual(1).material.color.rgba, [0.2;0.2;0.2;1]));
    assert(isempty(u.links(1).visual(1).geometry.mesh.scale));
    assert(isempty(u.links(2).inertial) && isempty(u.links(2).visual));
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

