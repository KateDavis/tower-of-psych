% Run SquareTagLogic through its paces
clear
clc

logic = SquareTagLogic('demo', now());


logic.startSession();
for ii = 1:logic.nTrials
    logic.startTrial();
    
    while strcmp(logic.nextSquare(), logic.nextOutput)
        v = {logic.cursorMap.outputs.value};
        disp(v)
    end
    disp(' ')
    
    logic.finishTrial();
end
logic.finishSession();