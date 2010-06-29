classdef topsGUI < handle
    % @class topsGUI
    % Superclass for Tower of Psych graphical interfaces.
    % You shouldn't need to work with this class unless you're developing a
    % new graphical interface.  If that's what you're doing, you may wish
    % to write a sublcass of topsGUI to take advantage of its features,
    % which are described here briefly.
    % @ingroup foundation
    
    properties(Hidden)
        % Matlab figure that holds the gui
        figure;
        
        % true or false, toggled to indicate when gui is busy
        isBusy = false;
        
        % default title for the gui
        title = 'tops GUI';
        
        % title to show when isBusy
        busyTitle = '(busy...)';
        
        % colormap of colors visible against white, to give subclasses
        % uniform appearance
        colors;

        % an offwhite color used by all subclasses
        lightColor = [1 1 .98];
        
        % struct array of listener objects used by subclass, automatically
        % deleted
        listeners = struct();
        
        % struct array of graphical children to receive mouse scroll
        % events
        % @details
        % Use addScrollableChild() to append elements to scrollables.
        scrollables;
        
        % array of handles to pushbutton uicontrol objects
        % @details
        % Use addButton() to append elements to buttons.
        buttons;
        
        % length in characters of strings that summarize values displayed
        % in the gui
        stringSummaryLength = 22;
    end
    
    properties(Hidden)
        % a small value, but not Matlab's eps()
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
        
        % Automatically closes the figure and deletes any listeners used by
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
        
        % Keep track of listeners by index and name.
        function ii = addListenerWithName(self, listener, name)
            if isfield(self.listeners, name)
                ii = length(self.listeners.(name)) + 1;
                self.listeners.(name)(ii) = listener;

            else
                ii = 1;
                self.listeners.(name) = listener;
            end
        end
        
        % Delete a listener by name and index.
        function ii = deleteListenerWithNameAndIndex(self, name, ii)
            if isfield(self.listeners, name)
                if ii <= length(self.listeners.(name))
                    delete(self.listeners.(name)(ii));
                    self.listeners.(name)(ii) = [];
                end
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
            self.scrollables = [];
            self.buttons = [];
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
        % scrolled and the current object is a scrollable or a child of a
        % scrollable, passes the scroll event to the scrollable's callback.
        function respondToScrolling(self, figure, event)
            % determine which scrollable gets the scroll
            if isempty(self.scrollables)
                return
            elseif length(self.scrollables) == 1
                obj = self.scrollables(1).handle;
                fcn = self.scrollables(1).fcn;
            else
                current = get(self.figure, 'CurrentObject');
                if isempty(current)
                    return
                    
                else
                    scrolls = [self.scrollables.handle];
                    while true
                        isScroll = current == scrolls;
                        if any(isScroll)
                            ii = find(isScroll, 1);
                            obj = self.scrollables(ii).handle;
                            fcn = self.scrollables(ii).fcn;
                            break;
                            
                        elseif current == self.figure
                            return
                            
                        end
                        current = get(current, 'Parent');
                    end
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
        
        % Add a child to receive mouse scroll events.
        % @param child a graphical child that may receive mouse scroll
        % events
        % @param scrollFcn the callback that should handle mouse scroll
        % events, should expect @a child and a Matlab event as the first
        % two arguments.
        % @details
        % topsGUI objects receive mouse scroll events from Matlab at the
        % figure level.  When @a child or one of its parents is the
        % figure's CurrentObject, this topsGUI will invoke the
        % corresponding @a scrollFcn.
        % @details
        % It's a pain that Matlab only updates CurrentObject after a mouse
        % click.  It's also a pain that Matlab makes it hard/slow to get
        % the pixel positions of graphical children (esp. in batches),
        % which makes CurrentPoint a lot less useful.
        function addScrollableChild(self, child, scrollFcn)
            s.handle = child;
            s.fcn = scrollFcn;
            if isempty(self.scrollables)
                self.scrollables = s;
            else
                self.scrollables(end+1) = s;
            end
        end
        
        % Add a button with given position and callback.
        % @param position normalized [x y w h] where to place the new
        % button within this gui's figure.
        % @param name string name to show on the new button
        % @param callback to invoke when the button is pressed, should
        % expect a handle to the button and a Matlab event as the first
        % two arguments.
        % @details
        % Returns the handle to a new uicontrol pushbutton object which has
        % this topsGUI's figure as its parent.
        function b = addButton(self, position, name, callback)
            b = uicontrol( ...
                'Parent', self.figure, ...
                'Callback', callback, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'String', name, ...
                'Position', position, ...
                'HorizontalAlignment', 'center');
            self.buttons(end+1) = b;
        end
        
        % Subclass may redefine their title, which is passed to the figure
        function set.title(self, title)
            self.title = title;
            set(self.figure, 'Name', title);
        end
        
        % Toggling isBusy shows a message in the figure title bar
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
        % @details
        % The idea is that strings should pop out visually, and identical
        % strings should pop out together and be memorable from gui to gui.
        function col = getColorForString(self, string)
            hash = 1 + mod(sum(string), size(self.colors,1));
            col = self.colors(hash, :);
        end
        
        % Subclasses can use a standard look and feel to reflect values
        % @param value any value or object to be represented with a
        % uicontrol
        % @details
        % Returns a list of standard "look and feel" arguments for GUI
        % controls, some of which may depend on the type and value of @a
        % value.
        function args = getLookAndFeelForValue(self, value)
            if ischar(value)
                col = self.getColorForString(value);
                bg = self.lightColor;
            else
                col = [0 0 0];
                bg = get(self.figure, 'Color');
            end
            string = summarizeValue(value, self.stringSummaryLength);
            args = { ...
                'ForegroundColor', col, ...
                'BackgroundColor', bg, ...
                'String', string};
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
            static = topsText.staticText;
            lookFeel = self.getLookAndFeelForValue(value);
            args = cat(2, static, lookFeel);
        end
        
        % Subclasses can present standard controls to interact with values
        % @param value any value or object to be interacted with, with a
        % uicontrol
        % @details
        % Returns a list of standard arguments to represent and interact
        % with @a value.  Strings and function handles match files on
        % Matlab's path become clickable links for opening the file in
        % Matlab.  Objects with a gui() method, including topsFoundataion
        % objects, also become bold links for launching object guis.
        % @details
        % If there's no good way to ineract with @a value, returns
        % the same arguments as getDescriptiveUIControlArgsForValue.
        function args = getInteractiveUIControlArgsForValue(self, value)
            callback = [];
            if isscalar(value) && any(strcmp(methods(value), 'gui'))
                % open up one of the topsFoundataion guis
                callback = @(obj,event) value.gui;
                
            elseif isscalar(value) && isa(value, 'function_handle')
                % open a funciton's m-file
                mName = [func2str(value), '.m'];
                if exist(mName, 'file')
                    callback = @(obj,event) open(mName);
                end
                
            elseif ischar(value)
                % open up an m-file
                mName = [value, '.m'];
                if exist(mName, 'file')
                    callback = @(obj,event) open(mName);
                end

            end
            
            if isempty(callback)
                % fallback on non-interactive control
                args = self.getDescriptiveUIControlArgsForValue(value);
                
            else
                click = topsText.clickTextWithCallback(callback);
                lookFeel = self.getLookAndFeelForValue(value);
                args = cat(2, click, lookFeel);
            end
        end
        
        % Subclasses can present standard controls for editing values
        % @param getter fevalable cell array to invoke that returns the
        % value to be displayed
        % @param setter fevalable cell array to invoke to set a new value
        % from user input (should expect the new value as the first
        % argument).
        % @details
        % Returns a list of standard arguments to represent and allow
        % editing of a value.  The value displayed will reflect the return
        % value of the @a getter fevalable.
        % @details
        % The user may click inside the control to type a new string, which
        % will be passed to Matlab's built-in eval() function.  The
        % eval() result wil be passed to the @a setter function to update
        % the value.
        % @details
        % The control will not attempt to validate user inputs.  It will
        % attempt to catch errors and display them, and only invoke the @a
        % setter upon success.
        function args = getEditableUIControlArgsWithGetterAndSetter(self, getter, setter)
            editable = topsText.editTextWithGetterAndSetter(getter, setter);
            lookFeel = self.getLookAndFeelForValue(feval(getter{:}));
            args = cat(2, editable, lookFeel);
        end
    end
end