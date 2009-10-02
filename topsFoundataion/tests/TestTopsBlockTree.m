classdef TestTopsBlockTree < TestCase
    
    properties
        blockTree;
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
            self.blockTree.blockBeginFcn = {@disp, 'block begin'};
            self.blockTree.blockActionFcn = {@disp, 'block action'};
            self.blockTree.blockEndFcn = {@disp, 'block end'};
            
            self.blockTree.preview;
            summary = topsDataLog.getAllDataSorted;
            assertEqual(length(summary), 3, 'wrong number of summary functions');
            assertEqual(self.blockTree.blockBeginFcn, summary(1).data, 'wrong block begin function');
            assertEqual(self.blockTree.blockActionFcn, summary(2).data, 'wrong block action function');
            assertEqual(self.blockTree.blockEndFcn, summary(3).data, 'wrong block end function');
        end
        
        function testPreviewChildFunctions(self)
            nChildren = 3;
            for ii = 1:nChildren
                child = topsBlockTree;
                child.name = 'child tree';
                self.blockTree.addChild(child);
            end
            self.blockTree.preview;
            summary = topsDataLog.getAllDataSorted;
            assertEqual(length(summary), 3*(nChildren+1), 'wrong number of child functions logged');
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
            self.blockTree.blockBeginFcn = fcn{1};
            self.blockTree.blockActionFcn = fcn{2};
            child.blockBeginFcn = fcn{3};
            child.blockActionFcn = fcn{4};
            grandchild.blockBeginFcn = fcn{5};
            grandchild.blockActionFcn = fcn{6};
            grandchild.blockEndFcn = fcn{7};
            child.blockEndFcn = fcn{8};
            self.blockTree.blockEndFcn = fcn{9};
            
            self.blockTree.run;
            summary = topsDataLog.getAllDataSorted;
            for ii = 1:length(fcn)
                assertEqual(fcn{ii}, summary(ii).data, 'functions run in wrong order');
            end
        end
        
        function testPropertyChangeEventPosting(self)
            global eventCount
            eventCount = 0;
            
            % listen for event postings
            props = properties(self.blockTree);
            n = length(props);
            for ii = 1:n
                self.blockTree.addlistener(props{ii}, 'PostSet', @hearEvent);
            end
            
            % trigger a posting for each property
            for ii = 1:n
                self.blockTree.(props{ii}) = self.blockTree.(props{ii});
            end
            assertEqual(eventCount, n, 'heard wrong number of property set events');
            clear global eventCount
            function hearEvent(metaProp, event)
                eventCount = eventCount + 1;
            end
        end
    end
end