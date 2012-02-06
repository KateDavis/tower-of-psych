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
            headerText = topsFigure.htmlWrapFontColor(headerText, color);
            infoText = self.makeHTMLInfoText(self.currentItem, [1 1 1]);
            summary = sprintf('%s\n%s', headerText, infoText);
            summary = topsFigure.htmlBreakAtLines(summary);
            self.jWidget.setText(summary);
            
            % make sure the java widget is up to date
            bg = self.parentFigure.backgroundColor;
            jColor = java.awt.Color(bg(1), bg(2), bg(3));
            self.jWidget.setBackground(jColor);
        end
    end
    
    methods (Access = protected)
        % Create and arrange fresh components.
        function initialize(self)
            self.initialize@topsPanel();
            
            % create a Java Swing widget capable of showing HTML content
            self.jWidget = javax.swing.JEditorPane('text/html', '');
            self.jWidget.setEditable(false);
            self.jWidget.setBorder([]);
            
            % put the widget in a scrollable Swing container
            self.jContainer = javax.swing.JScrollPane(self.jWidget);
            self.jContainer.setBorder([]);
            
            % display the Swing container through this Matlab panel
            %   javacomponent() is an undocumented built-in function
            %   see http://undocumentedmatlab.com/blog/javacomponent/
            [self.infoWidget, self.infoContainer] = ...
                javacomponent(self.jContainer, [], self.pan);
            set(self.infoContainer, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1]);
        end
        
        % Make disp()-style HTML info for a Matlab variable.
        function info = makeHTMLInfoText(self, item, color)
            
            if ischar(item)
                % item is a string, quote it and color it
                info = self.stringQuotesAndColor(item);
                
            else
                % use what disp() has to say about the item
                info = evalc('disp(item)');
                info = topsFigure.htmlStripAnchors(info, false);
                info = topsFigure.htmlWrapFontColor(info, color);
            end
        end
        
        % Add quotes and HTML color tags for a string.
        function colorQuoted = stringQuotesAndColor(self, string)
            quoted = sprintf('''%s''', string);
            colors = self.parentFigure.colors;
            color = topsFigure.getColorForString(string, colors);
            colorQuoted = topsFigure.htmlWrapFontColor(quoted, color);
        end
    end
end