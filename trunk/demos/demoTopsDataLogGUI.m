%Continually feed fake data to topsDataLog and topsDataLogGUI
clear all
clear classes

% Start a new data log session
topsDataLog.flushAllData;

% Launch the data log gui,
%   which shows the contents of the topsDataLog
gui = topsDataLogGUI;

% groups for sample data to save to the topsDataLog
groups = { ...
    'abracadabra', ...
    'an event', ...
    'something boring happened', ...
    'something interesting happened', ...
    'xylophone', ...
    'the last event'};

% until the gui window closes, continually log events
%   they will appear in the gui
ii = 0;
while isvalid(gui)
    % log some data--the number ii--with one of the mnemoncis above
    g = groups{1+mod(ii, length(groups))};
    topsDataLog.logDataInGroup(ii, g);
    ii = ii + 1;
    pause(1 + normrnd(.1,.1))
end