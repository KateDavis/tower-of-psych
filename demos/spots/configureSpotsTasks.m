function [spotsList, spotsTree] = configureSpotsTasks(figurePosition)
%Configure tops for a demo psychophysics task, with two task types
%
%   [spotsList, spotsTree] = configureSpotsTasks(figurePosition);
%
%   spotsList is a topsModalList object which holds all the data needed to
%   run the "spots" experiment.
%
%   spotsTree is a topsBlockTree object which organizes tasks and trials.
%   spotsTree and spotsList "know about" each other.
%
%   spotsTree.run(); will start the "spots" experiment.
%
%   figurePosition is optional.  It should contain a postion rectangle of
%   the form [x, y, w, h] for where to put the expermient figure window.
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
%   the top of configureSpotsTasks.m.
%
% See also, demoSpotsTask; topsModalList, topsBlockTree

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
taskOrder = 'sequential'; % 'sequential' or 'random'


%%%
%%% foundataion classes
%%%

% topsModalList
% spotsList list will hold all parameters and other data for the spots
%   experiment, somewhat like the ROOT_STRUCT of dotsx
spotsList = topsModalList;
spotsList.addItemToModeWithMnemonicWithPrecedence(figurePosition, 'spots', 'figurePosition');
spotsList.addItemToModeWithMnemonicWithPrecedence(spotRows, 'spots', 'spotRows');
spotsList.addItemToModeWithMnemonicWithPrecedence(spotColumns, 'spots', 'spotColumns');
spotsList.addItemToModeWithMnemonicWithPrecedence(spotCount, 'spots', 'spotCount');
spotsList.addItemToModeWithMnemonicWithPrecedence(spotViewingTime, 'spots', 'spotViewingTime');
spotsList.addItemToModeWithMnemonicWithPrecedence(intertrialInterval, 'spots', 'intertrialInterval');
spotsList.addItemToModeWithMnemonicWithPrecedence(trialsInARow, 'spots', 'trialsInARow');
spotsList.addItemToModeWithMnemonicWithPrecedence(taskRepetitions, 'spots', 'taskRepetitions');
spotsList.addItemToModeWithMnemonicWithPrecedence(taskOrder, 'spots', 'taskOrder');

% topsFunctionLoop
% function loops can multiple call functions repeatedly, during a trial
%   spotsLoop just needs call drawnow(), over and over.
spotsLoop = topsFunctionLoop;
spotsLoop.addFunctionToModeWithPrecedence({@drawnow}, 'spots', 1);
spotsList.addItemToModeWithMnemonicWithPrecedence(spotsLoop, 'spots', 'spotsLoop');

% topsBlockTree
% spotsTree manages the main figure window
%   it also will have the rt and fvt tasks as its "children"
spotsTree = topsBlockTree;
spotsTree.name = 'spots';
spotsTree.iterations = taskRepetitions;
spotsTree.iterationMethod = taskOrder;
spotsTree.blockBeginFcn = {@spotsSetup, spotsList, 'spots'};
spotsTree.blockEndFcn = {@spotsTearDown, spotsList, 'spots'};
spotsList.addItemToModeWithMnemonicWithPrecedence(spotsTree, 'spots', 'spotsTopLevel');

