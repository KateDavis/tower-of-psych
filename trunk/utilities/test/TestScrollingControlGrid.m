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
        
        function testReplaceInSameLocation(self)
            location = [1 5];
            hFirst = self.scrollGrid.newControlAtRowAndColumn(location(1), location(2));
            hReplace = self.scrollGrid.newControlAtRowAndColumn(location(1), location(2));
            assertFalse(ishandle(hFirst), 'old control should have been deleted');
            assertFalse(hFirst==hReplace, 'old control should have been replaced');
            assertTrue(ishandle(hReplace), 'new control should work');
        end
    end
end