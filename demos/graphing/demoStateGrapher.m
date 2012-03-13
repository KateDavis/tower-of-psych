% Try graphing state machine states from the SquareTag game
clear
clear classes
clc

% configure the full dotris game
[runnable, list] = configureSquareTag();
logic = list{'logic'}{'object'};
logic.startSession();
logic.startTrial();
logic.nextSquare();
stateMachine = list{'runnable'}{'stateMachine'};

% create the state diagram grapher object
sg = StateDiagramGrapher();
sg.dataGrapher.floatingEdgeNames = true;
sg.dataGrapher.listedEdgeNames = false;
sg.stateMachine = stateMachine;

% add some hints to complete the graph
sg.addInputHint('proceed', 'done');
sg.addInputHint('proceed', 'ready');

% Generate the state diagram
sg.parseStates();
sg.writeDotFile();
sg.generateGraph();