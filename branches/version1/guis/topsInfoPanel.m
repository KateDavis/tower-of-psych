classdef topsInfoPanel < topsPanel
    % Summarize the current item, like disp() on the command line.
    % @details
    % topsInfoPanel shows a summary of the "current item" of a Tower of
    % Psych GUI.  The summary comes from the built-in disp() command,
    % captured as a string.  Data of type char are highlighted according to
    % their spelling.
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % handle for an HTML display panel
        infoWidget;
        
        % handle for an HTML display panel container
        infoContainer;
        
        % HTML display panel java object
        jWidget;
        
        % HTML display container java object
        jContainer;
    end
    
    methods
        % Make a new panel in the given figure.
        % @param parentFigure topsFigure to work with
        % @details
        % Creates a new topsInfoPanel.  @a parentFigure must be a
        % topsFigure object, otherwise the panel won't display any content.
        function self = topsInfoPanel(varargin)
            self = self@topsPanel(varargin{:});
        end
        
        % Refresh the panel's contents.
        function refresh(self)
            % display a summary of the current item
            color = self.parentFigure.midgroundColor;
            headerText = sprintf('"%s" is a %s:', ...
                self.currentItemName, class(self.currentItem));
            headerText = topsFigure.htmlWrapFormat( ...
                headerText, color, true, false);
            
            infoText = self.makeHTMLInfoText(self.currentItem);
            
            summary = sprintf('%s\n%s', headerText, infoText);
            summary = topsFigure.htmlBreakAtLines(summary);
            self.jWidget.setText(summary);
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            [self.infoWidget, self.infoContainer, ...
                self.jWidget, self.jContainer] = ...
                self.parentFigure.makeHTMLWidget(self.pan);
        end
        
        % Make disp()-style HTML info for a Matlab variable.
        function info = makeHTMLInfoText(self, item, color)
            
            if nargin < 3
                color = self.parentFigure.foregroundColor;
            end
            
            if ischar(item)
                % item is a string, quote it and color it
                info = sprintf('''%s''', item);
                color = topsFigure.getColorForString( ...
                    item, self.parentFigure.colors);
                info = topsFigure.htmlWrapFormat( ...
                    info, color, false, false);
                
            else
                % use what disp() has to say about the item
                info = evalc('disp(item)');
                info = topsFigure.htmlStripAnchors(info, false, '[\s,]*');
                info = topsFigure.htmlWrapFormat( ...
                    info, color, false, false);
            end
        end
        
    end
end