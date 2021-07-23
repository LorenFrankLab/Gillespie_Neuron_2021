%% Save instfreq and spikes/tet for each rip
%for later use in dfs_ripcontent

animals = {'jaq','roquefort','despereaux','montague'};  %
%epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0 & $session==6']; % & $decode_error<=1
epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0 & $gooddecode==1']; % & $decode_error<=1
tetfilter = 'isequal($area,''ca1'')';

% resultant excludeperiods will define times when velocity is high
timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
iterator = 'epocheeganal';
f = createfilter('animal',animals,'epochs',epochfilter,'excludetime', timefilter, 'eegtetrodes',tetfilter,'iterator', iterator);

% tet-by-tet measures (instfreq, marks) use one iterator
f = setfilterfunction(f, 'dfa_ripfeatures_bytet', {'ripple','ripdecodesv3','marks'});

% remove chronux from path temporarily to access signal/findpeaks not the chronux one
rmpath('~/Src/Matlab/chronux/spectral_analysis/continuous/')
f = runfilter(f);
addpath('~/Src/Matlab/chronux/spectral_analysis/continuous/')

%save('/media/anna/whirlwindtemp2/ffresults/ctrl_instfreq_raw.mat','f','-v7.3')

%% reorganize, collapse across tets, save output

for a = 1:length(animals)
    det = cell2mat(arrayfun(@(x) x.index',f(a).output{1},'UniformOutput',0))';
    riptsz = arrayfun(@(x) x.riptsz,f(a).output{1},'UniformOutput',0);% stack data from all trials
    for d = unique(det(:,1))'
        for e = unique(det(det(:,1)==d,2))'
            inds = find(det(:,1) == d & det(:,2) == e);
            if all(~cellfun(@isempty,riptsz(inds))) % if there were decoded rips
                riptimes{d}{e} = riptsz{inds(1)}(:,1);
                instfreqs{d}{e} = cell2mat(cellfun(@(x) x(:,2),riptsz(inds),'un',0));
                meaninstfreq{d}{e} = mean(instfreqs{d}{e},2);
                spikenums{d}{e} = cell2mat(cellfun(@(x) x(:,3),riptsz(inds),'un',0));
                totalspikenum{d}{e} = sum(spikenums{d}{e},2);
                tetsactive{d}{e} = sum(spikenums{d}{e}>0,2);
                totaltets{d}{e} = length(inds);
            end
        end
    end
    out{a}.ripstarttimes = riptimes;
    out{a}.instfreq = meaninstfreq;
    out{a}.spikenum = totalspikenum;
    out{a}.tetnum = tetsactive;
    out{a}.totaltetnum = totaltets;
    clear riptimes instfreqs meaninstfreq spikenums totalspikenum tetsactive totaltets
end
%save('/media/anna/whirlwindtemp2/ffresults/ctrl_instfreqspikes.mat','out','-v7.3')

