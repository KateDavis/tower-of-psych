classdef EncounterBattleQueue < handle
    %Skeletal queue of feval()able cell arrays, for "encounter" game
    %   With thought, may get promoted to topsFoundataion
    
    properties
        fevalables = {};
        isLocked = false;
    end
    
    methods
        function self = EncounterBattleQueue
        end
        
        function flushQueue(self)
            self.fevalables = {};
        end
        
        function addFevalable(self, fevalable)
            self.fevalables{end+1} = fevalable;
        end
        
        function dispatchNextFevalable(self)
            if ~self.isLocked && length(self.fevalables) > 0
                feval(self.fevalables{1}{:});
                topsDataLog.logMnemonicWithData('battleQueue dispatched', self.fevalables{1});
                self.fevalables(1) = [];
            end
        end
    end
end