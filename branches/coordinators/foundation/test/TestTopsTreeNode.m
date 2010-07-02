classdef TestTopsTreeNode < TestCase
    
    properties
        treeNode;
        eventCount;
    end
    
    methods
        function self = TestTopsTreeNode(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.treeNode = topsTreeNode;
            self.treeNode.name = 'parent';
            topsDataLog.flushAllData;
        end
        
        function tearDown(self)
            delete(self.treeNode);
            self.treeNode = [];
        end
        
        function testSingleton(self)
            newTreeNode = topsTreeNode;
            assertFalse(self.treeNode==newTreeNode, ...
                'topsTreeNode should not be a singleton');
        end
        
        function testDepthFirstFunctionOrder(self)
            child = topsTreeNode;
            child.name = 'child';
            
            grandchild = topsTreeNode;
            grandchild.name = 'grandchild';
            
            self.treeNode.addChild(child);
            child.addChild(grandchild);
            
            self.treeNode.run;
            summary = topsDataLog.getSortedDataStruct;
            summary.group
        end
        
        function testPropertyChangeEventPosting(self)
            % listen for event postings
            props = properties(self.treeNode);
            n = length(props);
            for ii = 1:n
                self.treeNode.addlistener(props{ii}, ...
                    'PostSet', @self.hearEvent);
            end
            
            % trigger a posting for each property
            self.eventCount = 0;
            for ii = 1:n
                self.treeNode.(props{ii}) = self.treeNode.(props{ii});
            end
            assertEqual(self.eventCount, n, ...
                'heard wrong number of property set events');
        end
        
        function hearEvent(self, metaProp, event)
            self.eventCount = self.eventCount + 1;
        end
    end
end