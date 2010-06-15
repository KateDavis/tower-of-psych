classdef topsGroupedListGUI < topsGUI
    % @class topsGroupedListGUI
    % Visualize the items stored in a grouped list.
    % topsGroupedListGUI shows you a three-column view of a
    % topsGroupedList (or subclass).
    % @details
    % The left column shows all the groups in the list.  The middle column
    % shows all the mnemonics in the currently selected group.  The right
    % column shows details for the item that has the currently selected
    % mnemonic.
    % @details
    % Simple items like numbers and strings are shown by their value.
    % Strings are color-coded with a color scheme that's standard for Tower
    % of Psych GUIS.
    % @details
    % Complex items like cell arrays, structs, and objects are expanded
    % into multiple rows that show their elements, fields, and properties.
    % Field and property names and are left-aligned and their values are
    % right-aligned on the next row.  Again strings, including field and
    % property names, are color-codded.
    % @details
    % Struct arrays and object arrays are expanded even further, with a
    % group of rows for each element of the array.  In this case rows may
    % extend beneath the visible part of the column and a slider bar will
    % appear to bring these rows into view.
    % @details
    % Some items, elements, field values, and property values will appear
    % in bold:
    %   - strings or function handles that can be found on Matlab's path
    %   can be clicked to open them in Matlab's m-file editor.
    %   - instances of Towe of Psych foundation classes can be clicked to
    %   open their respective Towe of Psych GUIs.
    %   .
    % The "to workspace" button in the top right corner of the GUI lets you
    % send the currently displayed item to Matlab's base workspace (i.e.
    % the Command Window).  If the menmonic for the current item is a valid
    % variable name, the GUI will create or overwrite a variable with that
    % name.  Otherwise, the GUI will create or overwrite a variable with
    % the name "item".
    % @details
    % You can launch topsGroupedListGUI with the topsGroupedListGUI()
    % constructor, or with the gui() method a topsGroupedList or subclass.
    % @details
    % topsGroupedListGUI uses listeners to detect changes to the list its
    % showing.  This means that you can view a list as you work on your
    % experiment, and you don't have to reopen or refresh the GUI.
    % @details
    % Beware that listeners can slow Matlab down.  So if you're in a
    % timing-critical situation, like some experiments, you might wish to
    % close the GUI, deleting its listeners.
    % @ingroup foundation
    
    properties
        % topsGroupedList to interact with
        groupedList;
        
        % topsGroupedListPanel that contains most of the GUI components
        listPanel;
    end
    
    properties (Hidden)
        % normalized [x y w h] where to locate listPanel
        listPanelPosition = [0 0 1 1];
    end
    
    methods
        % Constructor takes one optional argument
        % @param groupedList a list to visualize
        % @details
        % Returns a handle to the new topsGroupedListGUI.  If
        % @a groupedList is missing, the GUI will launch but no
        % data will be shown.
        function self = topsGroupedListGUI(groupedList)
            self = self@topsGUI;
            self.title = 'Grouped List Viewer';
            
            self.listPanel = topsGroupedListPanel(...
                self, self.listPanelPosition);
            
            if nargin
                self.groupedList = groupedList;
                self.listPanel.populateWithGroupedList(groupedList);
            end
        end
        
        % Delegate resizing behavior to listPanel.
        function repondToResize(self, figure, event)
            self.listPanel.repondToResize(figure, event);
        end
    end
end