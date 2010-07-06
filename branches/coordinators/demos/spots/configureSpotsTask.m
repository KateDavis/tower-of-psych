function [spotsTree, spotsList] = configureSpotsTask(figurePosition)
%Configure tops for a demo psychophysics task, with two task types
%
%   [spotsTree, spotsList] = configureSpotsTask(figurePosition)
%
%   spotsTree is a topsTreeNode object which organizes tasks and trials.
%   spotsTree and spotsList "know about" each other.
%
%   spotsTree.run(); will start the "spots" experiment.
%
%   spotsList is a topsGroupedList object which holds all the data needed
%   to run the "spots" experiment.
%
%   figurePosition is optional.  It should contain a postion rectangle of
%   the form [x, y, w, h]--where to put the expermient figure window.
%
%   The "spots" experiment is a demo for the Tower of Psych.  It uses the
%   tops foundataion classes to implement an experiment similar to a real
%   psychophysics experiment.
%
%   There are two tasks: a reaction time (rt) task and a fixed viewing time
%   (fvt) task.  In both, the subject (you) uses the mouse to click on one
%   of several spots that appear.
%
%   For the rt task, the trials go like this:
%       -several blue spots and one red spot appear in the figure.
%       -at any time, the subject may click on one of the spots.  The red
%       spot is "correct" and the rest "incorrect".
%       -the spots disappear and the figure is blank for an interval
%       -the next trial begins...
%
%   For the fvt task, the trials go like this:
%       -several blue and one red spot appear in the figure, then quickly
%       all turn black
%       -after the spots are black, the subject may click on one of the
%       spots.  The spot that was red is "correct", the rest "incorrect".
%       -the spots disappear and the figure is blank for an interval.
%       -the next trial begins.
%
%   Several experiment parameters may be controlled by editing values near
%   the top of configureSpotsTask.m.
%
% See also, demoSpotsTask, topsGroupedList, topsTreeNode

% 2009 benjamin.heasly@gmail.com
%   Seattle, WA

if ~nargin
    figurePosition = [];
end


%%%
%%% experiment parameters to edit:
%%%
spotRows = 5;
spotColumns = 5;
spotCount = 6;
spotViewingTime = .25;

intertrialInterval = 1;
trialsInARow = 10;

taskRepetitions = 2;
taskOrder = 'random'; % 'sequential' or 'random'


%%%
%%% foundataion classes
%%%

% topsGroupedList
% spotsList list will hold all parameters and other data for the spots
%   experiment, somewhat like the ROOT_STRUCT of dotsx
spotsList = topsGroupedList;
spotsList.addItemToGroupWithMnemonic(figurePosition, 'spots', 'figurePosition');
spotsList.addItemToGroupWithMnemonic(spotRows, 'spots', 'spotRows');
spotsList.addItemToGroupWithMnemonic(spotColumns, 'spots', 'spotColumns');
spotsList.addItemToGroupWithMnemonic(spotCount, 'spots', 'spotCount');
spotsList.addItemToGroupWithMnemonic(spotViewingTime, 'spots', 'spotViewingTime');
spotsList.addItemToGroupWithMnemonic(intertrialInterval, 'spots', 'intertrialInterval');
spotsList.addItemToGroupWithMnemonic(trialsInARow, 'spots', 'trialsInARow');
spotsList.addItemToGroupWithMnemonic(taskRepetitions, 'spots', 'taskRepetitions');
spotsList.addItemToGroupWithMnemonic(taskOrder, 'spots', 'taskOrder');

% topsCallList
% spotsCalls can hold function calls, with arguments, that can be
% called as a batch.  spotsCalls just needs to call drawnow()
spotsCalls = topsCallList;
spotsCalls.fevalables.add({@drawnow});
spotsList.addItemToGroupWithMnemonic(spotsCalls, 'spots', 'spotsCalls');

% topsTreeNode
% spotsTree manages the main figure window
%   it also will have the rt and fvt tasks as its "children"
spotsTree = topsTreeNode;
spotsTree.name = 'spots';
spotsTree.iterations = taskRepetitions;
spotsTree.iterationMethod = taskOrder;
spotsTree.startFevalable = {@spotsSetup, spotsList, 'spots'};
spotsTree.finishFevalable = {@spotsTearDown, spotsList, 'spots'};
spotsList.addItemToGroupWithMnemonic(spotsTree, 'spots', 'spotsTopLevel');

