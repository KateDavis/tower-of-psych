classdef topsGUI < handle
    
    properties(Hidden)
        figure;
        title = 'tops GUI';
        busyTitle = '(busy...)';
        isBusy = false;
        colors;
        listeners = struct();
        biggerThanEps = 1e-6;
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
            % switchyard for scrollable widgets owned in subclass
            %   self.scrollableHandles and self.scrollCallbacks
            % get all handle Positions, vertat X,Y,W,H
            % get current point x,y
            % find any X<x & Y<y & x<X+W & y<Y+H
            % execute first correspond callback(handle, event)
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