%Run the "Spots Task" demo for Tower of Psych.
%
%   demoSpotsTask configures and launches the "Spots Task" demo of Tower of
%   Psych.  It also launches the topsDataLogGUI in a separate figure.
    
% launch the dataLogGUI
topsDataLog.flushAllData;
logGUI = topsDataLogGUI;

% manage screen real estate
logFigurePosition = get(logGUI.figure, 'Position');
spotsFigurePosition = logFigurePosition + [.5*logFigurePosition(3), 0 0 0];
logFigurePosition = logFigurePosition - [.5*logFigurePosition(3), 0 0 0];
set(logGUI.figure, 'Position', logFigurePosition);

% configure the Spots Task
[spotsList, spotsTree] = configureSpotsTasks(spotsFigurePosition);

% launch the Spots Task
spotsTree.run;