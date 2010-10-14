classdef TestTopsFile < TestCase
    
    properties
        filePath;
        fileName;
    end
    
    methods
        function self = TestTopsFile(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            [p,n,e] = fileparts(mfilename('fullpath'));
            self.filePath = p;
            self.fileName = 'topsFileTest.mat';
        end
        
        function tearDown(self)
            nameWithPath = fullfile(self.filePath, self.fileName);
            if exist(nameWithPath)
                delete(nameWithPath);
            end
        end
        
        function testCreate(self)
            fHeader = topsFile.newTopsFileHeader( ...
                'fileName', self.fileName, ...
                'filePath', self.filePath);
            assertTrue(isstruct(fHeader), ...
                'should get topsFile header metadata struct')
            assertEqual(self.fileName, fHeader.fileName, ...
                'should topsFile use supplied file name')
            assertEqual(self.filePath, fHeader.filePath, ...
                'should topsFile use supplied file path')
        end
        
        function testWriteReadIncrements(self)
            fHeader = topsFile.newTopsFileHeader( ...
                'fileName', self.fileName, ...
                'filePath', self.filePath);
            
            for ii = 1:10
                fHeader = topsFile.write(fHeader, ii);
                fHeader = topsFile.write(fHeader, -ii);
                [fHeader, increments] = topsFile.read(fHeader);
                assertEqual(numel(increments), 2, ...
                    'should read increments that were written')
                assertEqual(increments{1}, ii, ...
                    'should get first written increment, first')
                assertEqual(increments{2}, -ii, ...
                    'should get last written increment, last')
                
                [fHeader, increments] = topsFile.read(fHeader);
                assertTrue(isempty(increments), ...
                    'should not reread increments that were already read')
            end
        end
        
        function testRereadData(self)
            fHeader = topsFile.newTopsFileHeader( ...
                'fileName', self.fileName, ...
                'filePath', self.filePath);
            
            n = 10;
            for ii = 1:n
                fHeader = topsFile.write(fHeader, ii);
            end
            [fHeader, increments] = topsFile.read(fHeader);
            assertEqual(numel(increments), n, ...
                'should read all increments that were written')
            
            [fHeader, increments] = topsFile.read(fHeader);
            assertTrue(isempty(increments), ...
                'should not reread increments that were already read')
            
            [fHeader, increments] = topsFile.read( ...
                fHeader, fHeader.readIncrements);
            assertEqual(numel(increments), n, ...
                'should reread specified increments')
        end
    end
end