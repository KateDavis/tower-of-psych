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
        
        function testDepthFirstActionLogging(self)
            child = topsTreeNode;
            child.name = 'child';
            
            grandchild = topsTreeNode;
            grandchild.name = 'grandchild';
            
            self.treeNode.addChild(child);
            child.addChild(grandchild);
            
            self.treeNode.run;
            logInfo = topsDataLog.getSortedDataStruct;
            actionInfo = [logInfo.item];
            
            expectedNames = { ...
                self.treeNode.name, ...
                child.name, ...
                grandchild.name, ...
                grandchild.name, ...
                child.name, ...
                self.treeNode.name};
            runnableNames = {actionInfo.runnableName};
            assertEqual(expectedNames, runnableNames, ...
                'wrong node order for tree run()');
            
            start = self.treeNode.startString;
            finish = self.treeNode.finishString;
            expectedActions = {start, start, start, ...
                finish, finish finish};
            actions = {actionInfo.actionName};
            assertEqual(expectedActions, actions, ...
                'wrong action order for tree run()');
        end
        
        function testCatchRecursionException(self)
            errorCauser = {@stupidDoesNotExist};
            try
                feval(errorCauser{:})
            catch expectedException
                warning('off', expectedException.identifier)
            end
            
            child = self.treeNode.newChildNode;
            child.startFevalable = errorCauser;
            runner = @()self.treeNode.run;
            assertExceptionThrown(runner, expectedException.identifier, ...
                'treeNode should catch errors during runnung and rethrow')
            
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