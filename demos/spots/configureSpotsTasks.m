function [spotsList, spotsTree] = configureSpotsTasks(figurePosition)
%Configure tops for a demo psychophysics task, with two task types
%
%   [spotsList, spotsTree] = configureSpotsTasks(figurePosition);
%
%   spotsList is a topsModalList object which holds all the data needed to
%   run the "spots" experiment.
%
%   spotsTree is a topsBlockTree object which organizes tasks and trials.
%   It uses it and spotsList "know about" each other.
%
%   spotsTree.run(); will start the task
%
%
% See also, demoSpotsTask; topsModalList, topsBlockTree

% 2009 benjamin.heasly@gmail.com
%   Seattle, WA

if ~nargin
    figurePosition = [];
end

% this list will hold all data for the spots task
%   it's somewhat like the ROOT_STRUCT of DotsX
spotsList = topsModalList;

% remember figure location for this "spots experiment"
spotsList.addItemToModeWithMnemonicWithPrecedence(figurePosition, 'spots', 'figurePosition');

% this loop will call functions during a trial
%   each task can configure it, if necessary
spotsLoop = topsFunctionLoop;
spotsLoop.addFunctionToModeWithPrecedence({@drawnow}, 'spots', 1);
spotsList.addItemToModeWithMnemonicWithPrecedence(spotsLoop, 'spots', 'spotsLoop');

% the top level block, to manage the overall "spots experiment"
spotsTree = topsBlockTree;
spotsTree.name = 'spots';
spotsTree.blockBeginFcn = {@spotsSetup, spotsList, 'spots'};
spotsTree.blockEndFcn = {@spotsTearDown, spotsList, 'spots'};
spotsList.addItemToModeWithMnemonicWithPrecedence(spotsTree, 'spots', 'spotsTopLevel');

% a middle level block, to manage a reaction time task
taskName = 'rt_task';
rtTask = topsBlockTree;
rtTask.name = taskName;
rtTask.iterations = 10;
rtTask.blockBeginFcn = {@rtTaskSetup, spotsList, taskName};
rtTask.blockEndFcn = {@rtTaskTearDown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(rtTask, taskName, 'rtTask');

% a bottom level block, to manage reaction time trials
rtTrial = topsBlockTree;
rtTrial.name = 'rt_trial';
rtTrial.blockBeginFcn = {@rtTrialSetup, spotsList, taskName};
rtTrial.blockActionFcn = {@spotsLoop.runInModeForDuration, 'spots', 1};
rtTrial.blockEndFcn = {@rtTrialTeardown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(rtTrial, taskName, 'rtTrial');

% attach the task to the experiment!!
%   attach the trial to the task!!!!!!!
spotsTree.addChild(rtTask);
rtTask.addChild(rtTrial);

% another middle level block, to manage a fixed viewing time task
taskName = 'fix_task';
fixTask = topsBlockTree;
fixTask.name = taskName;
fixTask.iterations = 10;
fixTask.blockBeginFcn = {@fixTaskSetup, spotsList, taskName};
fixTask.blockEndFcn = {@fixTaskTearDown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(fixTask, taskName, 'fixTask');

% another bottom level block, to manage a fixed viewing time trial
fixTrial = topsBlockTree;
fixTrial.name = 'fix_trial';
fixTrial.blockBeginFcn = {@fixTrialSetup, spotsList, taskName};
fixTrial.blockActionFcn = {@spotsLoop.runInModeForDuration, 'spots', 1};
fixTrial.blockEndFcn = {@fixTrialTeardown, spotsList, taskName};
spotsList.addItemToModeWithMnemonicWithPrecedence(fixTrial, taskName, 'fixTrial');

% attach the task to the experiment!!
%   attach the trial to the task!!!!!!!
spotsTree.addChild(fixTask);
fixTask.addChild(fixTrial);

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
n = 5;
d = .1;
positions = [linspace(-1,1-d,n)', ...
    linspace(-1,1-d,n)', ...
    d*ones(n,1), ...
    d*ones(n,1)];
for ii = 1:n
    spots(ii) = rectangle('Parent', ax, ...
        'Position', positions(ii,:), ...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'Visible', 'off');
end

% use "replace" rather than "add", since this could get called twice and we
% don't want redundant spots created
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
if spot==redSpot
    topsDataLog.logMnemonicWithData('correct');
else
    topsDataLog.logMnemonicWithData('incorrect');
end
spotsLoop.proceed = false;

function rtTrialTeardown(spotsList, modeName)
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
set(spots, 'Visible', 'off');
pause(1);

%%%
%%% Functions for the fixed viewing task (a middle level)
%%%
function fixTaskSetup(spotsList, modeName)
% build stimulus spots in the axes
ax = spotsList.getItemFromModeWithMnemonic('spots', 'axes');
n = 5;
d = .1;
positions = [linspace(-1,1-d,n)', ...
    linspace(-1,1-d,n)', ...
    d*ones(n,1), ...
    d*ones(n,1)];
for ii = 1:n
    spots(ii) = rectangle('Parent', ax, ...
        'Position', positions(ii,:), ...
        'Curvature', [1 1], ...
        'FaceColor', [1 1 1], ...
        'LineStyle', ':', ...
        'LineWidth', 2, ...
        'Visible', 'off');
end
spotsList.replaceItemInModeWithMnemonicWithPrecedence(spots, modeName, 'spots');

uiwait(warndlg({'Click the red spot,' 'after it turns black.'}, 'Ready to begin?'));

function fixTaskTearDown(spotsList, modeName)
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
delete(spots);


%%%
%%% Functions for the fixed viewing trial (a bottom level)
%%%
function fixTrialSetup(spotsList, modeName)
spotsLoop = spotsList.getItemFromModeWithMnemonic('spots', 'spotsLoop');
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
redSpot = spots(ceil(rand*length(spots)));
set(spots, ...
    'FaceColor', [0 0 1], ...
    'ButtonDownFcn', {@fixTrialSpotCallback, spotsLoop, redSpot});
set(redSpot, 'FaceColor', [1 0 0]);
set(spots, 'Visible', 'on', 'HitTest', 'off');
pause(.25);
set(spots, 'FaceColor', [0 0 0], 'HitTest', 'on');
drawnow;

function fixTrialSpotCallback(spot, event, spotsLoop, redSpot)
if spot==redSpot
    topsDataLog.logMnemonicWithData('correct');
else
    topsDataLog.logMnemonicWithData('incorrect');
end
spotsLoop.proceed = false;

function fixTrialTeardown(spotsList, modeName)
spots = spotsList.getItemFromModeWithMnemonic(modeName, 'spots');
set(spots, 'Visible', 'off');
pause(1);