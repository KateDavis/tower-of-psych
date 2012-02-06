function dispSandbox

close all
fig = figure();
je = javax.swing.JEditorPane('text/html', '');
je.setEditable(false);
jp = javax.swing.JScrollPane(je);
[hcomponent, hcontainer] = javacomponent(jp, [], fig);
set(hcontainer, ...
    'Units', 'normalized', ...
    'Position', [0 0 .25 .5]);

u = uicontrol( ...
    'Style', 'edit', ...
    'Max', 100, ...
    'Units', 'normalized', ...
    'Position', [.5 0 .4 1], ...
    'String', '');

types = { ...
    1:10, ...
    'bean suppers', ...
    [false true], ...
    num2cell(1:10), ...
    struct('alpha', 'a', 'beta', 2, 'cheese', cell(1,2)), ...
    containers.Map, ...
    topsRunnable(), ...
    topsFoundation()};

nTypes = numel(types);
infos = cell(1, nTypes);
for ii = 1:nTypes
    item = types{ii};
    
    %infos{ii} = evalc('disp(item)');
    
    if ischar(item)
        infoString = colorInQuotes(sprintf('''%s''', item));
    else
        info = evalc('disp(item)');
        super = colorInQuotes(stripAnchors(info));
        infoString = super;
    end
    infos{ii} = sprintf('%s\n%s', class(item), infoString);
    
    myHtml = sprintf('<HTML>%s</HTML>', breakAtNewLine(infos{ii}));
    je.setText(myHtml);
    set(u, 'String', infos{ii})
    
    waitforbuttonpress();
end


function sStripped = stripAnchors(s)
anchorPat = '(<[Aa][^<]*>[^<]*</[Aa]>[,\n]*)';
sStripped = regexprep(s, anchorPat, '');

function sColored = colorInQuotes(s)
%s = 'what I will be eating is ''cheese'' and a ''pile'' of veg, today';

c = [.7 .4 0];
cHex = deblank(dec2hex(round(c*255), 2))';
cHexRow = cHex(:)';

htmlFront = sprintf('<FONT color="%s">', cHexRow);
htmlBack = '</FONT>';
htmlReplacer = sprintf('%s''$1''%s', htmlFront, htmlBack);

quotePat = '''([^'']+)''';
sColored = regexprep(s, quotePat, htmlReplacer);

function sBroken = breakAtNewLine(s)
newLinePat = '(\n)';
s
sBroken = regexprep(s, newLinePat, '<br/>')