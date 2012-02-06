classdef TestTopsGroupedListGUI < TestCase
    
    properties
        groupedList;
        groupedListGUI;
        groupedListPanel;
    end
    
    methods
        function self = TestTopsGroupedListGUI(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.groupedList = topsGroupedList;
            self.groupedListGUI = topsGroupedListGUI(self.groupedList);
            self.groupedListPanel = self.groupedListGUI.listPanel;
        end
        
        function tearDown(self)
            delete(self.groupedListGUI);
            self.groupedListGUI = [];
            
            delete(self.groupedList);
            self.groupedList = [];
        end
        
        function testSingleton(self)
            newGui = topsGroupedListGUI;
            assertFalse(self.groupedListGUI==newGui, 'topsGroupedListGUI should not be a singleton');
            delete(newGui);
        end
        
        function testInitialNumberOfControls(self)
            controls = self.groupedListPanel.groupsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 0, 'should start with no groups controls');
            
            controls = self.groupedListPanel.mnemonicsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 0, 'should start with no mnemonics controls');
            
            detailsGrid = self.groupedListPanel.itemDetailPanel.detailsGrid;
            controls = detailsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 0, 'should start with no item detail controls');
        end
        
        function testLaterNumberOfGroupsControls(self)
            % add three items under two groups
            self.groupedList.addItemToGroupWithMnemonic(1,1,1);
            self.groupedList.addItemToGroupWithMnemonic(2,1,2);
            self.groupedList.addItemToGroupWithMnemonic(3,2,3);
            
            controls = self.groupedListPanel.groupsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 2, 'should now have two groups controls');
        end
        
        function testNumericGroupsAndMnemonics(self)
            self.groupedList.addItemToGroupWithMnemonic(1,1,1);
            self.groupedList.addItemToGroupWithMnemonic(2,2,2);
            self.groupedList.addItemToGroupWithMnemonic(3,3,3);
            
            controls = self.groupedListPanel.groupsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 3, 'should now have three controls for numbered groups');
        end
        
        function testStringGroupsAndMnemonics(self)
            self.groupedList.addItemToGroupWithMnemonic('1','1','1');
            self.groupedList.addItemToGroupWithMnemonic('2','2','2');
            self.groupedList.addItemToGroupWithMnemonic('3','3','3');
            
            controls = self.groupedListPanel.groupsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertEqual(n, 3, 'should now have three controls for string-named groups');
        end
        
        function testDrillIntoStructItem(self)
            s.one = 1;
            s.two = 2;
            s.three = 'three';
            self.groupedList.addItemToGroupWithMnemonic(s, 'struct', 's');
            
            self.groupedListPanel.setCurrentGroup('struct');
            detailsGrid = self.groupedListPanel.itemDetailPanel.detailsGrid;
            controls = detailsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertTrue(n > 1, 'should have multiple controls to summarize struct item');
        end

        function testDrillIntoStructArrayItem(self)
            s(1).one = 1;
            s(1).two = 2;
            s(1).three = 'three';

            s(2).one = 1;
            s(2).two = 2;
            s(2).three = 'three';

            self.groupedList.addItemToGroupWithMnemonic(s, 'struct', 's');
            
            self.groupedListPanel.setCurrentGroup('struct');
            detailsGrid = self.groupedListPanel.itemDetailPanel.detailsGrid;
            controls = detailsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertTrue(n > 1, 'should have multiple controls to summarize struct item');
        end
        
        function testDrillIntoCellItem(self)
            c{1} = 1;
            c{2} = 2;
            c{3} = 'three';
            self.groupedList.addItemToGroupWithMnemonic(c, 'cell', 'c');
            
            self.groupedListPanel.setCurrentGroup('cell');
            detailsGrid = self.groupedListPanel.itemDetailPanel.detailsGrid;
            controls = detailsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertTrue(n > 1, 'should have multiple controls to summarize cell item');
        end
        
        function testDrillIntoObjectItem(self)
            o = self.groupedListGUI;
            self.groupedList.addItemToGroupWithMnemonic(o, 'object', 'o');
            
            self.groupedListPanel.setCurrentGroup('object');
            detailsGrid = self.groupedListPanel.itemDetailPanel.detailsGrid;
            controls = detailsGrid.controls;
            n = length(unique(controls(controls>0 & ishandle(controls))));
            assertTrue(n > 1, 'should have multiple controls to summarize object item');
        end
        
        function testSendItemToWorkspace(self)
            number = 4;
            self.groupedList.addItemToGroupWithMnemonic(number, 'numbers', 'number');
            self.groupedListPanel.setCurrentGroup('numbers');
            self.groupedListPanel.currentItemToBaseWorkspace;
            numberExists = logical(evalin('base', 'exist(''number'');'));
            assertTrue(numberExists, 'should have variable "number" in base workspace');
            
            numberValue = evalin('base', 'number');
            assertEqual(number, numberValue, '"number" in workspace has wrong value');
        end
    end
end