% rtTask manages the reaction time task
%   it will also have a reaction time *trial* as its child
taskName = 'rt_task';
rtTask = topsBlockTree;
rtTask.name = taskName;
rtTask.iterations = trialsInARow;
rtTask.blockBeginFcn = {@rtTaskSetup, spotsList, taskName};
rtTask.blockEndFcn = {@rtTaskTearDown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(rtTask, taskName, 'rtTask');
spotsTree.addChild(rtTask);

% rtTrial manages individual reaction time trials
rtTrial = topsBlockTree;
rtTrial.name = 'rt_trial';
rtTrial.blockBeginFcn = {@rtTrialSetup, spotsList, taskName};
rtTrial.blockActionFcn = {@spotsLoop.runInModeForDuration, 'spots', 1};
rtTrial.blockEndFcn = {@rtTrialTeardown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(rtTrial, taskName, 'rtTrial');
rtTask.addChild(rtTrial);

% fvtTask manages the fixed viewing time task
%   it will also have a fixed viewing time time *trial* as its child
taskName = 'fvt_task';
fvtTask = topsBlockTree;
fvtTask.name = taskName;
fvtTask.iterations = trialsInARow;
fvtTask.blockBeginFcn = {@fvtTaskSetup, spotsList, taskName};
fvtTask.blockEndFcn = {@fvtTaskTearDown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(fvtTask, taskName, 'fvtTask');

% another bottom level block, to manage a fixed viewing time trial
fvtTrial = topsBlockTree;
fvtTrial.name = 'fvt_trial';
fvtTrial.blockBeginFcn = {@fvtTrialSetup, spotsList, taskName};
fvtTrial.blockActionFcn = {@spotsLoop.runInModeForDuration, 'spots', 1};
fvtTrial.blockEndFcn = {@fvtTrialTeardown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(fvtTrial, taskName, 'fvtTrial');

% attach the task to the experiment!!
%   attach the trial to the task!!!!!!!
spotsTree.addChild(fvtTask);
fvtTask.addChild(fvtTrial);


%%%
%%% Functions for the overall experiment (the top level)
%%%
function spotsSetup(spotsList, modeName)
fp = spotsList.getItemFromModeWithMnemonic(modeName, 'figurePosition');
fig = figure( ...
    'ToolBar', 'none', ...
    'MenuBar', 'none');
if ~isempty(fp)
    set(fig, 'Position', fp);
end
spotsList.addItemToModeWithMnemonicWithPrecedence(fig, modeName, 'figure');

ax = axes('Parent', fig, ...
    'Units', 'normalized', ...
    'Position', [.01 .01 .98 .98], ...
    'XLim', [-1 1], ...
    'YLim', [-1 1], ...
    'XTick', [], ...
    'YTick', [], ...
    'Box', 'on');
spotsList.addItemToModeWithMnemonicWithPrecedence(ax, modeName, 'axes');

function spotsTearDown(spotsList, modeName)
fig = spotsList.getItemFromModeWithMnemonic(modeName, 'figure');
close(fig);


%%%
%%% Functions for the rt task (a middle level)
%%%
function rtTaskSetup(spotsList, modeName)
% build stimulus spots in the axes
ax = spotsList.getItemFromModeWithMnemonic('spots', 'axes');
n = spotsList.getItemFromModeWithMnemonic('spots', 'spotCount');
r = spotsList.getItemFromModeWithMnemonic('spots', 'spotRows');
c = spotsList.getItemFromModeWithMnemonic('spots', 'spotColumns');
shuffle = randperm(r*c);
area = [-1 -1 2 2];
for ii = 1:n
    m = shuffle(ii);
    pos = subposition(area, r, c, mod(m,c)+1, ceil(m/c));
    topsDataLog.logMnemonicWithData('made new spot', pos);
    spots(ii) = rectangle('Parent', ax, ...
        'Position', pos,...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'Visible', 'off');
end

% use "replace" rather than "add", since this could get called twice and we
% don't want to replace any existing spots
spotsList.replaceItemInModeWithMnemonicWithPrecedence(spots, modeName, 'spots');

uiwait(warndlg({'Click the red spot,' 'as soon as you can.'}, 'Ready to begin?'));

function rtTaskTearDown(spotsList, modeName)
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
delete(spots);


%%%
%%% Functions for the rt trial (a bottom level)
%%%
function rtTrialSetup(spotsList, modeName)
spotsLoop = spotsList.getItemFromModeWithMnemonic('spots', 'spotsLoop');
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
redSpot = spots(ceil(rand*length(spots)));
set(spots, ...
    'FaceColor', [0 0 1], ...
    'ButtonDownFcn', {@rtTrialSpotCallback, spotsLoop, redSpot});
set(redSpot, 'FaceColor', [1 0 0]);
set(spots, 'Visible', 'on');
drawnow;

function rtTrialSpotCallback(spot, event, spotsLoop, redSpot)
topsDataLog.logMnemonicWithData('picked spot', get(spot, 'Position'));
if spot==redSpot
    topsDataLog.logMnemonicWithData('correct');
else
    topsDataLog.logMnemonicWithData('incorrect');
end
spotsLoop.proceed = false;

function rtTrialTeardown(spotsList, modeName)
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
iti = spotsList.getItemFromModeWithMnemonic('spots', 'intertrialInterval');
set(spots, 'Visible', 'off');
pause(iti);


%%%
%%% Functions for the fixed viewing time task
%%%
function fvtTaskSetup(spotsList, modeName)
% build stimulus spots in the axes
ax = spotsList.getItemFromModeWithMnemonic('spots', 'axes');
n = spotsList.getItemFromModeWithMnemonic('spots', 'spotCount');
r = spotsList.getItemFromModeWithMnemonic('spots', 'spotRows');
c = spotsList.getItemFromModeWithMnemonic('spots', 'spotColumns');
shuffle = randperm(r*c);
area = [-1 -1 2 2];
for ii = 1:n
    m = shuffle(ii);
    pos = subposition(area, r, c, mod(m,c)+1, ceil(m/c));
    topsDataLog.logMnemonicWithData('made new spot', pos);
    spots(ii) = rectangle('Parent', ax, ...
        'Position', pos,...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'LineStyle', ':', ...
        'LineWidth', 2, ...
        'Visible', 'off');
end
spotsList.replaceItemInModeWithMnemonicWithPrecedence(spots, modeName, 'spots');

uiwait(warndlg({'Click the red spot,' 'after it turns black.'}, 'Ready to begin?'));

function fvtTaskTearDown(spotsList, modeName)
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
delete(spots);


%%%
%%% Functions for the fixed viewing time trial
%%%
function fvtTrialSetup(spotsList, modeName)
spotsLoop = spotsList.getItemFromModeWithMnemonic('spots', 'spotsLoop');
vt = spotsList.getItemFromModeWithMnemonic('spots', 'spotViewingTime');

spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
redSpot = spots(ceil(rand*length(spots)));
set(spots, ...
    'FaceColor', [0 0 1], ...
    'ButtonDownFcn', {@fvtTrialSpotCallback, spotsLoop, redSpot});
set(redSpot, 'FaceColor', [1 0 0]);
set(spots, 'Visible', 'on', 'HitTest', 'off');
pause(vt);
set(spots, 'FaceColor', [0 0 0], 'HitTest', 'on');
drawnow;

function fvtTrialSpotCallback(spot, event, spotsLoop, redSpot)
topsDataLog.logMnemonicWithData('picked spot', get(spot, 'Position'));
if spot==redSpot
    topsDataLog.logMnemonicWithData('correct');
else
    topsDataLog.logMnemonicWithData('incorrect');
end
spotsLoop.proceed = false;

function fvtTrialTeardown(spotsList, modeName)
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
iti = spotsList.getItemFromModeWithMnemonic('spots', 'intertrialInterval');
set(spots, 'Visible', 'off');
pause(iti);