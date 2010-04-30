%Run the "Spots Task" demo for Tower of Psych.
%
%   demoSpotsTask configures and launches the "Spots Task" demo of Tower of
%   Psych.  It also launches the topsDataLogGUI in a separate figure.

% manage screen real estate for the task and two tops GUIs
x = .46;
y = .46;
w = .4;
h = .4;
taskPosition = [0 y w h];
blockGUIPosition = [0 0 w h];
logGUIPosition = [x 0 w 2*h];

% configure the Spots Task
[spotsTree, spotsList] = configureSpotsTasks(taskPosition);

% launch the blockTreeGUI
blockGUI = topsBlockTreeGUI(spotsTree);
set(blockGUI.figure, 'Position', blockGUIPosition);

% launch the dataLogGUI
topsDataLog.flushAllData;
logGUI = topsDataLogGUI;
set(logGUI.figure, 'Position', logGUIPosition);