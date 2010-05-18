clear
clear classes
clc

% should use a tops-only example
[tree, list] = configureDotris;
stateMachine = list{'control objects'}{'game machine'};
gameLogic = list{'control objects'}{'game logic'};
queryable = list{'input objects'}{'using'};

sg = StateDiagramGrapher;
sg.dataGrapher.floatingEdgeNames = true;
sg.dataGrapher.listedEdgeNames = false;
sg.stateMachine = stateMachine;

% is there a way to clear or automate this?
sg.addInputHint('may fall', gameLogic.outputTickTimeUp);
sg.addInputHint('may fall', gameLogic.outputTickOK);
sg.addInputHint('ratchet', gameLogic.outputRatchetLanded);
sg.addInputHint('ratchet', gameLogic.outputRatchetOK);
sg.addInputHint('judgement', gameLogic.outputJudgeGameOver);
sg.addInputHint('judgement', gameLogic.outputJudgeOK);

classGroup = queryable.classifications{'dotris'};
classStruct = [classGroup{:}];
sg.addInputHint('may move', {classStruct.output});
sg.addInputHint('may move', queryable.unavailableOutput);

classGroup = queryable.classifications{'pause'};
classStruct = [classGroup{:}];
sg.addInputHint('pause', {classStruct.output});

sg.parseStates;
sg.writeDotFile;
sg.generateGraph;