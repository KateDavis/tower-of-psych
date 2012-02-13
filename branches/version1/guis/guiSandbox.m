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

fig.setPanels({bl br;t t}, [3 7], [4 6])

%% Look at some uitables
close all
clear all

fig = topsFigure('hoo');

s = struct('Firstly', {'McFirst', 'Firstington'}, 'Secondly', {2, [2 2]});
[tableData, tableHeaders] = ...
    topsGUIUtilities.makeTableForStructArray(s, fig.colors);

structTable = fig.makeUITable();
set(structTable, ...
    'Position', [0 0 .5 1], ...
    'Data', tableData, ...
    'ColumnName', tableHeaders)

nums = zeros(3, 2, 5, 2);
nums(1:end) = 1:numel(nums);
c = num2cell(nums);
c{1} = 'cottage cheese';
c{end} = containers.Map();
tableData = topsGUIUtilities.makeTableForCellArray(c, fig.colors);

cellTable = fig.makeUITable();
set(cellTable, ...
    'Position', [.5 0 .5 1], ...
    'Data', tableData, ...
    'ColumnName', 'numbered', ...
    'RowName', 'numbered')

%% Try out a grouped list panel

close all
clear all

gl = topsGroupedList();
gl.name = 'myList';
gl.addItemToGroupWithMnemonic(45, 1, 8);
gl.addItemToGroupWithMnemonic('ghjg', 2, 'cheese');
gl.addItemToGroupWithMnemonic('rfior', 2, 'my jesus cheese');
gl.addItemToGroupWithMnemonic(topsFoundation('albert'), 2, 'bert');
gl.addItemToGroupWithMnemonic(containers.Map(4, 4), 2, 'mahp');
fig = topsMakeGroupedListGUI(gl);


