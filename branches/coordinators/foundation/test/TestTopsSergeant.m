classdef TestTopsSergeant < TestCase
    
    properties
        sergeant;
        nComponents;
        components;
        order;
        eventCount;
    end
    
    methods
        function self = TestTopsSergeant(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.sergeant = topsSergeant;
            
            self.nComponents = 10;
            self.components = cell(1, self.nComponents);
            for ii = 1:self.nComponents
                comp = topsSergeant;
                comp.startFevalable = {@countValue, self, ii};
                self.components{ii} = comp;
            end
            
            self.order = [];
        end
        
        function tearDown(self)
            delete(self.sergeant);
            self.sergeant = [];
        end
        
        function countValue(self, value)
            self.order(end+1) = value;
        end
        
        function stopRunningComponent(self, component)
            component.isRunning = false;
        end
        
        function testSingleton(self)
            newList = topsSergeant;
            assertFalse(self.sergeant==newList, ...
                'topsSergeant should not be a singleton');
        end
        
        function testStepComponentsEqually(self)
            for ii = 1:self.nComponents
                self.sergeant.components.add(self.components{ii});
            end
            
            self.sergeant.run;
            
            for ii = 1:self.nComponents
                fun = self.components{ii}.startFevalable;
                value = fun{end};
                assertEqual(self.order(ii), value, ...
                    'should have called components in the order added')
            end
        end
        
        function testStopRunningWhenComponentStops(self)
            self.sergeant.start;
            self.sergeant.componentIsRunning = true(1, self.nComponents);
            self.sergeant.componentIsRunning(1) = false;
            self.sergeant.step;
            assertFalse(self.sergeant.isRunning, ...
                'sergeant should stop running when any component stops')
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.sergeant);
            n = length(props);
            for ii = 1:n
                self.sergeant.addlistener(props{ii}, 'PostSet', ...
                    @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.sergeant.(props{ii}) = self.sergeant.(props{ii});
            end
            assertEqual(self.eventCount, n, ...
                'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end