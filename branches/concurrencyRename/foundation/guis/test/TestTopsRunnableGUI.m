classdef TestTopsTreeNodeGUI < TestCase
    
    properties
        treeNode;
        treeNodeChild;
        treeNodeGUI;
    end
    
    methods
        function self = TestTopsTreeNodeGUI(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.treeNode = topsTreeNode;
            self.treeNode.name = 'parent';
            self.treeNodeChild = self.treeNode.newChildNode;
            self.treeNodeChild.name = 'child';
            
            self.treeNodeGUI = topsTreeNodeGUI(self.treeNode);
        end
        
        function tearDown(self)
            delete(self.treeNodeGUI);
            self.treeNodeGUI = [];
            
            delete(self.treeNode);
            self.treeNode = [];
            
            delete(self.treeNodeChild);
            self.treeNodeChild = [];
        end
        
        function testSingleton(self)
            newGui = topsTreeNodeGUI;
            assertFalse(self.treeNodeGUI==newGui, 'topsTreeNodeGUI should not be a singleton');
            delete(newGui);
        end
        
        function testInitialNumberOfTreeControls(self)
            controls = self.treeNodeGUI.nodesGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 2, 'should be two controls--parent and child');
        end
        
        function testLaterNumberOfTreeControls(self)
            treeNodeGrandchild = self.treeNodeChild.newChildNode;
            treeNodeGrandchild.name = 'grandchild';
            self.treeNode.name = 'grandparent';
            
            controls = self.treeNodeGUI.nodesGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 3, 'should be three controls--parent, child and grandchild');
        end
    end
end