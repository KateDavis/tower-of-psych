function logGUISandbox
close all
clear
clear classes
clc

dataPath = '/Users/ben/Desktop/Labs/Gold/testData';
dataFile = '2afcDemoData.mat';
data = fullfile(dataPath, dataFile);

topsDataLog.readDataFile(data)
log = topsDataLog.theDataLog;

t = log.earliestTime;
d = log.latestTime - t;
groupsOfInterest = log.groups;
n = numel(groupsOfInterest);

g = topsGUI;
p = topsDetailPanel;
p.parentGUI = g;

clf(g.figure)
ax = axes('Parent', g.figure, ...
    'Position', [.01 .5 .98 .49], ...
    'Box', 'on', ...
    'XGrid', 'on', ...
    'XLim', t+[0,d], ...
    'YLim', [0, n*2+1], ...
    'YTick', [], ...
    'HitTest', 'off');
xlabel(ax, summarizeValue(log.clockFunction));

texts = zeros(1, n);
lines = zeros(1, n);
for ii = 1:n
    group = groupsOfInterest{ii};
    groupColor = p.getColorForString(group);
    texts(ii) = text(t, 2*ii, group, 'Parent', ax, 'Color', groupColor, ...
        'FontSize', 9, 'HitTest', 'off');
    
    groupData = log.getAllItemsFromGroupAsStruct(group);
    times = [groupData.mnemonic];
    rows = (ii*2-1)*ones(size(times));
    lines(ii) = line(times, rows, 'Parent', ax, 'Color', groupColor, ...
        'LineStyle', 'none', 'Marker', '.', 'HitTest', 'on', ...
        'ButtonDownFcn', @(obj, event)lineDetails(obj, event, log, group));
end

function lineDetails(l, event, log, group)
disp(sprintf('hit me: %s', group))
ax = get(l, 'Parent');
click = get(ax, 'CurrentPoint');
clickTime = click(1,1)
times = get(l, 'XData');
[nearest, nearestIndex] = min(abs(times-clickTime));
dataTime = times(nearestIndex);
rows = get(l, 'YData');
line(dataTime, rows(1), 'Parent', ax, 'Color', [0 0 0], ...
    'LineStyle', 'none', 'Marker', 'o', 'HitTest', 'off');

item = log.getItemFromGroupWithMnemonic(group, dataTime)