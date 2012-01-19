% Try graphing states from the dotris game topsStateMachine
clear
clear classes
clc

% configure the full dotris game
[tree, list] = configureDotris;
stateMachine = list{'control objects'}{'game machine'};
gameLogic = list{'control objects'}{'game logic'};
queryable = list{'input objects'}{'using'};

% create the state diagram grapher object
sg = StateDiagramGrapher();
sg.dataGrapher.floatingEdgeNames = true;
sg.dataGrapher.listedEdgeNames = false;
sg.stateMachine = stateMachine;

% Specify state transitions that are conditional and not obvious from
% parsing the state list.
%
% I don't know a good way to automate this without constraining state
% machine behavior or requiring a lot of extra typing to specify valid
% conditional state transitions.
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

% Generate the state diagram
sg.parseStates;
sg.writeDotFile;
sg.generateGraph;