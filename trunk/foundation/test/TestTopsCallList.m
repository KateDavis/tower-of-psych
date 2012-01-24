classdef TestTopsCallList < TestCase
    
    properties
        callList;
        nFunctions;
        orderedFunctions;
        order;
        eventCount;
    end
    
    methods
        function self = TestTopsCallList(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.callList = topsCallList;
            
            self.nFunctions = 10;
            self.orderedFunctions = cell(1, self.nFunctions);
            for ii = 1:self.nFunctions
                self.orderedFunctions{ii} = ...
                    {@countValue, self, ii};
            end
            
            self.order = [];
        end
        
        function tearDown(self)
            delete(self.callList);
            self.callList = [];
        end
        
        function countValue(self, value)
            self.order(end+1) = value;
        end
        
        function stopListFromRunning(self, callList)
            callList.isRunning = false;
        end
        
        function testSingleton(self)
            newList = topsCallList;
            assertFalse(self.callList==newList, ...
                'topsCallList should not be a singleton');
        end
        
        function testRunThroughCalls(self)
            for ii = 1:self.nFunctions
                name = sprintf('%d', ii);
                self.callList.addCall(self.orderedFunctions{ii}, name);
            end
            
            self.callList.alwaysRunning = false;
            self.callList.run;
            
            for ii = 1:self.nFunctions
                fun = self.orderedFunctions{ii};
                value = fun{end};
                assertEqual(self.order(ii), value, ...
                    'should have called functions in the order added')
            end
        end
        
        function testRunUntilStopped(self)
            self.callList.alwaysRunning = true;
            self.callList.addCall({@stopListFromRunning, ...
                self, self.callList}, 'stop');
            self.callList.runBriefly;
            assertFalse(self.callList.isRunning, ...
                'call list should have been stopped from running')
        end
        
        function testToggleIsActive(self)
            self.callList.addCall(self.orderedFunctions{1}, 'one');
            self.callList.addCall(self.orderedFunctions{2}, 'two');
            
            self.callList.setActiveByName(false, 'two');
            self.callList.runBriefly;
            assertEqual(length(self.order), 1, ...
                'should have called only one function')
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.callList);
            n = length(props);
            for ii = 1:n
                self.callList.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.callList.(props{ii}) = self.callList.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end