classdef TestTopsDataLogGUI < TestCase
    
    properties
        logGui;
    end
    
    methods
        function self = TestTopsDataLogGUI(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            topsDataLog.flushAllData;
            self.logGui = topsDataLogGUI;
        end
        
        function tearDown(self)
            delete(self.logGui);
            self.logGui = [];
            topsDataLog.flushAllData;
        end
        
        function testSingleton(self)
            newGui = topsDataLogGUI;
            assertFalse(self.logGui==newGui, 'topsDataLogGUI should not be a singleton');
            delete(newGui);
        end
    end
end