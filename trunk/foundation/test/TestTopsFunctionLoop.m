classdef TestTopsFunctionLoop < TestCase
    
    properties
        functionLoop;
        mathGroup;
        mathFunctions;
        orderedGroup;
        orderedFunctions;
        order;
        eventCount;
    end
    
    methods
        function self = TestTopsFunctionLoop(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.functionLoop = topsFunctionLoop;            

            self.mathGroup = 'maths';
            self.mathFunctions  = { ...
                {@eye, 6}, ...
                {@mod, 3, 2}};
            
            self.orderedGroup = 'ordered';
            self.orderedFunctions = { ...
                {@self.executeFunction, 1}, ...
                {@self.executeFunction, 2}, ...
                {@self.executeFunction, 3}, ...
                {@self.executeFunction, 4}};
            
            self.order = [];
        end
        
        function tearDown(self)
            delete(self.functionLoop);
            self.functionLoop = [];
        end
        
        function executeFunction(self, value)
            self.order(end+1) = value;
        end
        
        function addFunctionsToGroupsInOrder(self)
            % bunch of functions for two different groups
            for ii = 1:length(self.mathFunctions)
                self.functionLoop.addFunctionToGroupWithRank(self.mathFunctions{ii}, self.mathGroup, ii);
            end
            
            for ii = 1:length(self.orderedFunctions)
                self.functionLoop.addFunctionToGroupWithRank(self.orderedFunctions{ii}, self.orderedGroup, ii);
            end
        end
        
        function testSingleton(self)
            newLoop = topsFunctionLoop;
            assertFalse(self.functionLoop==newLoop, 'topsFunctionLoop should not be a singleton');
        end
        
        function testRetrieveFunctionsByGroupAndRank(self)
            self.addFunctionsToGroupsInOrder;
            
            mathLoop = self.functionLoop.getFunctionListForGroup(self.mathGroup);
            for ii = 1:length(mathLoop)
                assertEqual(mathLoop{ii}, self.mathFunctions{ii}, ...
                    'should get back identical list of math functions');
            end

            orderedLoop = self.functionLoop.getFunctionListForGroup(self.orderedGroup);
            for ii = 1:length(orderedLoop)
                assertEqual(orderedLoop{ii}, self.orderedFunctions{ii}, ...
                    'should get back identical list of test functions');
            end
        end

        function testRunFunctionsInCorrectOrder(self)
            self.addFunctionsToGroupsInOrder;
            self.functionLoop.runForGroup(self.orderedGroup, 0);
            assertFalse(isempty(self.order), 'failed to execute functions');
            assertTrue(all(diff(self.order))>0, 'executed functions in wrong order');
        end
        
        function testAbortRunWithProceedFlag(self)
            abortGroup = 'abortTest';
            self.functionLoop.proceedFcn = {@false};
            self.functionLoop.addFunctionToGroupWithRank({@self.executeFunction, 1}, abortGroup, 2);
            self.functionLoop.runForGroup(abortGroup, 0);
            assertEqual(length(self.order), 1, ...
                'function loop should made only one pass');
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.functionLoop);
            n = length(props);
            for ii = 1:n
                self.functionLoop.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.functionLoop.(props{ii}) = self.functionLoop.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end