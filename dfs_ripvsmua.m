%% Sungod manu: calculate fraction of mua events that overlap with rip events, and vv

animals = {'jaq','roquefort','despereaux','montague'};  %,, 'remy',};%};

epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0 & $gooddecode==1']; % & $decode_error<=1
%epochfilter{1} = ['$session==27'];

% resultant excludeperiods will define times when velocity is high
timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
iterator = 'epochbehaveanal';

f = createfilter('animal',animals,'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
f = setfilterfunction(f, 'dfa_ripvsmua', {'ripdecodesv3','muadecodesv3','trials','pos'},'window',.02);
f = runfilter(f);

animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols

%% plot the mean overlap frac across sessions
figure;
for a = 1:length(animals)
    muafrac{a} = cell2mat(arrayfun(@(x) x.fracmua_withoverlap,f(a).output{1},'UniformOutput',0))';
    ripfrac{a} = cell2mat(arrayfun(@(x) x.fracrips_withoverlap,f(a).output{1},'UniformOutput',0))';
    
    numev{a} = cell2mat(arrayfun(@(x) x.numrip_mua',f(a).output{1},'UniformOutput',0))';
end
subplot(1,3,1); plot4a(numev,'gnames',{'rips','mua'}); title('event numbers'); ylim([0 2500])
subplot(1,3,2); plot4a(muafrac); ylim([0 1]); title('%mua with overlap')
subplot(1,3,3); plot4a(ripfrac); ylim([0 1]); title('%rips with overlap')


%%