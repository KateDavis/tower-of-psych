function treeSandbox()
%%
asdf;

fig = figure();
parent = uipanel( ...
    'Parent', fig, ...
    'Units', 'normalized', ...
    'Position', [.1 .1 .8 .8]);

rootNode = uitreenode('v0', 'primate', 'primate', [], false);
rootNode.add(uitreenode('v0', 'ape', 'ape', [], false));
rootNode.add(uitreenode('v0', 'moneky', 'monkey', [], false));
[tree, container] = uitree('v0', fig, ...
    'Root', rootNode, ...
    ...'ExpandFcn', @treeExpand, ...
    ...'SelectionChangeFcn', @treeSelect, ...
    'ExpandFcn', @(obj, value)zeros(0,0), ...
    'SelectionChangeFcn', @(obj, value)disp(''), ...
    'Parent', parent);
tree.expand(rootNode);

jTree = tree.getTree();
jColor = java.awt.Color(1, 0, 0);
jTree.setBackground(jColor);

jRenderer = jTree.getCellRenderer();
jColor = java.awt.Color(0, 0, 1);
jRenderer.setBackgroundNonSelectionColor(jColor);


% initial parent is ignored
set(container, ...
    'Parent', parent, ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1]);
%%

function nodes = treeExpand(obj, value)
offspring = sprintf('more %s', value);
nodes = uitreenode('v0', offspring, offspring, [], false);

function treeSelect(obj, value)
%disp(value)