classdef TestTopsConcurrentComposite < TestCase
    
    properties
        concurrents;
        nComponents;
        components;
        order;
        eventCount;
    end
    
    methods
        function self = TestTopsConcurrentComposite(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.concurrents = topsConcurrentComposite;
            
            self.nComponents = 10;
            self.components = cell(1, self.nComponents);
            for ii = 1:self.nComponents
                comp = topsConcurrent;
                comp.startFevalable = {@countValue, self, ii};
                self.components{ii} = comp;
            end
            
            self.order = [];
        end
        
        function tearDown(self)
            delete(self.concurrents);
            self.concurrents = [];
        end
        
        function countValue(self, value)
            self.order(end+1) = value;
        end
        
        function stopRunningComponent(self, component)
            component.isRunning = false;
        end
        
        function testSingleton(self)
            newList = topsConcurrentComposite;
            assertFalse(self.concurrents==newList, ...
                'topsConcurrentComposite should not be a singleton');
        end
        
        function testRunComponentsEqually(self)
            for ii = 1:self.nComponents
                self.concurrents.addChild(self.components{ii});
            end
            
            self.concurrents.run;
            
            for ii = 1:self.nComponents
                fun = self.components{ii}.startFevalable;
                value = fun{end};
                assertEqual(self.order(ii), value, ...
                    'should have called components in the order added')
            end
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.concurrents);
            n = length(props);
            for ii = 1:n
                self.concurrents.addlistener(props{ii}, 'PostSet', ...
                    @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.concurrents.(props{ii}) = self.concurrents.(props{ii});
            end
            assertEqual(self.eventCount, n, ...
                'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end