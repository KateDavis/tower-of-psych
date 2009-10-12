classdef topsGUI < handle
    properties (SetObservable)
        figure;
        title = 'tops GUI';
        isBusy = false;
    end
    
    properties(Hidden)
        busyTitle = '(busy...)';
        colors;
        listeners = struct();
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
            delete(struct2array(self.listeners));
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
                'ToolBar', 'none');
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