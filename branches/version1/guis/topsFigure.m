classdef topsFigure < handle
    % The top-level container for Tower of Psych GUIs.
    % @details
    % topsFigure manages a Matlab figure window for use by Tower od Psych
    % Graphical User Interfaces (GUIs).  Each topsFigure can contain one or
    % more content panels which show custom plots and data, and a few
    % buttons.
    % @details
    % topsFigure also defines a standard "look and feel" for GUIs, by
    % choosing things like how to lay out GUI components and what colors
    % they should be.
    % @details
    % With the help of its content panels, topsFigure keeps track of a
    % "current item".  This may be any Matlab variable, such as a Tower of
    % Psych object or a piece of data, which was most recently viewed or
    % used through the GUI.  The various content panels can work together
    % by all using the same "current item".  topsFigure provides buttons
    % for sending the current item to the Command Window workspace and for
    % viewing the current item in more detail.
    %
    % @ingroup guis
    
    properties (SetAccess = protected)
        % GUI name to display in the figure title bar
        name = 'Tower of Psych';
        
        % the color to use for backgrounds
        backgroundColor = [0.98 0.98 0.92];
        
        % the color to use for midgrounds or secondary text
        midgroundColor = [0.3 0.2 0.1];
        
        % the color to use for foregrounds or primary text
        foregroundColor = [0 0 0];
        
        % color map to use for alternate foreground colors
        colors = puebloColors(9);
        
        % default font typeface to use for text
        fontName = 'Helvetica';
        
        % default font size to use for text
        fontSize = 12;
        
        % the Matlab figure window
        fig;
        
        % how to divide the figure area between button and main panels
        figureDiv = [8 92];
        
        % the figure area reserved for content panels
        mainPanel;
        
        % 2D cell array of topsPanel objects
        contentPanels = {};
        
        % the figure area reserved for buttons
        buttonPanel;
        
        % array of button graphics handles
        buttons = [];
        
        % the "current item" in use in the GUI
        currentItem;
        
        % name to give the "current item"
        currentItemName;
    end
    
    methods
        % Open an new topsFigure.
        % @param name optional name to give the figure.
        % @param varargin optional property-value pairs to set
        % @details
        % Opens a new topsFigure and initializes components.  If @a name is
        % provided, displays @a name in the title bar.  If @a varargin is
        % provided, it should contain property-value pairs to set before
        % initialization.
        function self = topsFigure(name, varargin)
            % use given name
            if nargin >= 1
                self.setName(name);
            end
            
            % set immutable properties before initialization
            if nargin >= 3
                for ii = 1:2:numel(varargin);
                    prop = varargin{ii};
                    val = varargin{ii+1};
                    self.(prop) = val;
                end
            end
            
            % initialize using given properties
            self.initialize();
        end
        
        % Close the Matlab figure when this topsFigure is destroyed.
        function delete(self)
            if ishandle(self.fig)
                delete(self.fig);
            end
        end
        
        % Make a Matlab figure with a certain look and feel.
        function f = makeFigure(self)
            f = figure( ...
                'Color', self.backgroundColor, ...
                'Colormap', self.colors, ...
                'MenuBar', 'none', ...
                'Name', self.name, ...
                'NumberTitle', 'off', ...
                'ResizeFcn', [], ...
                'ToolBar', 'none', ...
                'WindowKeyPressFcn', {}, ...
                'WindowKeyReleaseFcn', {}, ...
                'WindowScrollWheelFcn', {});
        end
        
        % Make a Matlab uipanel with a certain look and feel
        % @param parent figure or uipanel to hold the new uipane.
        % @details
        % Returns a new uipanel which is a child of the given @a parent, or
        % mainPanel if @a parent is omitted.  At first, the ui panel is not
        % visible.
        function p = makeUIPanel(self, parent)
            if nargin < 2
                parent = self.mainPanel;
            end
            
            p = uipanel( ...
                'BorderType', 'none', ...
                'BorderWidth', 0, ...
                'FontName', self.fontName, ...
                'ForegroundColor', self.foregroundColor, ...
                'HighlightColor', self.midgroundColor, ...
                'ShadowColor', self.backgroundColor, ...
                'Title', '', ...
                'BackgroundColor', self.backgroundColor, ...
                'Units', 'normalized', ...
                'Parent', parent, ...
                'SelectionHighlight', 'off', ...
                'Visible', 'off');
        end
        
        % Make a widget capable of displaying HTML content.
        % @param parent figure or uipanel to hold the new widget.
        % @details
        % Makes a new HTML widget which is a child of the given @a
        % parent, or mainPanel if @a parent is omitted.  The widget
        % is wrapped in a container which can scroll as needed.  Both a
        % Matlab graphics handle and a Java object are returned, for both
        % the widget and the container.  The four outputs are returned
        % following order:
        %   - widget handle
        %   - container handle
        %   - widget Java object
        %   - container Java object.
        %   .
        function [widget, container, jWidget, jContainer] = ...
                makeHTMLWidget(self, parent)
            if nargin < 2
                parent = self.mainPanel;
            end
            
            % create a Java Swing widget capable of showing HTML content
            %   put the widget in a scrollable Swing container
            jWidget = javax.swing.JEditorPane('text/html', '');
            jWidget.setEditable(false);
            jContainer = javax.swing.JScrollPane(jWidget);
            
            % set the default appearance of the widget and container
            jWidget.setBorder([]);
            jContainer.setBorder([]);
            
            c = self.backgroundColor;
            jColor = java.awt.Color(c(1), c(2), c(3));
            jWidget.setForeground(jColor);
            jWidget.setBackground(jColor);
            
            c = self.foregroundColor;
            jColor = java.awt.Color(c(1), c(2), c(3));
            jContainer.setForeground(jColor);
            jContainer.setBackground(jColor);
            
            % setting the font takes a little Java work
            jFont = java.awt.Font( ...
                self.fontName, java.awt.Font.PLAIN, self.fontSize);
            jWidget.setFont(jFont);
            java.lang.System.setProperty( ...
                'awt.useSystemAAFontSettings', 'on');
            jWidget.putClientProperty( ...
                javax.swing.JEditorPane.HONOR_DISPLAY_PROPERTIES, true);
            property = ...
                com.jidesoft.swing.JideSwingUtilities.AA_TEXT_PROPERTY_KEY;
            jWidget.putClientProperty(property, true);
            
            % display the widget and container through the given parent
            %   javacomponent() is an undocumented built-in function
            %   see http://undocumentedmatlab.com/blog/javacomponent/
            [widget, container] = javacomponent(jContainer, [], parent);
            set(container, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1]);
        end
        
        % Choose the name to display in the figure title bar.
        % @param name string name of the figure
        % @details
        % Assigns @a name to this object and updates the Matlab figure
        % window.
        function setName(self, name)
            self.name = name;
            set(self.fig, 'Name', name);
        end
        
        % Choose the current item and tell panels to update.
        % @param currentItem the new current item
        % @param currentItemName name to use for the current item
        % @details
        % Assigns @a currentItem and @a currentItemName to this figure and
        % any panels.
        function setCurrentItem(self, currentItem, currentItemName)
            self.currentItem = currentItem;
            self.currentItemName = currentItemName;
            self.refresh(false);
            
            for ii = 1:numel(self.contentPanels)
                self.contentPanels{ii}.setCurrentItem( ...
                    currentItem, currentItemName);
            end
        end
        
        % Choose the content panels to use in this GUI.
        % @param panels 2D cell array of topsPanel objects
        % @param yDiv array specifying how to arrange panels vertically
        % @param xDiv array specifying how to arrange panels horizontally
        % @details
        % Assigns the given @a panels to work with this topsFigure to make
        % a GUI.  @a panels should be a 2D cell array, where the rows and
        % columns indicate how the panels should be layed out graphically.
        % The first row and first column correspond to the bottom left
        % corner of the main panel.  Where @a panels contains empty
        % elements, the main panel is left blank.  If @a panels contains
        % duplicate adjacent elements, the duplicated panel is stretched to
        % fill more than one row or column.
        % @details
        % By default, the main panel is divided evenly into rows and
        % columns.  @a xDiv and @a yDiv may specify uneven divisions.
        % @a xDiv should have one element for each column of @a panels, and
        % @a yDiv should have one element for each row.  The elemets of @a
        % xDiv or @a yDiv specify the relative width or height of each
        % column or row, respectively.
        % @details
        % Sets the Position of each panel's uipanel for the given layout,
        % and makes each panel Visible.
        function setPanels(self, panels, yDiv, xDiv)
            % use the given panels
            self.contentPanels = panels;
            
            % choose the row divisions
            nRows = size(panels, 1);
            if nargin < 4
                yDiv = ones(1, nRows) ./ nRows;
            else
                yDiv = yDiv ./ sum(yDiv);
            end
            y = [0 cumsum(yDiv)];
            
            % choose the column divisions
            nCols = size(panels, 2);
            if nargin < 3
                xDiv = ones(1, nCols) ./ nCols;
            else
                xDiv = xDiv ./ sum(xDiv);
            end
            x = [0 cumsum(xDiv)];
            
            % keep track of handles of uipanels already positioned
            alreadyPositioned = [];
            for ii = 1:nRows
                for jj = 1:nCols
                    % where is this grid cell?
                    cellPosition = [x(jj) y(ii) xDiv(jj) yDiv(ii)];
                    
                    % what is this topsPanel's uipanel handle?
                    panel = panels{ii,jj};
                    h = panel.pan;
                    
                    % position each uipanel
                    if ishandle(h)
                        if any(alreadyPositioned == h)
                            % stretch to fill additional grid cells
                            panelPosition = get(h, 'Position');
                            mergedPosition = topsFigure.mergePositions( ...
                                cellPosition, panelPosition);
                            set(h, 'Position', mergedPosition);
                            
                        else
                            % place the panel in a new grid cell
                            alreadyPositioned(end+1) = h;
                            set(h, ...
                                'Units', 'normalized', ...
                                'Position', cellPosition);
                        end
                    end
                end
            end
            
            % now positioned, make all uipanels visible
            set(alreadyPositioned, 'Visible', 'on');
        end
        
        % Tell each content panel to refresh its contents.
        % @param isRefreshPanels whether to also refresh panels
        % @details
        % Refreshes the appearance of this figure.  By default, also
        % invokes refresh() on each panel in contentPanels.  If @a
        % isRefreshPanels is provided and false, only refreshes the figure
        % itself.
        function refresh(self, isRefreshPanels)
            
            if nargin < 2
                isRefreshPanels = true;
            end
            
            % any self behaviors?
            
            % refresh each panel
            if isRefreshPanels
                for ii = 1:numel(self.contentPanels)
                    self.contentPanels{ii}.refresh();
                end
            end
        end
        
        % Send the current item to the Command Window workspace.
        function currentItemToCommandWindow(self)
            
        end
        
        % Try to open the current item as a file.
        function currentItemOpen(self)
            
        end
        
        % View details of the current item.
        function currentItemInfo(self)
            
        end
    end
    
    methods (Access = private)
        % Create and arrange fresh components.
        function initialize(self)
            if ishandle(self.fig)
                delete(self.fig);
            end
            
            self.fig = self.makeFigure();
            fd = self.figureDiv ./ sum(self.figureDiv);
            self.mainPanel = self.makeUIPanel(self.fig);
            self.buttonPanel = self.makeUIPanel(self.fig);
            set(self.mainPanel, ...
                'Position', [0 fd(1) 1 fd(2)], ...
                'Visible', 'on');
            set(self.buttonPanel, ...
                'Position', [0 0 1 fd(1)], ...
                'Visible', 'on');
        end
    end
    
    methods (Static)
        % Calculate a position that bounds other positions.
        % @param varargin one or more position rectangles
        % @details
        % Merges one or more position rectangles of the form [x y width
        % height] into one big position that bounds all of the given
        % rectangles.
        function merged = mergePositions(varargin)
            % take cell array of [x y width height] rects
            p = vertcat(varargin{:});
            l = min(p(:,1));
            b = min(p(:,2));
            r = max(p(:,1)+p(:,3));
            t = max(p(:,2)+p(:,4));
            merged = [l, b, r-l, t-b];
        end
        
        % Pick a color for the given string, based on its spelling.
        % @param string any string
        % @param colors nx3 matrix with one color per row (RGB, 0-1)
        % @details
        % Maps the given @a string to one of the rows in @a colors, based
        % on the spelling of @a string.  The same string will always map to
        % the same row.  Multiple strings will also map to each row.
        function col = getColorForString(string, colors)
            hashRow = 1 + mod(sum(string), size(colors,1));
            col = colors(hashRow, :);
        end
        
        % Wrap the given string with HTML font tags.
        % @param string any string
        % @param color 1x3 color (RGB, 0-1)
        % @param isEmphasis whether to apply @em emphasis formatting
        % @param isStrong whether to apply @b strong formatting
        % @details
        % Wraps the given @a string in HTML tags which specify font
        % formatting.  @a color must contain RBG components in the range
        % 0-1.  @a isEmphasis specifies whether to apply @em emphasis
        % (true) or not.  @a isStrong specifies whether to apply @b strong
        % formatting or not.  @a color, @a isEmphasis, or @a isStrong may
        % be omitted empty, in which case no formatting is specified.
        % @details
        % Returns the given @a string, wrapped in HTML tags.
        function string = htmlWrapFormat( ...
                string, color, isEmphasis, isStrong)
            
            % Apply color?
            if nargin >=2 && ~isempty(color)
                colorHex = dec2hex(round(color*255), 2)';
                colorName = colorHex(:)';
                string = sprintf('<FONT color="%s">%s</FONT>', ...
                    colorName, string);
            end
            
            % Apply emphasis?
            if nargin >=3 && isEmphasis
                string = sprintf('<EM>%s</EM>', string);
            end
            
            % Apply strong?
            if nargin >=4 && isStrong
                string = sprintf('<STRONG>%s</STRONG>', string);
            end
        end
        
        % Strip out HTML anchors and anchor tags from a string.
        % @param string any string
        % @param isPreserveText whether to leave the anchor text in place
        % @param stripPrefix additional regexp to strip before each anchor
        % @details
        % Strips out HTML anchors (like "a=href", etc.) from the given
        % @a string.  By default, strips out the anchor text along with the
        % anchor tags.  If @a isPreserverText is provided and true, leaves
        % the anchor text without the tags.  If @a stripPrefix is provided,
        % also strips out patterns that match the regular expression @a
        % stripPrefix, immediately before anchors.
        function stripped = htmlStripAnchors( ...
                string, isPreserveText, stripPrefix)
            
            if nargin < 2 || isempty(isPreserveText)
                isPreserveText = false;
            end
            
            if nargin < 3 || isempty(stripPrefix)
                stripPrefix = '';
            end
            
            anchorPat = '<[Aa][^<]*>([^<]*)</[Aa]>';
            stripPat = [stripPrefix anchorPat stripPrefix];
            if isPreserveText
                stripped = regexprep(string, stripPat, '$1');
            else
                stripped = regexprep(string, stripPat, '');
            end
        end
        
        % Replace newline characters with HTML break tags.
        % @param string any string
        % @details
        % Replaces any newline (\n) or return carriage (\r) characters in
        % the given @a string with HTML <br/> break tags.
        function breaked = htmlBreakAtLines(string)
            newLinePat = '([\n\r]+)';
            breaked = regexprep(string, newLinePat, '<br />');
        end
    end
end