classdef TestTopsBlockTree < TestCase
    
    properties
        blockTree;
        eventCount;
    end
    
    methods
        function self = TestTopsBlockTree(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.blockTree = topsBlockTree;
            self.blockTree.name = 'test tree';
            topsDataLog.flushAllData;
        end
        
        function tearDown(self)
            delete(self.blockTree);
            self.blockTree = [];
        end
        
        function testSingleton(self)
            newBlockTree = topsBlockTree;
            assertFalse(self.blockTree==newBlockTree, 'topsBlockTree should not be a singleton');
        end
        
        function testPreviewOwnFunctions(self)
            self.blockTree.blockStartFevalable = {@sprintf, 'block start'};
            self.blockTree.blockActionFevalable = {@sprintf, 'block action'};
            self.blockTree.blockEndFevalable = {@sprintf, 'block end'};
            
            self.blockTree.preview = true;
            self.blockTree.run;
            summary = topsDataLog.getSortedDataStruct;
            assertEqual(length(summary), 3, 'wrong number of summary functions');
            assertEqual(self.blockTree.blockStartFevalable{1}, summary(1).item, 'wrong block start function');
            assertEqual(self.blockTree.blockActionFevalable{1}, summary(2).item, 'wrong block action function');
            assertEqual(self.blockTree.blockEndFevalable{1}, summary(3).item, 'wrong block end function');
        end
        
        function testPreviewChildFunctions(self)
            nChildren = 3;
            for ii = 1:nChildren
                child = topsBlockTree;
                child.name = 'child tree';
                child.blockStartFevalable = {@sprintf, 'block start'};
                child.blockActionFevalable = {@sprintf, 'block action'};
                child.blockEndFevalable = {@sprintf, 'block end'};
                child.preview = true;
                self.blockTree.addChild(child);
            end
            self.blockTree.preview = true;
            self.blockTree.run;
            summary = topsDataLog.getSortedDataStruct;
            assertEqual(length(summary), 3*nChildren, 'wrong number of child functions logged');
        end
        
        function testDepthFirstFunctionOrder(self)
            child = topsBlockTree;
            child.name = 'child';
            
            grandchild = topsBlockTree;
            grandchild.name = 'grandchild';
            
            self.blockTree.addChild(child);
            child.addChild(grandchild);
            
            % ordered list of functions
            for ii = 9:-1:1
                fcn{ii} = {@plus, ii, ii};
            end
            
            % expected depth-first execution order
            self.blockTree.blockStartFevalable = fcn{1};
            self.blockTree.blockActionFevalable = fcn{2};
            child.blockStartFevalable = fcn{3};
            child.blockActionFevalable = fcn{4};
            grandchild.blockStartFevalable = fcn{5};
            grandchild.blockActionFevalable = fcn{6};
            grandchild.blockEndFevalable = fcn{7};
            child.blockEndFevalable = fcn{8};
            self.blockTree.blockEndFevalable = fcn{9};
            
            self.blockTree.run;
            summary = topsDataLog.getSortedDataStruct;
            for ii = 1:length(fcn)
                assertEqual(fcn{ii}{1}, summary(ii).item, 'functions run in wrong order');
            end
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.blockTree);
            n = length(props);
            for ii = 1:n
                self.blockTree.addlistener(props{ii}, 'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.blockTree.(props{ii}) = self.blockTree.(props{ii});
            end
            assertEqual(self.eventCount, n, 'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end