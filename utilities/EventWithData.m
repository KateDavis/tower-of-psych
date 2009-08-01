classdef EventWithData < event.EventData
    % It's outrageous--outrageous--that Matlab's EventData superclass
    % doesn't have a UserData property, or a default subclass with user
    % data.  Here it is.
    
    properties
        UserData;
    end
    
    methods
        function self = EventWithData(UserData)
            if nargin
                self.UserData = UserData;
            end
        end
    end
end