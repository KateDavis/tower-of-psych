classdef TestTopsStateMachine < TestCase
    
    properties
        stateMachine;
        eventCount;
        branchState;
    end
    
    methods
        function self = TestTopsStateMachine(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.stateMachine = topsStateMachine;
            self.stateMachine.name = 'test machine';
            topsDataLog.flushAllData;
        end
        
        function tearDown(self)
            delete(self.stateMachine);
            self.stateMachine = [];
        end
        
        function stateName = getNextState(self)
            stateName = self.branchState;
        end
        
        function testSingleton(self)
            newStateMachine = topsStateMachine;
            assertFalse(self.stateMachine==newStateMachine, ...
                'topsStateMachine should not be a singleton');
        end
        
        function testCallAndLogMachineFcns(self)
            self.eventCount = 0;
            machineFcn = @(stateInfo) self.hearEvent;
            self.stateMachine.beginFevalable = {machineFcn};
            self.stateMachine.transitionFevalable = {machineFcn};
            self.stateMachine.endFevalable = {machineFcn};
            
            statesInfo = { ...
                'name',     'next'; ...
                'beginning','middle'; ...
                'middle',   'end'; ...
                'end',      ''; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            self.stateMachine.run;
            
            % expect n+1 function calls for
            %   n-1 transitions, plus beginning, plus end
            expectedCount = length(self.stateMachine.allStates) + 1;
            assertEqual(expectedCount, self.eventCount, ...
                'state machine called wrong number of functions');
            
            summary = topsDataLog.getSortedDataStruct;
            assertEqual(expectedCount, length(summary), ...
                'state machine logged wrong number of functions');
            
            for ii = 1:length(summary)
                loggedFcn = summary(ii).item{1};
                assertEqual(loggedFcn, machineFcn, ...
                    'state machine did not log correct function')
                
                loggedStateInfo = summary(ii).item{2};
                assertTrue(isstruct(loggedStateInfo), ...
                    'state machine should log state info with function call')
            end
        end
        
        function testCallAndLogStateFcns(self)
            self.eventCount = 0;
            stateFcn = {@() self.hearEvent};
            
            statesInfo = { ...
                'name',     'next',     'entry',    'exit'; ...
                'beginning','middle',   stateFcn,   stateFcn; ...
                'middle',	'end',      stateFcn,   stateFcn; ...
                'end',      '',         stateFcn,   stateFcn; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            self.stateMachine.run;
            
            % expect 2n function calls for
            %   n entry and n exit functions
            expectedCount = 2*length(self.stateMachine.allStates);
            assertEqual(expectedCount, self.eventCount, ...
                'state machine called wrong number of state functions');
            
            summary = topsDataLog.getSortedDataStruct;
            assertEqual(expectedCount, length(summary), ...
                'state machine logged wrong number of state functions');
            
            for ii = 1:length(summary)
                loggedFcn = summary(ii).item;
                assertEqual(loggedFcn, stateFcn{1}, ...
                    'state machine did not log correct state function')
            end
        end
        
        function testInputBranching(self)
            % a batch of boring states
            defaultEnd = 'end';
            altEnd1 = 'alt1';
            altEnd2 = 'alt2';
            statesInfo = { ...
                'name',     'next'; ...
                'beginning','middle'; ...
                defaultEnd, ''; ...
                altEnd1,    ''; ...
                altEnd2,	''; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);
            
            % a special middle state which checks for input
            %   and the alternate way of specifying
            m.name = 'middle';
            m.timeout = .005;
            m.next = defaultEnd;
            m.input = {@getNextState, self};
            self.stateMachine.addState(m);
            
            self.branchState = '';
            self.stateMachine.run;
            endName = self.stateMachine.endState.name;
            assertEqual(endName, defaultEnd, ...
                'empty input should lead to default end')
            
            self.branchState = altEnd1;
            self.stateMachine.run;
            endName = self.stateMachine.endState.name;
            assertEqual(endName, altEnd1, ...
                'name input should cause branching to named state')
            
            self.branchState = altEnd2;
            self.stateMachine.run;
            endName = self.stateMachine.endState.name;
            assertEqual(endName, altEnd2, ...
                'name input should cause branching to named state')
        end
        
        function testStateSharedFunctions(self)
            % add some shared functions that will get arguments from the
            % from each state
            sharedFcn = {@countSharedFunctionCall, self};
            self.stateMachine.addSharedFevalableWithName( ...
                sharedFcn, 'enterWith', 'entry');
            self.stateMachine.addSharedFevalableWithName( ...
                sharedFcn, 'exitWith', 'exit');
            
            % add states that "know about" the shared functions
            enterNum = 1;
            exitNum = 10;
            statesInfo = { ...
                'name',     'next',     'enterWith',	'exitWith'; ...
                'beginning','middle',   {enterNum},     {exitNum}; ...
                'middle',	'end',      {enterNum},     {exitNum}; ...
                'end',      '',         {enterNum},     {exitNum}; ...
                };
            self.stateMachine.addMultipleStates(statesInfo);

            % add a new shared function after the fact
            %   the states wont know to add arguments to this one
            extraNum = 100;
            sharedFcn = {@countSharedFunctionCall, self, extraNum};
            self.stateMachine.addSharedFevalableWithName( ...
                sharedFcn, 'extra', 'entry');
            
            self.eventCount = 0;
            self.stateMachine.run;
            expectedCount = length(self.stateMachine.allStates) ...
                * (enterNum + exitNum + extraNum);
            assertEqual(expectedCount, self.eventCount, ...
                'wrong count of state common function calls');

        end
        
        function countSharedFunctionCall(self, number)
            self.eventCount = self.eventCount + number;
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.stateMachine);
            n = length(props);
            for ii = 1:n
                self.stateMachine.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.stateMachine.(props{ii}) = self.stateMachine.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
        end
        
        function hearEvent(self, varargin)
            self.eventCount = self.eventCount + 1;
        end
    end
end