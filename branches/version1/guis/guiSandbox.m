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

item = sprintf('Cheese this man...\n...and quickly!');
name = 'a string';
fig.setCurrentItem(item, name);

% item = topsFoundation('I would have some cheese.');
% item = containers.Map();
% name = 'an objet';
% fig.setCurrentItem(item, name);