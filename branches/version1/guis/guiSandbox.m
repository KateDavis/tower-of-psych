%% Put the drill-down GUI through its paces
close all
clear

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
    f = topsMakeDrillDownGUI(items{ii}, name);
end

%% Make sure the figure can do panel layout
close all
clear

fig = topsFigure('george');

bl = topsPanel(fig);
set(bl.pan, 'BackgroundColor', fig.colors(1,:));

br = topsPanel(fig);
set(br.pan, 'BackgroundColor', fig.colors(2,:));

t = topsPanel(fig);
set(t.pan, 'BackgroundColor', fig.colors(3,:));

fig.setPanels({bl br; t t}, [3 7], [4 6])

%% Look at some 2D tables for struct and cell array data
close all
clear all

fig = topsFigure('hoo');
structPan = topsTablePanel(fig);
cellPan = topsTablePanel(fig);
infoPan = topsInfoPanel(fig);
fig.setPanels({structPan cellPan; infoPan infoPan}, [1 1]);

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

% Josh had a matlab hang in this example
% 7.13.0.564
% 1.6.0
% os x 10.6.8

% click on title to set baseItem as currentItem

%% Try out a grouped list panel

close all
clear all

gl = topsGroupedList();
gl.name = 'myList';
gl.addItemToGroupWithMnemonic(48, 'group 1', 8);
gl.addItemToGroupWithMnemonic(49, 'group 1', 9);
gl.addItemToGroupWithMnemonic(39, 'group 1', -1);
gl.addItemToGroupWithMnemonic('ghjg', 'group 2', 'cheese');
gl.addItemToGroupWithMnemonic('rfior', 'group 2', 'my jesus cheese');
gl.addItemToGroupWithMnemonic(topsFoundation('albert'), 'group 2', 'bert');
gl.addItemToGroupWithMnemonic(containers.Map(4, 4), 'group 2', 'mahp');
fig = topsMakeGroupedListGUI(gl);


