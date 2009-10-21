classdef topsGUI < handle
    
    properties(Hidden)
        figure;
        title = 'tops GUI';
        busyTitle = '(busy...)';
        isBusy = false;
        colors;
        listeners = struct();
        scrollables;
        biggerThanEps = 1e-6;
        lightColor = [1 1 1]*.95;
    end
    
    methods
        function self = topsGUI
            self.colors = spacedColors(61);
            self.setupFigure;
        end
        
        function delete(self)
            if ~isempty(self.figure) && ishandle(self.figure);
                delete(self.figure);
                self.figure = [];
            end
            self.deleteListeners;
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
        
        function figureClose(self)
            if isvalid(self)
                delete(self)
            end
        end
        
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
        
        function repondToResize(self, figure, event)
            % no-op for subclass to override
        end
        
        function respondToKeypress(self, figure, event)
            % no-op for subclass to override
        end
        
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
        
        function addScrollableChild(self, child, scrollFcn)
            s.handle = child;
            s.fcn = scrollFcn;
            if isempty(self.scrollables)
                self.scrollables = s;
            else
                self.scrollables(end+1) = s;
            end
        end
        
        function set.title(self, title)
            self.title = title;
            set(self.figure, 'Name', title);
        end
        
        function set.isBusy(self, isBusy)
            self.isBusy = isBusy;
            if isBusy
                set(self.figure, 'Name', self.busyTitle);
            else
                set(self.figure, 'Name', self.title);
            end
            drawnow;
        end
        
        function col = getColorForString(self, string)
            hash = 1 + mod(sum(string), size(self.colors,1));
            col = self.colors(hash, :);
        end
    end
end