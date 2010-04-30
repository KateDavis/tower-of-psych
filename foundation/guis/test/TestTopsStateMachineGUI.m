classdef TestTopsStateMachineGUI < TestCase
    
    properties
        stateMachine;
        stateMachineGUI;
    end
    
    methods
        function self = TestTopsStateMachineGUI(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.stateMachine = topsStateMachine;
            a.name = 'a';
            self.stateMachine.addState(a);
            self.stateMachineGUI = topsStateMachineGUI(self.stateMachine);
        end
        
        function tearDown(self)
            delete(self.stateMachineGUI);
            self.stateMachineGUI = [];
            
            delete(self.stateMachine);
            self.stateMachine = [];
        end
        
        function testSingleton(self)
            newGui = topsStateMachineGUI;
            assertFalse(self.stateMachineGUI==newGui, ...
                'topsStateMachineGUI should not be a singleton');
            delete(newGui);
        end
        
        function testControlsForNewStates(self)
            guiRows = size(self.stateMachineGUI.statesGrid.controls, 1);
            z.name = 'z';
            self.stateMachine.addState(z);
            guiMoreRows = size(self.stateMachineGUI.statesGrid.controls, 1);
            assertEqual(guiMoreRows, guiRows+1, ...
                'state machine GUI should add controls for new state');
        end
    end
end