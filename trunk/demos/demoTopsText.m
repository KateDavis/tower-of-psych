close all
clear
clear classes

lookFeel = { ...
    'Units', 'normalized', ...
    'BackgroundColor', [1 1 1], ...
    'ForegroundColor', [.9 .5 .1], ...
    'FontWeight', 'bold', ...
    'Callback', @(obj, event)disp(get(obj, 'String'))};

args = topsText.staticText;
more = { ...
    'String', 'static', ...
    'Position', subposition([0 0 1 1], 10, 3, 1, 2), ...
    };
static = uicontrol(args{:}, lookFeel{:}, more{:});

args = topsText.clickText;
more = { ...
    'String', 'click', ...
    'Position', subposition([0 0 1 1], 10, 3, 3, 2), ...
    };
click = uicontrol(args{:}, lookFeel{:}, more{:});

args = topsText.toggleText;
more = { ...
    'String', 'toggle', ...
    'Position', subposition([0 0 1 1], 10, 3, 5, 2), ...
    };
toggle = uicontrol(args{:}, lookFeel{:}, more{:});

args = topsText.editText;
more = { ...
    'String', 'edit', ...
    'Position', subposition([0 0 1 1], 10, 3, 7, 2), ...
    };
editable = uicontrol(args{:}, lookFeel{:}, more{:});

object = EventWithData;
object.userData.a{4} = 'get and set';
subs = substruct('.', 'userData', '.', 'a', '{}', {4});

getter = {@subsref, object, subs};
setFunction = @(value, object, subs)subsasgn(object, subs, value);
setter = {setFunction, object, subs};

args = topsText.editTextWithGetterAndSetter(getter, setter);
more = { ...
    'Position', subposition([0 0 1 1], 10, 3, 9, 2), ...
    'Callback', @(obj, event)disp(feval(getter{:})), ...
    };
bound = uicontrol(args{:}, lookFeel{:}, more{:});