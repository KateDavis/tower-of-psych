classdef topsGUI < handle
    % @class topsGUI
    % Superclass for Tower of Psych graphical interfaces.
    % You shouldn't need to work with this class unless you're developing a
    % new graphical interface.  If that's what you're doing, you may wish
    % to write a sublcass of topsGUI to take advantage of its features,
    % which are described here briefly.
    % @ingroup foundation
    
    properties
        % Matlab figure that holds the gui
        figure;
        
        % true or false, toggled to indicate when gui is busy
        isBusy = false;
        
        % title for the gui figure
        title = 'topsGUI';
    end
    
    properties (Hidden)
        % title to show when isBusy
        busyTitle = '(busy...)';
        
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
    end
    
    methods
        % Constructor takes no arguments.
        % Opens a figure with a standard appearance.
        function self = topsGUI
            self.setupFigure;
        end
        
        % Automatically closes the figure and deletes any listeners used by
        % a subclass or topsDetailPanel.
        function delete(self)
            if ~isempty(self.figure) && ishandle(self.figure);
                delete(self.figure);
                self.figure = [];
            end
            self.deleteListeners;
        end
        
        % Delete this topsGUI object when its figure closes.
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
        
        % Un-register to receive notifications from displayed objects.
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
                'Renderer', 'painters', ...
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
            if isempty(self.scrollables)
                return
            end
            
            n = length(self.scrollables);
            current = get(self.figure, 'CurrentObject');
            if n == 1 || isempty(current)
                % pick last scrollable, when it's obvious
                self.eventToScrollableAtIndex(event, n);
                
            else
                % work up in parents from the last-clicked object
                scrolls = [self.scrollables.handle];
                while true
                    isScroll = current == scrolls;
                    if any(isScroll)
                        ii = find(isScroll, 1);
                        didScroll = ...
                            self.eventToScrollableAtIndex(event, ii);
                        if ~didScroll
                            break;
                        end
                        
                    elseif current == self.figure
                        break;
                        
                    end
                    current = get(current, 'Parent');
                end
                
                % fall back on any scrollable, in the order added
                for ii = 1:length(self.scrollables)
                    didScroll = self.eventToScrollableAtIndex(event, ii);
                    if didScroll
                        break;
                    end
                end
            end
        end
        
        % Pass a mouse wheel scroll event to a registered object.
        function didScroll = eventToScrollableAtIndex(self, event, ii)
            obj = self.scrollables(ii).handle;
            fcn = self.scrollables(ii).fcn;
            if iscell(fcn)
                if length(fcn) > 1
                    didScroll = feval(fcn{1}, obj, event, fcn{2:end});
                else
                    didScroll = feval(fcn{1}, obj, event);
                end
            else
                didScroll = feval(fcn, obj, event);
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

        % Remove a child so it no longer receives mouse scroll events.
        % @param child a graphical child that was added with
        % addScrollableChild()
        function removeScrollableChild(self, child)
            scrollableHandles = [self.scrollables.handle];
            self.scrollables(scrollableHandles == child) = [];
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
        
        % Subclass may redefine their title, which is passed to the figure.
        function set.title(self, title)
            self.title = title;
            set(self.figure, 'Name', title);
        end
        
        % Shows a message in the figure title bar when busy.
        function set.isBusy(self, isBusy)
            self.isBusy = isBusy;
            if isBusy
                set(self.figure, 'Name', self.busyTitle);
            else
                set(self.figure, 'Name', self.title);
            end
            drawnow;
        end
    end
end