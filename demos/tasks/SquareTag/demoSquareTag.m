% Run SquareTagLogic through its paces.
clear
clear classes
clc

% create the logical "back end" of the SquareTag task
logic = SquareTagLogic('demo', now());
logic.nTrials = 4;
logic.nSquares = 5;

% chose which kind of audio-visual "front end" to use
av = SquareTagAVPlotter(logic);
av.initialize();

% figure out the range of the cursor
screens = get(0, 'MonitorPositions');
width = screens(1,3);
height = screens(1,4);

% map the cursor range into the unit square
%   fudge these as necessary, depending on your desktop
pointScale = [width-50 height-25];
pointOffset = [0 21];

% start playing SquareTag!
logic.startSession();
for ii = 1:logic.nTrials
    
    % initialize the logic and av objects for each trial
    logic.startTrial();
    av.doBeforeSquares();
    
    % proceed through squares, one at a time
    while strcmp(logic.nextSquare(), logic.nextOutput)
        
        % indicate which squares are already tagged
        av.doNextSquare();
        
        % wait for the next square to be tagged
        %   logic.cursorMap maps cursor location onto squares
        %   and knows which square should be tagged next
        while ~strcmp(logic.cursorMap.getOutput(true), logic.tagOutput)
            % get the latest cursor position and send it to the logic
            %   apply the unit square mapping from above
            point = get(0, 'PointerLocation');
            logic.setCursorLocation((point + pointOffset) ./ pointScale);
            
            % let the av object draw a new cursor location
            av.updateCursor();
            drawnow();
        end
    end
    
    % indicate trial completion and wait for an interval
    av.doAfterSquares();
    pause(1);
    
    % account for the completed trial
    logic.finishTrial();
end

% clean up from playing SquareTag!
logic.finishSession();
av.terminate();