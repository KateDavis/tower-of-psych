classdef ScrollingControlGrid < handle
    %Manage a grid of uicontrols, less irritating than uitable
    
    properties
        parent;
        position;
        
        panel;
        slider;
        controlPanel;
        controls;
        rowHeight = 1.5;
    end
    
    methods
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
        
        function deleteAllControls(self)
            h = self.controls;
            delete(h(ishandle(h) & (h > 0)));
            self.controls = [];
            self.repositionControls;
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
                'Position', [xDiv 0 1-xDiv 1], ...
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
        
        function h = newControlAtRowAndColumn(self, row, column, varargin)
            z = size(self.controls);
            h = uicontrol(varargin{:}, 'Parent', self.controlPanel);
            self.controls(row, column) = h;
        end
        
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