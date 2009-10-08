classdef ScrollingControlGrid < handle
    %Manage a grid of uicontrols, less irritating than uitable
    
    properties
        parent;
        position;
        
        panel;
        slider;
        controlPanel;
        controls;
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
                'HandleVisibility', 'off', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
            
            self.slider = uicontrol( ...
                'Parent', self.panel, ...
                'Max', 1, ...
                'Min', 0, ...
                'Units', 'normalized', ...
                'Position', [.95 0 .05 1], ...
                'String', '', ...
                'Style', 'slider', ...
                'SliderStep', [.01 .1], ...
                'Value', 0, ...
                'Callback', {@ScrollingControlGrid.respondToSlider, self}, ...
                'HandleVisibility', 'off', ...
                'HitTest', 'on', ...
                'Visible', 'on');
            
            self.controlPanel = uipanel( ...
                'Parent', self.panel, ...
                'BorderType', 'none', ...
                'BorderWidth', 0, ...
                'Title', '', ...
                'BackgroundColor', 'none', ...
                'Units', 'normalized', ...
                'Position', [0 0 .95 1], ...
                'Clipping', 'on', ...
                'HandleVisibility', 'off', ...
                'HitTest', 'off', ...
                'SelectionHighlight', 'off', ...
                'Visible', 'on');
        end
        
        function h = newControlAtRowAndColumn(self, row, column, varargin)
            z = size(self.controls);
            if (z(1) >= row) && (z(2) >= column)
                h = self.controls(row, column);
                if ishandle(h) && h > 0
                    delete(h);
                end
            end
            h = uicontrol(varargin{:}, 'Parent', self.controlPanel);
            self.controls(row, column) = h;
            self.repositionControls;
        end
        
        function removeControlAtRowAndColumn(self, row, column)
            z = size(self.controls);
            if (z(1) >= row) && (z(2) >= column)
                h = self.controls(row, column);
                if ishandle(h) && h > 0
                    delete(h);
                end
            end
            self.controls(row, column) = 0;
            self.trimEdges;
            self.repositionControls;
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
            % this is ugly, since want normalized width but
            % character-spaced heights.
            
            % establish the correct controlPanel size,
            %   in character units
            z = size(self.controls);
            set(self.controlPanel, 'Units', 'Characters');
            charPos = get(self.controlPanel, 'Position');
            charPos = [0 0 charPos(3) z(1)];
            set(self.controlPanel, 'Position', charPos);
            
            % divvy up character units to each control
            %   then make them normalized for any figure resizing
            for ii = 1:z(1)
                for jj = 1:z(2)
                    h = self.controls(ii,jj);
                    if h > 0 && ishandle(h)
                        pos = subposition(charPos, z(1), z(2), z(1)-ii+1, jj);
                        set(h, 'Units', 'Characters', ...
                            'Position', pos, ...
                            'Units', 'normalized');
                    end
                end
            end
            
            % make the controlPanel normalized for resizing and scrolling
            %   and place it at the top of the main panel.
            set(self.controlPanel, 'Units', 'normalized');
            normPos = get(self.controlPanel, 'Position');
            y = 1-normPos(4);
            normPos(1:2) = [0, y];
            set(self.controlPanel, 'Position', normPos);
            
            % only allow scrolling when the controlPanel is too big to fit
            if y < 0
                set(self.slider, 'Max', -y, 'Min', 0, ...
                    'Value', -y, 'Enable', 'on');
                drawnow
            else
                set(self.slider, 'Enable', 'off');
            end
        end
    end
    
    methods(Static)
        function respondToSlider(slider, event, self)
            normPos = get(self.controlPanel, 'Position');
            normPos(2) = -get(slider, 'Value');
            set(self.controlPanel, 'Position', normPos);
        end
    end
end