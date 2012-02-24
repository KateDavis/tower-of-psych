% Run SquareTagLogic through its paces
clear
clc

logic = SquareTagLogic('demo', now());

logic.startSession();
for ii = 1:logic.nTrials
    logic.startTrial();
    
    while strcmp(logic.nextSquare(), logic.nextOutput)
        classn = logic.makeClassification();
        disp([logic.currentTrial logic.currentSquare])
        pos = logic.squarePositions(logic.currentSquare,:);
        disp(pos)
    end
    
    logic.finishTrial();
end
logic.finishSession();