classdef TestTopsClassification < dotsTestCase
    
    properties
        xSample;
        ySample;
    end
    
    methods
        function self = TestTopsClassification(name)
            self = self@dotsTestCase(name);
        end
        
        function x = getX(self)
            x = self.xSample;
        end
        
        function y = getY(self)
            y = self.ySample;
        end
        
        function testRectangles(self)
            % classify in the unit square
            classn = topsClassification('unit square');
            nPoints = 10;
            classn.addSource('x', @()getX(self), 0, 1, nPoints);
            classn.addSource('y', @()getY(self), 0, 1, nPoints);
            
            % map left and middle regions to arbitrary outputs
            left = topsRegion('left', classn.space);
            left = left.setRectangle('x', 'y', [0 0 .5 1], 'in');
            classn.addOutput('left', left, 'left');
            
            middle = topsRegion('middle', classn.space);
            middle = middle.setRectangle('x', 'y', [0.25 0 .5 1], 'in');
            classn.addOutput('middle', middle, 'middle');
            
            % set a point on the left side
            self.xSample = 0;
            self.ySample = 0.5;
            classn.updateSamples();
            [output, outputName] = classn.getOutput();
            assertEqual('left', output, 'wrong output for left data')
            assertEqual('left', outputName, 'wrong name for left output')
            
            % set a point on the right side
            self.xSample = 1;
            self.ySample = 0.5;
            classn.updateSamples();
            [output, outputName] = classn.getOutput();
            assertEqual(classn.defaultOutput, output, ...
                'wrong output for unmapped data')
            assertEqual(classn.defaultOutputName, outputName, ...
                'wrong name for default output')
            
            % set a point in the middle
            self.xSample = 0.5;
            self.ySample = 0.5;
            classn.updateSamples();
            [output, outputName] = classn.getOutput();
            assertEqual('middle', output, 'middle should take precedence')
            assertEqual('middle', outputName, 'wrong name for middle')
        end
        
    end
end