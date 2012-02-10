classdef topsPanel < handle
    % The bottom-level container for Tower of Psych GUIs.
    % @details
    % topsPanel provides a uniform interface for detailed content panels.
    % The uniform interface allows multiple panels to collaborate with a
    % topsFigure and with each other.
    % @details
    % Each panel manages a Matlab uipanel, in which it can display plots,
    % data, text, etc., as well as interactive controls.
    % @details
    % Each panel also keeps track of a "current item".  This may be any
    % Matlab variable, such as a Tower of Psych object or a piece of data,
    % which was most recently viewed or used through the GUI.  A panel can
    % set the current item in response to user actions, or update itself to
    % reflect a current item that was selected in a different panel.
    % @details
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % the topsFigure that holds this panel
        parentFigure;
        
        % the Matlab uipanel
        pan;
        
        % whether to leave the currentItem and contents as static
        isLocked = false;
        
        % the "current item" in use in the GUI
        currentItem;
        
        % name to give the "current item"
        currentItemName;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsPanel to show GUI content.  @a parentFigure
        % must be a topsFigure object, otherwise the panel won't display
        % any content.
        function self = topsPanel(parentFigure)
            if nargin >= 1
                self.parentFigure = parentFigure;
                self.initialize();
                self.refresh();
            end
        end
        
        % Clear references to graphics and handle objects.
        function delete(self)
            if ishandle(self.pan)
                delete(self.pan);
            end
        end
        
        % Choose the current item.
        % @param currentItem the new current item
        % @param currentItemName name to use for the current item
        % @details
        % Assigns @a currentItem and @a currentItemName to this panel and
        % refreshes the panel contents.
        function setCurrentItem(self, currentItem, currentItemName)
            if ~self.isLocked
                self.currentItem = currentItem;
                self.currentItemName = currentItemName;
            end
        end
        
        % Refresh the panel's contents.
        function refresh(self)
            if ~self.isLocked
                self.updateContents();
            end
        end
    end
    
    methods (Access = protected)
        % Update the panel's contents (used internally)
        function updateContents(self)
            
        end
        
        % Create and arrange fresh components.
        function initialize(self)
            if ishandle(self.pan)
                delete(self.pan);
            end
            self.pan = self.parentFigure.makeUIPanel();
        end
    end
end