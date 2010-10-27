% Demonstrate some flavors of the text widgets that Tower of Psych uses.
close all
clear
clear classes

% First, define some attributes for use in this demo.  Since topsText is
% based on the Matlab built-in uicontrol class, these must be valid
% uicontrol property names and values.
lookFeel = { ...
    'Units', 'normalized', ...
    'BackgroundColor', [1 1 1], ...
    'ForegroundColor', [.9 .5 .1], ...
    'FontWeight', 'bold', ...
    'Callback', @(obj, event)disp(get(obj, 'String'))};

% Use the topsText class to get additional attributes for a topsText-style
% static text uicontrol object.  Combine the arguments and create a
% topsText-style uicontrol object in a new figure.
args = topsText.staticText;
more = { ...
    'String', 'static', ...
    'Position', subposition([0 0 1 1], 10, 3, 1, 2), ...
    };
static = uicontrol(args{:}, lookFeel{:}, more{:});

% Similarly, create a topsText-style clickable text uicontrol object--like
% a button, but with a special topsText appearance.
args = topsText.clickText;
more = { ...
    'String', 'click', ...
    'Position', subposition([0 0 1 1], 10, 3, 3, 2), ...
    };
click = uicontrol(args{:}, lookFeel{:}, more{:});

% Create a topsText-style togglable text uicontrol object--like
% a toggle button, but with a special topsText appearance.
args = topsText.toggleText;
more = { ...
    'String', 'toggle', ...
    'Position', subposition([0 0 1 1], 10, 3, 5, 2), ...
    };
toggle = uicontrol(args{:}, lookFeel{:}, more{:});

% Create a topsText-style editable text uicontrol object--like
% a text edit field, but with a special topsText appearance.
%
% This style of editable text will only allow the user to edit the text
% value that appears in the widget.
args = topsText.editText;
more = { ...
    'String', 'edit', ...
    'Position', subposition([0 0 1 1], 10, 3, 7, 2), ...
    };
editable = uicontrol(args{:}, lookFeel{:}, more{:});

% Even better, create a topsText-style editable text uicontrol object which
% allows value that appears in the widget to be bound to a property of
% another object!

% create an object to work with and set a value, nested deep in its
% userData property.  Also define the "subs" path that digs into the nest.
object = EventWithData;
object.userData.a{4} = 'get and set';
subs = substruct('.', 'userData', '.', 'a', '{}', {4});

% define set and get functions that will bind the object property to the
% text widget.  The getter passes values from the object property to the
% text widget.  The setter passes user input values from the text widget to
% the object property.
getter = {@subsref, object, subs};
setFunction = @(value, object, subs)subsasgn(object, subs, value);
setter = {setFunction, object, subs};

% create the object-bound text widget with the getter and setter
args = topsText.editTextWithGetterAndSetter(getter, setter);
more = { ...
    'Position', subposition([0 0 1 1], 10, 3, 9, 2), ...
    'Callback', @(obj, event)disp(feval(getter{:})), ...
    };
bound = uicontrol(args{:}, lookFeel{:}, more{:});

% note that editing the value in this bound widget will alter the value of
% object.userData.  Check it out on the command line!
disp(object.userData)