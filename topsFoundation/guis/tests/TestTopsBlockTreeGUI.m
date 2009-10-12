classdef TestTopsBlockTreeGUI < TestCase
    
    properties
        blockTree;
        blockTreeChild;
        blockTreeGUI;
    end
    
    methods
        function self = TestTopsBlockTreeGUI(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.blockTree = topsBlockTree;
            self.blockTree.name = 'parent';
            self.blockTreeChild = topsBlockTree;
            self.blockTreeChild.name = 'child';
            self.blockTree.addChild(self.blockTreeChild);
            
            self.blockTreeGUI = topsBlockTreeGUI(self.blockTree);
        end
        
        function tearDown(self)
            delete(self.blockTreeGUI);
            self.blockTreeGUI = [];
            
            delete(self.blockTree);
            self.blockTree = [];
            
            delete(self.blockTreeChild);
            self.blockTreeChild = [];
        end
        
        function testSingleton(self)
            newGui = topsBlockTreeGUI;
            assertFalse(self.blockTreeGUI==newGui, 'topsBlockTreeGUI should not be a singleton');
            delete(newGui);
        end
        
        function testInitialNumberOfTreeControls(self)
            controls = self.blockTreeGUI.blocksGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 2, 'should be two controls--parent and child');
        end
        
        function testLaterNumberOfTreeControls(self)
            blockTreeGrandchild = topsBlockTree;
            blockTreeGrandchild.name = 'child';
            self.blockTreeChild.addChild(blockTreeGrandchild);
            
            controls = self.blockTreeGUI.blocksGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 3, 'should be three controls--parent, child and grandchild');
        end
    end
end