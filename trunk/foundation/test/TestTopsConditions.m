classdef TestTopsConditions < TestCase
    
    properties
        conditions;
        assignmentTarget;
        eventCount;
    end
    
    methods
        function self = TestTopsConditions(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.conditions = topsConditions;
            self.assignmentTarget = '';
            self.eventCount = 0;
        end
        
        function tearDown(self)
            delete(self.conditions);
            self.conditions = [];
        end
        
        function testSingleton(self)
            newConditions = topsConditions;
            assertFalse(self.conditions==newConditions, ...
                'topsConditions should not be a singleton');
        end
        
        function testAssignmentAndCounting(self)
            % get the conditions to count in binary by assigning values to
            % differnt elements of assignmentTarget
            self.conditions.addParameter('ones', {'1', '0'});
            self.conditions.addParameter('twos', {'1', '0'});
            self.conditions.addParameter('fours', {'1', '0'});
            
            self.conditions.addAssignment('ones', ...
                self, '.', 'assignmentTarget', '()', {1});
            self.conditions.addAssignment('twos', ...
                self, '.', 'assignmentTarget', '()', {2});
            self.conditions.addAssignment('fours', ...
                self, '.', 'assignmentTarget', '()', {3});
            
            % run through all the conditions and keep track of the
            % binary numbers assigned
            self.conditions.setPickingMethod('sequential');
            assignedNumbers = [];
            self.conditions.reset;
            while ~self.conditions.isDone
                self.conditions.run;
                assignedNumbers(end+1) = bin2dec(self.assignmentTarget);
            end
            
            % verify that every combination of binary digits was assigned
            expectedNumbers = 0:(self.conditions.nConditions - 1);
            assertEqual(sort(assignedNumbers), expectedNumbers, ...
                'should have traversed a unique integer per condition')
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.conditions);
            n = length(props);
            for ii = 1:n
                self.conditions.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.conditions.(props{ii}) = self.conditions.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end