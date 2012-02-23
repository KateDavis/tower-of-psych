classdef TestStringifyValue < TestCase
    
    properties
        numerics;
        nonNumerics;
        functionHandles;
        
        n;
    end
    
    methods
        function self = TestStringifyValue(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            self.numerics = {uint8(3), 44.65, pi, ...
                nan, inf, -inf, [], ...
                1:10, (-100:10)*exp(1), int16(0:5), ...
                eye(10), [1 2 3;4 5 6], single(eps*ones(100,4)), ...
                ones(2,2,2)};
            
            self.nonNumerics = {true, false, '', 'a', char(42:126), ...
                logical([0 1 1 0; 1 1 0 1]), ['aaaaaaa';'zzzzzzz';'ggggggg']};
            
            self.functionHandles = {@disp, @()disp('things'), @self.setUp, ...
                @(str)disp(str), @(stuff)self.setUp(stuff)};
            
            self.n = 20;
        end
        
        function tearDown(self)
        end
        
        function summarizeValues(self, values)
            for ii = 1:length(values)
                string = summarizeValue(values{ii}, self.n);
                
                assertTrue(ischar(string), 'summary must be string!')
                assertFalse(isempty(string), ...
                    'no need to get empty string summary')
                assertTrue(length(string) <= self.n, ...
                    sprintf('summary is to long (%d>%d): %s', ...
                    numel(string), self.n, string));
            end
        end
        
        function testSummarySanity(self)
            self.summarizeValues(self.numerics);
            self.summarizeValues(self.nonNumerics);
            self.summarizeValues(self.functionHandles);
            
            self.summarizeValues({self.numerics});
            self.summarizeValues({self.nonNumerics});
            self.summarizeValues({self.functionHandles});
        end
    end
end