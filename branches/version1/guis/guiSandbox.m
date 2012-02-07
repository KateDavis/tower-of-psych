%%
asdf;

fig = topsFigure('george');

bl = topsPanel(fig);
set(bl.pan, 'BackgroundColor', fig.colors(1,:));

br = topsPanel(fig);
set(br.pan, 'BackgroundColor', fig.colors(2,:));

t = topsPanel(fig);
set(t.pan, 'BackgroundColor', fig.colors(3,:));

fig.setPanels({bl br;t t}, [3 7], [4 6])

%%
asdf;

fig = topsFigure('smappy');
pan = topsInfoPanel(fig);
fig.setPanels({pan})

name = 'this item';

items = { ...
    sprintf('Cheese this man...\n...and quickly!'), ...
    topsFoundation('I would have some cheese.'), ...
    containers.Map(), ...
    struct('a', 'flowers', 'ggg', 4), ...
    {'gg', containers.Map(), 44, false}, ...
    false(1,100), ...
    eye(9)};

for ii = 1:numel(items)
    fig.setCurrentItem(items{ii}, name);
    pause();
end

close all