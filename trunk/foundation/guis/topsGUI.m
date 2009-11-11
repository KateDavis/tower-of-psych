classdef topsGUI < handle
    % @class topsGUI
    % Superclass for Tower of Psych graphical interfaces.
    % You shouldn't need to work with this class unless you're developing a
    % new graphical interface.  If that's what you're doing, you may wish
    % to write a sublcass of topsGUI to take advantage of its features,
    % which are described here briefly.
    % @ingroup foundation
    
    properties(Hidden)
        % Matlab figure to show gui, and delete it when closed.
        figure;
        
        % Toggle to indicate in the title bar that that the gui is busy.
        isBusy = false;
        title = 'tops GUI';
        busyTitle = '(busy...)';
        
        % Color map of colors visible against white, to give subclasses
        % uniform appearance.
        colors;
        
        % struct array of listener objects used by subclass, automatically
        % deleted.
        listeners = struct();
        
        % Struct array of graphical children to receive mouse scroll
        % events.
        scrollables;
        
        % Same offwhite color used by all subclasses.
        lightColor = [1 1 .98];
        
        biggerThanEps = 1e-6;
    end
    
    methods
        % Constructor takes no arguments.
        % Generates standard color map, opens a figure with a standard
        % appearance.
        function self = topsGUI
            self.colors = spacedColors(61);
            self.setupFigure;
        end
        
        % Automatically closes the figure and deletes ny listeners used by
        % a subclass.
        function delete(self)
            if ~isempty(self.figure) && ishandle(self.figure);
                delete(self.figure);
                self.figure = [];
            end
            self.deleteListeners;
        end
        
        function figureClose(self)
            if isvalid(self)
                delete(self)
            end
        end
        
        function deleteListeners(self)
            % would like to use struct2array, but
            % cannot concatenate event.listener withevent.proplistener
            % so, iterate the struct fields
            fn = fieldnames(self.listeners);
            if ~isempty(fn)
                for ii = 1:length(fn)
                    delete([self.listeners.(fn{ii})]);
                end
            end
        end
        
        % Open a figure or clear existing figure.
        % Sets a uniform appearance for subclass figures.  Also defines
        % some figure callbacks:
        %   - ResizeFcn calls repondToResize, which subclasses may redefine
        %   - WindowKeyPressFcn calls respondToKeypress, which subclasses
        %   may redefine
        %   - WindowScrollWheelFcn calls respondToScrolling, which may
        %   pass scrolling events to graphical children in the scrollables
        %   when the mouse is over them.
        function setupFigure(self)
            if ~isempty(self.figure) && ishandle(self.figure)
                clf(self.figure)
            else
                self.figure = figure;
            end
            set(self.figure, ...
                'CloseRequestFcn', @(obj, event) delete(self), ...
                'Renderer', 'zbuffer', ...
                'HandleVisibility', 'on', ...
                'MenuBar', 'none', ...
                'Name', self.title, ...
                'NumberTitle', 'off', ...
                'ToolBar', 'none', ...
                'Units', 'normalized', ...
                'ResizeFcn', @(fig, event)self.repondToResize(fig, event), ...
                'WindowKeyPressFcn', @(fig, event)self.respondToKeypress(fig, event), ...
                'WindowScrollWheelFcn', @(fig, event)self.respondToScrolling(fig, event));
        end
        
        % Figure ResizeFcn for subclasses to redefine
        function repondToResize(self, figure, event)
            % no-op for subclass to override
        end
        
        % Figure WindowKeyPressFcn for subclasses to redefine
        function respondToKeypress(self, figure, event)
            % no-op for subclass to override
        end
        
        % Figure WindowScrollWheelFcn to deal out scroll events
        % the gui's scrollables array contains handles to graphical
        % children and a callback for each.  When the mouse wheel is
        % scrolled and the cursor is insode one of the "scrollable"
        % object's Position, passes the scroll event to the object's
        % callback.
        function respondToScrolling(self, figure, event)
            % determine which scrollable gets the scroll
            if isempty(self.scrollables)
                return
            elseif length(self.scrollables) == 1
                obj = self.scrollables.handle;
                fcn = self.scrollables.fcn;
            else
                mouse = get(self.figure, 'CurrentPoint');
                posCell = get([self.scrollables.handle], 'Position');
                p = vertcat(posCell{:});
                hit = mouse(1) >= p(:,1) ...
                    & mouse(2) >= p(:,2) ...
                    & mouse(1) <= p(:,1)+p(:,3) ...
                    & mouse(2) <= p(:,2)+p(:,4);
                if any(hit)
                    ii = find(hit, 1);
                    obj = self.scrollables(ii).handle;
                    fcn = self.scrollables(ii).fcn;
                else
                    return
                end
            end
            
            % pass the scroll event to the scrollable
            if iscell(fcn)
                if length(fcn) > 1
                    feval(fcn{1}, obj, event, fcn{2:end});
                else
                    feval(fcn{1}, obj, event);
                end
            else
                feval(fcn, obj, event);
            end
        end
        
        % Add a "scrollable" graphical child and a callback to the
        % scrollables struct.
        function addScrollableChild(self, child, scrollFcn)
            s.handle = child;
            s.fcn = scrollFcn;
            if isempty(self.scrollables)
                self.scrollables = s;
            else
                self.scrollables(end+1) = s;
            end
        end
        
        % Subclass may redefine their title, which is passed to the figure
        function set.title(self, title)
            self.title = title;
            set(self.figure, 'Name', title);
        end
        
        % Toggling isBusy, shows a message in the figure title bar
        function set.isBusy(self, isBusy)
            self.isBusy = isBusy;
            if isBusy
                set(self.figure, 'Name', self.busyTitle);
            else
                set(self.figure, 'Name', self.title);
            end
            drawnow;
        end
        
        % Subclasses can color in string variables using standard colors
        % @param string a string that should be colored in
        % @details
        % Computes the "sum" of the string and uses it as an index into the
        % standard color map.  Returns the color from the color map.
        % <br><br>
        % The idea is that strings should pop out visually, and identical
        % strings should pop out together and be memorable from gui to gui.
        function col = getColorForString(self, string)
            hash = 1 + mod(sum(string), size(self.colors,1));
            col = self.colors(hash, :);
        end
        
        % Subclasses can present standard controls to represent values
        % @param value any value or object to be represented with a
        % uicontrol
        % @details
        % Returns a list of standard arguments to represent @a value.
        % The arguments will reflect the type of @a value.  For
        % example, strings get colored in using getColorForString().  Other
        % values get summarized as black strings.
        function args = getDescriptiveUIControlArgsForValue(self, value)
            if ischar(value)
                col = self.getColorForString(value);
                bg = self.lightColor;
            else
                col = [0 0 0];
                bg = get(self.figure, 'Color');
            end
            args = { ...
                'Style', 'text', ...
                'String', stringifyValue(value), ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', bg, ...
                'ForegroundColor', col};
        end
        
        % Subclasses can present standard controls to interact with values
        % @param value any value or object to be interacted with, with a
        % uicontrol
        % @details
        % Returns a list of standard arguments to represent and interact
        % with @a value.  The arguments will reflect the type of
        % @a value.  For example, strings get colored in using
        % getColorForString().  Strings and function handles match files on
        % Matlab's path become clickable links for opening the file in
        % Matlab.  Instances of tops foundation classes also become bold,
        % clickable links, to other topsGUI subclasses.
        % <br><br>
        % If there's no good way to ineract with @a value, returns
        % the same arguments as getDescriptiveUIControlArgsForValue.
        function args = getInteractiveUIControlArgsForValue(self, value)
            args = self.getDescriptiveUIControlArgsForValue(value);
            
            if isscalar(value) && any(strcmp(methods(value), 'gui'))
                % open up one of the topsFoundataion guis
                callback = @(obj,event) value.gui;
                
            elseif isscalar(value) && isa(value, 'function_handle')
                % open a funciton's m-file
                name = func2str(value);
                if exist(name, 'file') || exist([name, '.m'], 'file')
                    callback = @(obj,event) open(name);
                else
                    return
                end
                
            elseif ischar(value) && ~isempty(which(value))
                % open up the m-file
                callback = @(obj,event) open(value);
                
            else
                % fallback on descripive uicontrol
                return
            end
            
            % 'inactive' mode actually enables the ButtonDownFcn
            moreArgs = { ...
                'FontWeight', 'bold', ...
                'ButtonDownFcn', callback, ...
                'Enable', 'inactive'};
            args = cat(2, args, moreArgs);
        end
    end
end