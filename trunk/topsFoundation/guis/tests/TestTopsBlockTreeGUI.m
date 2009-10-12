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
            z = size(self.blockTreeGUI.blocksGrid.controls);
            assertEqual(z(1), 2, 'wrong number of block control rows');
            assertEqual(z(2), 2, 'wrong number of block control columns');
        end
        
        function testLaterNumberOfTreeControls(self)
            blockTreeGrandchild = topsBlockTree;
            blockTreeGrandchild.name = 'child';
            self.blockTreeChild.addChild(blockTreeGrandchild);

            z = size(self.blockTreeGUI.blocksGrid.controls);
            assertEqual(z(1), 3, 'wrong number of block control rows');
            assertEqual(z(2), 3, 'wrong number of block control columns');
        end
    end
end