% rtTask manages the reaction time task
%   it will also have a reaction time *trial* as its child
rtTask = spotsTree.newChild;
taskName = 'rt_task';
rtTask.name = taskName;
rtTask.iterations = trialsInARow;
rtTask.startFevalable = {@rtTaskSetup, spotsList, taskName};
rtTask.finishFevalable = {@rtTaskTearDown, spotsList, taskName};
spotsList.addItemToGroupWithMnemonic(rtTask, taskName, 'rtTask');

% rtTrial manages individual reaction time trials
rtTrial = rtTask.newChild;
rtTrial.name = 'rt_trial';
rtTrial.startFevalable = {@rtTrialSetup, spotsList, taskName};
rtTrial.addChild(spotsCalls);
rtTrial.finishFevalable = {@rtTrialTeardown, spotsList, taskName};
spotsList.addItemToGroupWithMnemonic(rtTrial, taskName, 'rtTrial');

% fvtTask manages the fixed viewing time task
%   it will also have a fixed viewing time time *trial* as its child
fvtTask = spotsTree.newChild;
taskName = 'fvt_task';
fvtTask.name = taskName;
fvtTask.iterations = trialsInARow;
fvtTask.startFevalable = {@fvtTaskSetup, spotsList, taskName};
fvtTask.finishFevalable = {@fvtTaskTearDown, spotsList, taskName};
spotsList.addItemToGroupWithMnemonic(fvtTask, taskName, 'fvtTask');

% another bottom level block, to manage a fixed viewing time trial
fvtTrial = fvtTask.newChild;
fvtTrial.name = 'fvt_trial';
fvtTrial.startFevalable = {@fvtTrialSetup, spotsList, taskName};
fvtTrial.addChild(spotsCalls);
fvtTrial.finishFevalable = {@fvtTrialTeardown, spotsList, taskName};
spotsList.addItemToGroupWithMnemonic(fvtTrial, taskName, 'fvtTrial');


%%%
%%% Functions for the overall experiment (the top level)
%%%
function spotsSetup(spotsList, modeName)
fp = spotsList.getItemFromGroupWithMnemonic(modeName, 'figurePosition');
fig = figure( ...
    'Name', 'See Spots', ...
    'Units', 'normalized', ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');
if ~isempty(fp)
    set(fig, 'Position', fp);
end
spotsList.addItemToGroupWithMnemonic(fig, modeName, 'figure');

ax = axes('Parent', fig, ...
    'Units', 'normalized', ...
    'Position', [.01 .01 .98 .98], ...
    'XLim', [-1 1], ...
    'YLim', [-1 1], ...
    'XTick', [], ...
    'YTick', [], ...
    'Box', 'on');
spotsList.addItemToGroupWithMnemonic(ax, modeName, 'axes');

function spotsTearDown(spotsList, modeName)
fig = spotsList.getItemFromGroupWithMnemonic(modeName, 'figure');
close(fig);

function waitForUserClick(spotsList, message)
fig = spotsList.getItemFromGroupWithMnemonic('spots', 'figure');
button = uicontrol( ...
    'Parent', fig, ...
    'Style', 'togglebutton', ...
    'Value', false, ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1], ...
    'String', message);
while get(button, 'Value') == false
    drawnow;
end
delete(button);
drawnow


%%%
%%% Functions for the rt task (a middle level)
%%%
function rtTaskSetup(spotsList, modeName)
% build stimulus spots in the axes
ax = spotsList.getItemFromGroupWithMnemonic('spots', 'axes');
n = spotsList.getItemFromGroupWithMnemonic('spots', 'spotCount');
r = spotsList.getItemFromGroupWithMnemonic('spots', 'spotRows');
c = spotsList.getItemFromGroupWithMnemonic('spots', 'spotColumns');
shuffle = randperm(r*c);
area = [-1 -1 2 2];
for ii = 1:n
    m = shuffle(ii);
    pos = subposition(area, r, c, mod(m,c)+1, ceil(m/c));
    topsDataLog.logDataInGroup(pos, 'made new spot');
    spots(ii) = rectangle('Parent', ax, ...
        'Position', pos,...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'Visible', 'off');
end
spotsList.addItemToGroupWithMnemonic(spots, modeName, 'spots');

