function test_show_tree(previewFile)
%TEST_SHOW_TREE Verify UI hierarchy, labels and original object references.
% Optional previewFile exports the branched viewer for visual inspection.
    arguments
        previewFile (1,1) string = ""
    end
    addpath(fileparts(fileparts(mfilename('fullpath'))));
    links = struct('name', {"tip", "base", "arm", "camera"});
    joints = struct('name', {"wrist", "camera_mount", "shoulder"}, ...
        'type', {"revolute", "fixed", "continuous"}, ...
        'parent', {"arm", "base", "base"}, ...
        'child', {"tip", "camera", "arm"});
    tree = rpm.chain.robotTree(struct('links', links, 'joints', joints, 'rootLinkIndex', 2));
    [fig, view] = tree.show_tree("off");
    cleanup = onCleanup(@() delete(fig));
    drawnow;
    assert(isgraphics(fig) && strcmp(fig.Visible, 'off'));
    assert(isa(view, 'matlab.ui.container.Tree'));
    assert(isscalar(view.Children));
    rootView = view.Children;
    assert(string(rootView.Text) == "base [link]");
    assert(rootView.NodeData == tree.baseLink);
    assert(numel(rootView.Children) == 2);
    cameraJointView = rootView.Children(1);
    shoulderView = rootView.Children(2);
    assert(string(cameraJointView.Text) == "camera_mount [joint: fixed]");
    assert(string(shoulderView.Text) == "shoulder [joint: continuous]");
    assert(cameraJointView.NodeData == tree.baseLink.childJoint(1));
    assert(shoulderView.NodeData == tree.baseLink.childJoint(2));
    cameraView = cameraJointView.Children;
    armView = shoulderView.Children;
    assert(isscalar(cameraView) && isscalar(armView));
    assert(cameraView.NodeData == tree.getLink("camera"));
    assert(armView.NodeData == tree.getLink("arm"));
    wristView = armView.Children;
    tipView = wristView.Children;
    assert(string(wristView.Text) == "wrist [joint: revolute]");
    assert(wristView.NodeData == tree.getJoint("wrist"));
    assert(tipView.NodeData == tree.getLink("tip"));
    assert(isempty(tipView.Children) && isempty(cameraView.Children));
    assert(isequal(properties(tree), {'baseLink'}));
    if strlength(previewFile) > 0
        exportapp(fig, previewFile);
    end
    % A single link has one UI root and no joint nodes.
    single = rpm.chain.robotTree(struct('links', links(2), 'joints', [], 'rootLinkIndex', 1));
    [singleFig, singleView] = single.show_tree("off");
    singleCleanup = onCleanup(@() delete(singleFig));
    assert(isscalar(singleView.Children) && isempty(singleView.Children.Children));
    assert(singleView.Children.NodeData == single.baseLink);
    % Repeated calls create independent viewers without changing topology.
    [otherFig, otherView] = tree.show_tree("off");
    otherCleanup = onCleanup(@() delete(otherFig));
    assert(otherFig ~= fig && otherView.Children.NodeData == rootView.NodeData);
    fprintf('test_show_tree passed.\n');
end
