%% test for circular references
close all
clear
clear classes

fig = topsFigure('circus');
pan = topsTreePanel(fig);
drawnow();

%% Put the drill-down GUI through its paces
close all
clear
clear classes

items = { ...
    sprintf('Cheese this man...\n...and quickly!'), ...
    'topsFigure', ...
    @disp, ...
    topsFoundation('I would have some cheese.'), ...
    containers.Map(), ...
    struct('a', 'flowers', 'ggg', 4), ...
    struct('Firstly', {'McFirst', 'Firstington'}, 'Secondly', {2, [2 2]}), ...
    {'gg', containers.Map(), 44, false}, ...
    false(1,100), ...
    eye(9)};

nItems = numel(items);
for ii = 1:nItems
    name = sprintf('item %d/%d', ii, nItems);
    topsGUIUtilities.openBasicGUI(items{ii}, name);
end

%% Make sure the figure can do panel layout
close all
clear
clear classes

fig = topsFigure('george');

bl = topsPanel(fig);
set(bl.pan, 'BackgroundColor', fig.colors(1,:));

br = topsPanel(fig);
set(br.pan, 'BackgroundColor', fig.colors(2,:));

t = topsPanel(fig);
set(t.pan, 'BackgroundColor', fig.colors(3,:));

fig.usePanels({bl br; t t}, [3 7], [4 6])

%% Look at some 2D tables for struct and cell array data
close all
clear
clear classes

fig = topsFigure('hoo');
structPan = topsTablePanel(fig);
cellPan = topsTablePanel(fig);
infoPan = topsInfoPanel(fig);
fig.usePanels({structPan cellPan; infoPan infoPan}, [1 1]);

s = struct('Firstly', {'McFirst', 'Firstington'}, 'Secondly', {2, [2 2]});
structPan.isBaseItemTitle = true;
structPan.setBaseItem(s, 'myStruct');

nums = zeros(3, 2, 5, 1);
nums(1:end) = 1:numel(nums);
c = num2cell(nums);
c{1} = 'cottage cheese';
c{end} = containers.Map();
cellPan.isBaseItemTitle = true;
cellPan.setBaseItem(c, 'myCell');

% Josh had a matlab hang while clicking during this example.
% He has:
%   Matlab 7.13.0.564
%   Java 1.6.0
%   OS X 10.6.8
% The hang didn't repeat itself after restarting Matlab.

%% Try out a grouped list panel
close all
clear
clear classes

gl = topsGroupedList();
gl.name = 'myList';
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox c');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox d');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox e');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox f');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox g');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox h');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox i');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox j');
gl.addItemToGroupWithMnemonic(1, 'group 1', 'this is a very quick fox k');
gl.addItemToGroupWithMnemonic(48, 'group 2', 8);
gl.addItemToGroupWithMnemonic(49, 'group 2', 9);
gl.addItemToGroupWithMnemonic(39, 'group 2', -1);
gl.addItemToGroupWithMnemonic(containers.Map(4, 4), 'group 2', 7);
fig = gl.gui();

%% try out a runnables panel
close all
clear
clear classes

fig = topsFigure('runnablalia');
runPan = topsRunnablesPanel(fig);
fig.usePanels({runPan});

r = topsRunnableComposite();
r.name = 'cheese';

c = topsRunnableComposite();
c.name = 'ilchester';

sm = topsStateMachine();
sm.name = 'machine';

cl = topsCallList();
cl.name = 'list';

e = topsEnsemble();
e.name = 'ensemble';

t = topsTreeNode();
t.name = 'tree';

st = topsTreeNode();
st.name = 'sub tree';

r.addChild(c);
r.addChild(t);

c.addChild(sm);
c.addChild(cl);
c.addChild(e);

t.addChild(st);

runPan.setBaseItem(r, r.name);

%% try out a data log panel
close all
clear
clear classes

topsDataLog.logDataInGroup('myData', 'singulars');
topsDataLog.logDataInGroup('yournData', 'singulars');
topsDataLog.logDataInGroup('ournData', 'plurals');
topsDataLog.logDataInGroup('theirnData', 'plurals');
%topsDataLog.logDataInGroup(47, 'taco time!!');

fig = topsFigure('loggins');
logPan = topsDataLogPanel(fig);
infoPan = topsInfoPanel(fig);
fig.usePanels({infoPan; logPan}, [2 8]);