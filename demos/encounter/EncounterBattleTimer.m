classdef battleTimer < handle
    %Skeletal timer class to help schedule "encounter" battle events
    %   with thought, might get promoted to topsFoundataion
    
    properties
        nextFire=inf;
        repeatInterval=inf;
        callback={};
        
        clockFcn = @now;
    end
    
    methods
        function self = battleTimer
        end

        function loadForTimeWithCallback(self, time, callback)
            self.nextFire = time;
            self.callback = callback;
        end

        function loadForRepeatIntervalWithCallback(self, interval, callback)
            self.repeatInterval = interval;
            self.callback = callback;
        end
        
        function beginRepetitions(self)
            nowTime = feval(self.clockFcn);
            self.nextFire = nowTime + self.repeatInterval;
        end
        
        function didFire = tick(self)
            nowTime = feval(self.clockFcn);
            didFire = nowTime >= self.nextFire;
            
            if didFire
                feval(self.callback{:});
                topsDataLog.logMnemonicWithData('battleTimer fired', self.callback);
                self.nextFire = nowTime + self.repeatInterval;
            end
        end
    end
end