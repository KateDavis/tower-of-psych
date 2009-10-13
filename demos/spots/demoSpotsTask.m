%Run the "Spots Task" demo for Tower of Psych.
%
%   demoSpotsTask configures and launches the "Spots Task" demo of Tower of
%   Psych.  It also launches the topsDataLogGUI in a separate figure.

% manage screen real estate for the task and two tops GUIs
fullScreen = get(0, 'ScreenSize');
x = .46*fullScreen(3);
y = .46*fullScreen(4);
w = .4*fullScreen(3);
h = .4*fullScreen(4);
taskPosition = [x/2 y w h];
blockGUIPosition = [0 0 w h];
logGUIPosition = [x 0 w h];

% configure the Spots Task
[spotsList, spotsTree] = configureSpotsTasks(taskPosition);

% launch the blockTreeGUI
blockGUI = topsBlockTreeGUI(spotsTree);
set(blockGUI.figure, 'Position', blockGUIPosition);

% launch the dataLogGUI
topsDataLog.flushAllData;
logGUI = topsDataLogGUI;
set(logGUI.figure, 'Position', logGUIPosition);