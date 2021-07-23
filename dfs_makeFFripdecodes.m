%% Generate filterframework format summaries of posteriors during rip times ("ripdecodes")

animals = {'montague'}; %'gus','bernard','fievel',  'jaq','roquefort','despereaux',


    epochfilter{1} = ['$session>=0 & (isequal($environment,''goal''))'];% | isequal($environment,''goal_nodelay'')


    % resultant excludeperiods will define times when velocity is high
    timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
    iterator = 'epochbehaveanal';
    
for a = 1:length(animals)
    
    f(a) = createfilter('animal',animals{a},'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
    f(a) = setfilterfunction(f(a), 'dfa_makeFFripdecodes', {'ca1rippleskons'},'animal',animals{a},'version','v2');  % ca1ripplsekonslow
    %f(a) = setfilterfunction(f(a), 'dfa_makeFFmuadecodes', {'muaripples'},'animal',animals{a},'version','v3');  % 
    %f(a) = setfilterfunction(f(a), 'dfa_makeFFlikdecodes', {'ca1rippleskons'},'animal',animals{a},'version','v2');  % 
    f(a) = runfilter(f(a));

end

%%








