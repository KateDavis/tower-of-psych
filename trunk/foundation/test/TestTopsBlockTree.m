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
            self.blockTree.blockStartFcn = {@sprintf, 'block start'};
            self.blockTree.blockActionFcn = {@sprintf, 'block action'};
            self.blockTree.blockEndFcn = {@sprintf, 'block end'};
            
            self.blockTree.preview;
            summary = topsDataLog.getSortedDataStruct;
            assertEqual(length(summary), 3, 'wrong number of summary functions');
            assertEqual(self.blockTree.blockStartFcn, summary(1).item, 'wrong block start function');
            assertEqual(self.blockTree.blockActionFcn, summary(2).item, 'wrong block action function');
            assertEqual(self.blockTree.blockEndFcn, summary(3).item, 'wrong block end function');
        end
        
        function testPreviewChildFunctions(self)
            nChildren = 3;
            for ii = 1:nChildren
                child = topsBlockTree;
                child.name = 'child tree';
                child.blockStartFcn = {@sprintf, 'block start'};
                child.blockActionFcn = {@sprintf, 'block action'};
                child.blockEndFcn = {@sprintf, 'block end'};
                self.blockTree.addChild(child);
            end
            self.blockTree.preview;
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
            self.blockTree.blockStartFcn = fcn{1};
            self.blockTree.blockActionFcn = fcn{2};
            child.blockStartFcn = fcn{3};
            child.blockActionFcn = fcn{4};
            grandchild.blockStartFcn = fcn{5};
            grandchild.blockActionFcn = fcn{6};
            grandchild.blockEndFcn = fcn{7};
            child.blockEndFcn = fcn{8};
            self.blockTree.blockEndFcn = fcn{9};
            
            self.blockTree.run;
            summary = topsDataLog.getSortedDataStruct;
            for ii = 1:length(fcn)
                assertEqual(fcn{ii}, summary(ii).item, 'functions run in wrong order');
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