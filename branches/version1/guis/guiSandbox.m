%%
asdf;

fig = topsFigure('george');

bl = topsPanel(fig);
set(bl.pan, 'BackgroundColor', fig.colors(1,:));

br = topsPanel(fig);
set(br.pan, 'BackgroundColor', fig.colors(2,:));

t = topsPanel(fig);
set(t.pan, 'BackgroundColor', fig.colors(3,:));

%fig.setPanels({bl br;t t}, [3 7], [4 6])
fig.setPanels({bl br})

%%
asdf;

fig = topsFigure('smappy');
infoPan = topsInfoPanel(fig);
drillDownPan = topsDrillDownPanel(fig);
fig.setPanels({drillDownPan infoPan});

name = 'thisItem';

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

for ii = 1:numel(items)
    drillDownPan.setBaseItem(items{ii}, name);
    fig.setCurrentItem(items{ii}, name);
    pause();
end

close all

%%
asdf;
fig = topsFigure('hoo');
table = fig.makeUITable();
set(table, ...
    'Data', num2cell(eye(3)), ...
    'ColumnName', {'aaaaaaaaaaaaaaaaaaaaaaaaaa', 'b', 'c'})