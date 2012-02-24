classdef SquareTagAV < handle
    % @class SquareTagAV
    % Manage graphics and sound for the "SquareTag" task.
    % @details
    % SquareTagAV is the audio-visual "front end" of the SquareTag task.
    % It manages look and feel and graphical and sound resources.
    % @details
    % SquareTagAV should transform the unitless geometry of SquareTagLogic
    % into viewable graphics and possibly fun sounds.  It "knows about" a
    % SquareTagLogic, so it can base the graphics and sound on data in the
    % SquareTagLogic object.  It shouldn't modify the SquareTagLogic
    % object.
    % @details
    % SquareTagAV doesn't know *when* do do graphics and sound behaviors.
    % It's up to some other function or class to coordinate the behaviors
    % of a SquareTagLogic and SquareTagAV object, probably in conjunction
    % with user input.
    
    properties
        % the SquareTagLogic object to work with
        logic;
    end
    
    methods
        % Make a new AV object.
        function self = SquareTagAV(logic)
            if nargin >= 1
                self.logic = logic;
            end
        end
        
        % Set up audio-visual resources as needed.
        function initialize(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Indicate ready to tag the first square.
        function doFirstSquare(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Indicate ready to tag next square.
        function doNextSquare(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Update the subject's cursor.
        function updateCursor(self)
        end
    end
end
