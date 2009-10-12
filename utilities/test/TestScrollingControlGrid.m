classdef TestScrollingControlGrid < TestCase
    
    properties
        figure;
        position;
        scrollGrid;
    end
    
    methods
        function self = TestScrollingControlGrid(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.figure = figure;
            self.position = [.2 .2 .6 .6];
            self.scrollGrid = ScrollingControlGrid(self.figure, self.position);
        end
        
        function tearDown(self)
            delete(self.scrollGrid);
            self.scrollGrid = [];
            delete(self.figure);
            self.figure = [];
        end
        
        function testSingleton(self)
            newGrid = ScrollingControlGrid;
            assertFalse(self.scrollGrid==newGrid, 'ScrollingControlGrid should not be a singleton');
            delete(newGrid);
        end
        
        function testDeleteAllControls(self)
            self.scrollGrid.deleteAllControls;
            assertTrue(isempty(self.scrollGrid.controls), 'should have no controls')
            
            h = self.scrollGrid.newControlAtRowAndColumn(1, 1);
            assertTrue(ishandle(h), 'should have valid handle');
            
            self.scrollGrid.deleteAllControls;
            assertTrue(isempty(self.scrollGrid.controls), 'should have no controls')
            assertFalse(ishandle(h), 'should have invalid handle');
        end
        
        function testTrimWhenRemove(self)
            locations = [1 5; 5 1; 100 3];
            for ii = 1:size(locations,1)
                self.scrollGrid.newControlAtRowAndColumn(locations(ii,1), locations(ii,2));
            end
            controls = self.scrollGrid.controls;
            assertEqual(size(controls,1), max(locations(:,1)));
            assertEqual(size(controls,2), max(locations(:,2)));
            
            self.scrollGrid.removeControlAtRowAndColumn(locations(end,1), locations(end,2));
            controls = self.scrollGrid.controls;
            assertEqual(size(controls,1), max(locations(1:end-1,1)));
            assertEqual(size(controls,2), max(locations(1:end-1,2)));
        end
        
        function testStretchForMultipleRowsAndColumns(self)
            rows = [3 4];
            cols = [2 5];
            big = self.scrollGrid.newControlAtRowAndColumn(rows, cols);
            small = self.scrollGrid.newControlAtRowAndColumn(1, 1);

            bigPos = get(big, 'Position');
            smallPos = get(small, 'Position');
            assertTrue(smallPos(3) < bigPos(3), 'multi-entry control should have bigger width')
            assertTrue(smallPos(4) < bigPos(4), 'multi-entry control should have bigger height')
            for r = rows
                for c = cols
                    assertEqual(big, self.scrollGrid.controls(r,c), 'multi-entry control should be redundant in controls array');
                end
            end
        end
    end
end