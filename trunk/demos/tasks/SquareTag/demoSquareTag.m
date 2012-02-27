% Demonstrate SquareTagLogic and SquareTagAV without user input.
clear
clear classes
close all
clc

% create the logical "back end" of the SquareTag task
logic = SquareTagLogic('demo', now());
logic.nTrials = 4;
logic.nSquares = 5;

% chose which kind of audio-visual "front end" to use
av = SquareTagAVPlotter(logic);
av.initialize();

% choose how long it takes the computer to tag each square
tagSteps = 10;

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
        
        % peek at the location of the current square
        %   plan programmatic movement towards it
        squarePos = logic.squarePositions(logic.currentSquare, :);
        cursorTarget = squarePos(1:2) + squarePos(3:4)/2;
        cursorGap = cursorTarget - logic.getCursorLocation();
        cursorDelta = cursorGap / tagSteps;
        
        % wait for the next square to be tagged
        %   logic.cursorMap maps cursor location onto squares
        %   and knows which square should be tagged next
        while ~strcmp(logic.cursorMap.getOutput(true), logic.tagOutput)
            % programmatically step the cursor towards the next square
            cursorPos = logic.getCursorLocation() + cursorDelta;
            logic.setCursorLocation(cursorPos);
            
            % let the av object draw a new cursor location
            av.updateCursor();
            drawnow();
        end
    end
    
    % indicate trial completion and wait for an interval
    av.doAfterSquares();
    pause(0.5);
    
    % account for the completed trial
    logic.finishTrial();
end

% clean up from playing SquareTag!
logic.finishSession();
av.terminate();