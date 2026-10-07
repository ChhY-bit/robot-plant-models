function test_robot_tree_frames(previewFile)
%TEST_ROBOT_TREE_FRAMES Check zero-pose frames through object references.
    arguments
        previewFile (1,1) string = ""
    end
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    links = struct('name', {'root','a','b','c','branch'});
    joints = repmat(struct('name',"",'type',"fixed",'parent',"",'child',"",'origin',[]),4,1);
    for i = 1:numel(joints), joints(i).name = "joint_" + i; end
    joints(1).parent = "root"; joints(1).child = "a";
    joints(1).origin = struct('xyz',[1;0;0],'rpy',[0;0;pi/2]);
    joints(2).parent = "a"; joints(2).child = "b";
    joints(2).origin = struct('xyz',[1;0;0],'rpy',[]);
    joints(3).parent = "b"; joints(3).child = "c"; % No origin.
    joints(4).parent = "root"; joints(4).child = "branch";
    joints(4).origin = struct('xyz',[],'rpy',[pi/2;0;0]);
    % Match load_urdf's string-valued link names.
    for i = 1:numel(links), links(i).name = string(links(i).name); end
    urdf = struct('links',links,'joints',joints,'rootLinkIndex',1);
    tree = rpm.chain.robotTree(urdf);
    fig = figure('Visible','off');
    cleanup = onCleanup(@() close(fig));
    ax = axes('Parent',fig);
    existing = plot3(ax,10,10,10,'o');
    returned = tree.show_frames([],[],fig);
    assert(returned == fig && isgraphics(existing) && ~ishold(ax));
    assert(strcmp(ax.XGrid,'on') && isequal(ax.DataAspectRatio,[1,1,1]));
    expected = [0,1,0,1,1; 0,0,0,1,1; 0,0,0,0,0];
    % Queue order is root, a, branch, b, c. Only three quiver objects.
    q = findall(ax,'Type','quiver','Tag','rpm.chain.robotTree.frame');
    assert(numel(q) == 3);
    for i = 1:3
        color = zeros(1,3); color(i) = 1;
        axis_handle = q(arrayfun(@(h) isequal(h.Color,color),q));
        positions = [axis_handle.XData(:).';axis_handle.YData(:).';axis_handle.ZData(:).'];
        assert(norm(positions-expected,'fro') < 1e-12);
    end
    xaxis = q(arrayfun(@(h) isequal(h.Color,[1,0,0]),q));
    directions = [xaxis.UData(:).';xaxis.VData(:).';xaxis.WData(:).'];
    assert(norm(directions(:,4)-[0;0.02;0]) < 1e-12);
    % Subtree T0 is explicitly the starting link's world pose.
    cla(ax); hold(ax,'on');
    T0 = [0,-1,0,1;1,0,0,0;0,0,1,0;0,0,0,1];
    tree.show_frames(T0,"a",fig);
    assert(ishold(ax));
    q = findall(ax,'Type','quiver');
    assert(numel(q(1).XData) == 3);
    assert(norm(q(1).YData(:)-[0;1;1]) < 1e-12);
    % Leaf subtree and single-link URDF still draw a frame.
    cla(ax); tree.show_frames(eye(4),tree.getLink("c"),fig);
    q = findall(ax,'Type','quiver');
    assert(numel(q) == 3 && isscalar(q(1).XData));
    single = rpm.chain.robotTree(struct('links',links(1),'joints',[],'rootLinkIndex',1));
    cla(ax); single.show_frames([],[],fig);
    assert(numel(findall(ax,'Type','quiver')) == 3);
    bad_transform = eye(4); bad_transform(1,1) = -1;
    must_error(@() tree.show_frames(bad_transform,[],fig), ...
        'rpm:robotTree:InvalidRotationMatrix');
    bad_transform = eye(4); bad_transform(4,1) = 1;
    must_error(@() tree.show_frames(bad_transform,[],fig), ...
        'rpm:robotTree:InvalidTransform');
    must_error(@() tree.show_frames([],[],ax), 'rpm:robotTree:InvalidFigure');
    must_error(@() tree.show_frames([],single.baseLink,fig), 'rpm:robotTree:InvalidLink');
    must_error(@() tree.show_frames([],2,fig), 'rpm:robotTree:InvalidLink');
    bad = urdf; bad.joints(2).child = "unknown";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf;
    bad.joints(4).parent = "c"; bad.joints(4).child = "root";
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    bad = urdf; bad.joints = bad.joints(1:3); % Unreachable branch link.
    must_error(@() rpm.chain.robotTree(bad), 'rpm:robotTree:InvalidTopology');
    % Traverse deeper than the normal recursion limit without recursive calls.
    n = 600;
    deep_links = repmat(struct('name',""),n,1);
    deep_joints = repmat(struct('name',"",'type',"fixed",'parent',"",'child',""),n-1,1);
    for i = 1:n
        deep_links(i).name = "link_" + i;
        if i < n
            deep_joints(i).name = "joint_" + i;
            deep_joints(i).parent = "link_" + i;
            deep_joints(i).child = "link_" + (i+1);
        end
    end
    deep = rpm.chain.robotTree(struct('links',deep_links,'joints',deep_joints,'rootLinkIndex',1));
    cla(ax); deep.show_frames([],[],fig);
    q = findall(ax,'Type','quiver');
    assert(numel(q) == 3 && numel(q(1).XData) == n);
    % Display uses temporary poses, without changing the node state.
    assert(isempty(tree.baseLink.world_T) && isempty(tree.getLink("b").world_T));
    if strlength(previewFile) > 0
        cla(ax); tree.show_frames([],[],fig);
        title(ax, 'Robot link frames at zero joint displacement');
        xlabel(ax, 'X'); ylabel(ax, 'Y'); zlabel(ax, 'Z');
        exportgraphics(ax, previewFile);
    end
    fprintf('test_robot_tree_frames passed.\n');
end

function must_error(action,identifier)
    try
        action();
    catch cause
        assert(strcmp(cause.identifier,identifier),'%s',cause.message);
        return;
    end
    error('Expected error %s.',identifier);
end
