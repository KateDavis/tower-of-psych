%% should behave as singleton
clear
clc
log1 = topsDataLog.theDataLog;
log2 = topsDataLog.theDataLog;
assert(isequal(log1, log2), 'log is not a singleton');


%% should store data with mnemonics and account for them
clear
clc
theLog = topsDataLog.theDataLog;
theLog.flushAllData;

% log each datum with each mnemonic
%   redundant data would not be normal
mnemonics = {'animals', 'pizzas', 'phone books'};
data = {1, {'elephant', 'sauce'}, []};
for m = mnemonics
    for d = data
        theLog.logMnemonicWithData(m{1}, d{1});
    end
end
assert(theLog.count == (length(mnemonics)*length(data)), 'failed to count log entries')

gotMnemnics = theLog.getAllMnemonics;
assert(isequal(sort(gotMnemnics), sort(mnemonics)), 'failed to account for unique mnemonics')


%% should flush all data
clear
clc
theLog = topsDataLog.theDataLog;
theLog.flushAllData;
assert(theLog.count == 0, 'failed to get log with 0 entries')
assert(isempty(theLog.getAllMnemonics), 'failed to get log with no mnemonics')

% log each datum with each mnemonic
%   redundant data would not be normal
mnemonics = {'animals', 'pizzas', 'phone books'};
data = {1, {'elephant', 'sauce'}, []};
for m = mnemonics
    for d = data
        theLog.logMnemonicWithData(m{1}, d{1});
    end
end

theLog.flushAllData;
assert(theLog.count == 0, 'failed to clear log entries after adding')
assert(isempty(theLog.getAllMnemonics), 'failed to clear log mnemonics after adding')



%% should return data by mnemonic or all at once
clear
clc
theLog = topsDataLog.theDataLog;
theLog.flushAllData;

% log each datum with each mnemonic
%   redundant data would not be normal
mnemonics = {'animals', 'pizzas', 'phone books'};
data = {1, {'elephant', 'sauce'}, []};
for m = mnemonics
    for d = data
        theLog.logMnemonicWithData(m{1}, d{1});
    end
end

for m = mnemonics
    dataStruct = theLog.getDataForMnemonic(m{1});
    gotData = {dataStruct.data};
    for d = data
        count = 0;
        for gd = gotData
            count = count + isequal(gd, d);
        end
        assert(count == 1, 'failed to retrieve get exactly one of each datum')
    end
    
    gotMnemonics = {dataStruct.mnemonic};
    assert(all(strcmp(gotMnemonics, m{1})), 'got wrong mnemonic')
end


%% should return data all at once, sorted
clear
clc
theLog = topsDataLog.theDataLog;
theLog.flushAllData;

% log each datum with each mnemonic
%   redundant data would not be normal
mnemonics = {'animals', 'pizzas', 'phone books'};
data = {1, {'elephant', 'sauce'}, []};
for m = mnemonics
    for d = data
        theLog.logMnemonicWithData(m{1}, d{1});
    end
end

allStruct = theLog.getAllDataSorted;
gotAllMnemonics = {allStruct.mnemonic};
for m = mnemonics
    assert(sum(strcmp(m{1}, gotAllMnemonics))==length(data), 'wrong number of mnemonics in grand data struct')
end

gotAllData = {allStruct.data};
for d = data
    count = 0;
    for gd = gotAllData
        count = count + isequal(gd, d);
    end
    assert(count == length(mnemonics), 'wrong number of unique data in grand data struct')
end

gotAllTimes = [allStruct.time];
assert(all(diff(gotAllTimes) >=0), 'all data not sorted by time')