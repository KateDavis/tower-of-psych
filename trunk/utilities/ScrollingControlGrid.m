classdef ScrollingControlGrid < handle
    % @class ScrollingControlGrid
    % A grid of uicontrol objects.
    % ScrollingControlGrid is an alternative to Matlab's built-in uitable.
    % Like uitable, it presents rows and columns of data and controls that
    % you specify.  ScrollingControlGrid has fewer explicit features than
    % uitable and fewer arbitrary limitations.
    % <br><br>
    % The basic idea is that the ScrollingControlGrid contains a
    % two-dimensional matrix of handles to uicontrol objects.  It arranges
    % all these uicontrols within a figure or uipanel, with the same row
    % and column layout as the handles in the matrix.
    % <br><br>
    % The grid also provides a scroll bar so that the uicontrols can be
    % moved up and down and large numbers of uicontrols can be accomodated.
    % <br><br>
    % The two-dimensional matrix of handles can contain redundant entries.
    % uicontrols with multiple entries will have their Positions stretched
    % to cover all of the individual row and column Positions.
    % ScrollingControlGrid makes no attempt to prevent collisions among
    % stretched uicontrols.
    % <br><br>
    % ScrollingControlGrid can manage uicontrol objects of any 'Style' and
    % only specifies their 'Parent', 'Position', and 'Units' properties.
    % So ScrollingControlGrid should accomodate many user interface tasks
    % that call for a roughly grid-like presentation of data or controls.
    % @ingroup utilities
    
    properties
        % the figure or uipanel that contains the ScrollingControlGrid
        parent;
        
        % [x y w h] in normalized units of the ScrollingControlGrid within
        % its parent
        position;
        
        % a two-dimensional matrix of handles to uicontrol objects
        controls;
        
        % height in characters units of individial uicontrol objects
        rowHeight = 1.5;
        
        panel;
        slider;
        controlPanel;
    end
    
    methods
        % Contructor takes two optional arguments.
        % @param parent figure or uipanel to contain the new
        % ScrollingControlGrid.  Uses gcf() if @a parent is missing.
        % @param position [x y w h] in normalized units of the
        % ScrollingControlGrid within @a parent.  Uses [0 0 1 1] if
        % @a position is missing.
        function self = ScrollingControlGrid(parent, position)
            if nargin
                self.parent = parent;
            else
                self.parent = gcf;
            end
            
            if nargin > 1
                self.position = position;
            else
                self.position = [0 0 1 1];
            end
            self.initPanels;
        end
        
        function delete(self)
            if ishandle(self.panel) && self.panel > 0
                delete(self.panel)
            end
        end
        
        % Deletes all uicontrols in the two-dimensional controls matrix.
        % @details
        % Calls delete() on all of the handles in the grid's controls
        % matrix, then sets the controls matrix to [].
        function deleteAllControls(self)
            h = self.controls;
            delete(h(ishandle(h) & (h > 0)));
            self.controls = [];
            self.repositionControls;
        end
        
        % Add a new uicontrol to the grid.
        % @param row the grid row to add the uicontrol to.  @a row
        % may be an array of row indices, in which case the uicontrol will
        % be stretched vertically.
        % @param column the grid column to add the uicontrol to.
        % @a column may be an array of column indices, in which case
        % the uicontrol will be stretched horizontally.
        % @param varargin uicontrol property-value pairs.  These are the
        % same property-value pairs you might pass to the uicontrol() or
        % set() function.
        % @details
        % Returns a handle to a newly created uicontrol object, and adds
        % the handle to the grid's two-dimensional matrix of handles, at
        % @a row and @a column.  The new uicontrol will use all
        % property-value pairs contained in @a varargin.  In
        % addition, the new uicontrol will have its Parent property set by
        % the grid.
        % <br><br> @a row and/or @a column may be array of
        % indices. In that case, the new uicontrol's handle will be added
        % redundantly to multiple grid locations and it's appearance will
        % be stretched to cover all the individual locations.  Matlab's
        % default indexing behavior is to add the handle to all
        % combinations of row(i) and column(j) in the matrix.
        % <br><br>
        % The grid won't automatically update its appearance, after adding
        % a new uicontrol.  This allows controls to be added in batches and
        % speeds up performance.  To update the grid appearance, call
        % repositionControls().
        function h = newControlAtRowAndColumn(self, row, column, varargin)
            z = size(self.controls);
            h = uicontrol(varargin{:}, 'Parent', self.controlPanel);
            self.controls(row, column) = h;
        end
        
        % Remove the uicontrol at the given row and column
        % @param row a scalar row index for the uicontrol to remove
        % @param column a scalar column index for the uicontrol to remove
        % @details
        % Looks for a uicontrol handle in the controls matrix, at
        % @a row and @a column.  Calls delete() for any handle
        % it finds there.  Then sets all entries in the controls matrix
        % that match the handle to 0.  If removing a control results in
        % empty rows on the bottom of the grid, or empty columns on the
        % right, these will be trimmed.
        function removeControlAtRowAndColumn(self, row, column)
            z = size(self.controls);
            if (z(1) >= row) && (z(2) >= column)
                h = self.controls(row, column);
                if ishandle(h) && h > 0
                    delete(h);
                end
                self.controls(self.controls == h) = 0;
            end
            self.trimEdges;
        end
        
        % Refresh the layout of all uicontrols.
        % @details
        % Recalculates the Position property for all uicontrol objects in
        % the grid's controls matrix, to match the rows and columns of the
        % matrix itself.  Uses a constant height for all rows of controls,
        % as specified by the grid's rowHeight property (character units).
        % Stretches columns to fill the width of the entire grid.
        % <br><br>
        % When there are too many rows to fit vertically in the grid, they
        % will run off the bottom and a slider bar will appear on the right
        % side.  It can be dragged to expose unseen controls.
        % <br><br>
        % After setting the individual uicontrol Positions, sets their
        % Units property to normalized.  Thus, subsequent resizing of the
        % figure that contains the grid will cause the all the controls to
        % stretch.  If you call repositionControls() from the figure's
        % ResizeFcn, the controls will maintain their constant height in
        % character units.
        function repositionControls(self)
            % establish the correct controlPanel size,
            %   in character units
            z = size(self.controls);
            if ~any(z)
                return;
            end
            
            set(self.controlPanel, 'Visible', 'off', 'Units', 'Characters');
            charPos = get(self.controlPanel, 'Position');
            charPos = [0 0 charPos(3) max(1, z(1)*self.rowHeight)];
            
            % size controlPanel, *then* set it to normalized
            %   then place it at the top of the main panel.
            set(self.controlPanel, 'Position', charPos, 'Units', 'normalized');
            normPos = get(self.controlPanel, 'Position');
            y = 1-normPos(4);
            normPos(1:2) = [0, y];
            set(self.controlPanel, 'Position', normPos);
            
            % divvy up character units to each control
            % stretch controls with redundant entries
            % then normalized controls for figure resizing
            alreadyPlaced = [];
            for ii = 1:z(1)
                for jj = 1:z(2)
                    h = self.controls(ii,jj);
                    if h > 0 && ishandle(h)
                        set(h, 'Units', 'Characters');
                        gridPos = subposition(charPos, z(1), z(2), z(1)-ii+1, jj);
                        if any(h == alreadyPlaced)
                            % stretch this control
                            controlPos = get(h, 'Position');
                            gridPos = ScrollingControlGrid.mergePositionRects(controlPos, gridPos);
                        end
                        alreadyPlaced(end+1) = h;
                        set(h, 'Position', gridPos, 'Units', 'normalized');
                    end
                end
            end
            set(self.controlPanel, 'Visible', 'on');
            
            % only allow scrolling when the controlPanel is too big to fit
            if y < 0
                set(self.slider, 'Max', -y, 'Min', 0, ...
                    'Value', -y, 'Enable', 'on', 'Visible', 'on');
            else
                set(self.slider, 'Enable', 'off', 'Visible', 'off');
            end
        end

        function trimEdges(self)
            % trim empty edge rows and columns
            z = size(self.controls);
            keepRow = logical(ones(1,z(1)));
            for ii = z(1):-1:1
                row = self.controls(ii,:);
                keepRow(ii) = any(ishandle(row) & (row > 0));
                if keepRow(ii)
                    break;
                end
            end
            self.controls = self.controls(keepRow,:);
            
            keepColumn = logical(ones(1,z(2)));
            for jj = z(2):-1:1
                column = self.controls(:,jj);
                keepColumn(jj) = any(ishandle(column) & (column > 0));
                if keepColumn(jj)
                    break;
                end
            end
            self.controls = self.controls(:,keepColumn);
        end
        
        function initPanels(self)
            h = [self.slider, self.panel, self.controlPanel, self.controls];
            delete(h(ishandle(h)));
            
            self.panel = uipanel( ...
                'Parent', self.parent, ...
                'BorderType', 'line', ...
                'BorderWidth', 1, ...
                'ForegroundColor', [1 1 1]*.7, ...
                'HighlightColor', [1 1 1]*.7, ...
                'Title', '', ...
                'BackgroundColor', 'none', ...
                'Units', 'normalized', ...
                'Position', self.position, ...
                'Clipping', 'on', ...
                'HandleVisibility', 'on', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
            
            xDiv = .90;
            self.slider = uicontrol( ...
                'Parent', self.panel, ...
                'Max', 1, ...
                'Min', 0, ...
                'Units', 'normalized', ...
                'Position', [xDiv+.01 0 1-xDiv 1], ...
                'String', '', ...
                'Style', 'slider', ...
                'SliderStep', [.01 .1], ...
                'Value', 0, ...
                'Callback', {@ScrollingControlGrid.respondToSliderOrScroll, self}, ...
                'HandleVisibility', 'off', ...
                'HitTest', 'on', ...
                'Enable', 'off', ...
                'Visible', 'off');
            
            self.controlPanel = uipanel( ...
                'Parent', self.panel, ...
                'BorderType', 'line', ...
                'BorderWidth', 1, ...
                'ForegroundColor', [1 1 1]*.7, ...
                'HighlightColor', [1 1 1]*.7, ...
                'Title', '', ...
                'BackgroundColor', 'none', ...
                'Units', 'normalized', ...
                'Position', [0 0 xDiv 1], ...
                'Clipping', 'on', ...
                'HandleVisibility', 'off', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
        end
    end
    
    methods(Static)
        function respondToSliderOrScroll(obj, event, self)
            if strcmp(get(self.slider, 'Enable'), 'on')
                y = -get(self.slider, 'Value');
                if isfield(event, 'VerticalScrollCount')
                    % mouse scroll event
                    scroll = .01*event.VerticalScrollCount;
                    bottom = -get(self.slider, 'Max');
                    y = min(max(y+scroll, bottom), 0);
                    set(self.slider, 'Value', -y);
                end
                normPos = get(self.controlPanel, 'Position');
                normPos(2) = y;
                set(self.controlPanel, 'Position', normPos);
            end
        end
        
        function mergedPos = mergePositionRects(varargin)
            % take cell array of [x,y,w,h] position rects
            p = vertcat(varargin{:});
            l = min(p(:,1));
            b = min(p(:,2));
            r = max(p(:,1)+p(:,3));
            t = max(p(:,2)+p(:,4));
            mergedPos = [l, b, r-l, t-b];
        end
    end
end