msg = 'Click the red spot--as soon as you can.';
waitForUserClick(spotsList, msg);


function rtTaskTearDown(spotsList, modeName)
spots = spotsList.getItemFromGroupWithMnemonic(modeName, 'spots');
delete(spots);


%%%
%%% Functions for the rt trial (a bottom level)
%%%
function rtTrialSetup(spotsList, modeName)
spotsCalls = spotsList.getItemFromGroupWithMnemonic('spots', 'spotsCalls');
spots = spotsList.getItemFromGroupWithMnemonic(modeName, 'spots');
redSpot = spots(ceil(rand*length(spots)));
set(spots, ...
    'FaceColor', [0 0 1], ...
    'ButtonDownFcn', {@rtTrialSpotCallback, spotsCalls, redSpot});
set(redSpot, 'FaceColor', [1 0 0]);
set(spots, 'Visible', 'on');
drawnow;

function rtTrialSpotCallback(spot, event, spotsCalls, redSpot)
topsDataLog.logDataInGroup(get(spot, 'Position'), 'picked spot');
if spot==redSpot
    topsDataLog.logDataInGroup([], 'correct');
else
    topsDataLog.logDataInGroup([], 'incorrect');
end
spotsCalls.isRunning = false;

function rtTrialTeardown(spotsList, modeName)
spots = spotsList.getItemFromGroupWithMnemonic(modeName, 'spots');
iti = spotsList.getItemFromGroupWithMnemonic('spots', 'intertrialInterval');
set(spots, 'Visible', 'off');
pause(iti);


%%%
%%% Functions for the fixed viewing time task
%%%
function fvtTaskSetup(spotsList, modeName)
% build stimulus spots in the axes
ax = spotsList.getItemFromGroupWithMnemonic('spots', 'axes');
n = spotsList.getItemFromGroupWithMnemonic('spots', 'spotCount');
r = spotsList.getItemFromGroupWithMnemonic('spots', 'spotRows');
c = spotsList.getItemFromGroupWithMnemonic('spots', 'spotColumns');
shuffle = randperm(r*c);
area = [-1 -1 2 2];
for ii = 1:n
    m = shuffle(ii);
    pos = subposition(area, r, c, mod(m,c)+1, ceil(m/c));
    topsDataLog.logDataInGroup(pos, 'made new spot');
    spots(ii) = rectangle('Parent', ax, ...
        'Position', pos,...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'LineStyle', ':', ...
        'LineWidth', 2, ...
        'Visible', 'off');
end
spotsList.addItemToGroupWithMnemonic(spots, modeName, 'spots');

msg = 'Click the red spot--after it turns black.';
waitForUserClick(spotsList, msg);

function fvtTaskTearDown(spotsList, modeName)
spots = spotsList.getItemFromGroupWithMnemonic(modeName, 'spots');
delete(spots);


%%%
%%% Functions for the fixed viewing time trial
%%%
function fvtTrialSetup(spotsList, modeName)
spotsCalls = spotsList.getItemFromGroupWithMnemonic('spots', 'spotsCalls');
vt = spotsList.getItemFromGroupWithMnemonic('spots', 'spotViewingTime');

spots = spotsList.getItemFromGroupWithMnemonic(modeName, 'spots');
redSpot = spots(ceil(rand*length(spots)));
set(spots, ...
    'FaceColor', [0 0 1], ...
    'ButtonDownFcn', {@fvtTrialSpotCallback, spotsCalls, redSpot});
set(redSpot, 'FaceColor', [1 0 0]);
set(spots, 'Visible', 'on', 'HitTest', 'off');
pause(vt);
set(spots, 'FaceColor', [0 0 0], 'HitTest', 'on');
drawnow;

function fvtTrialSpotCallback(spot, event, spotsCalls, redSpot)
topsDataLog.logDataInGroup(get(spot, 'Position'), 'picked spot');
if spot==redSpot
    topsDataLog.logDataInGroup([], 'correct');
else
    topsDataLog.logDataInGroup([], 'incorrect');
end
spotsCalls.isRunning = false;

function fvtTrialTeardown(spotsList, modeName)
spots = spotsList.getItemFromGroupWithMnemonic(modeName, 'spots');
iti = spotsList.getItemFromGroupWithMnemonic('spots', 'intertrialInterval');
set(spots, 'Visible', 'off');
pause(iti);