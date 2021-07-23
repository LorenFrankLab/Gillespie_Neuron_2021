function out = dfa_makeFFripdecodes(index, excludeperiods, rips, varargin)

%  Load full  posterior from animal/decoding
%  For each immo ripple, calculate useful summaries of the decode
%  Save in animalripdecodes04.mat {day}{ep} with one entry per ripple
%  outputs:

%  times: 1xtimebins (in ms posterior ts)
%  post_curves: 3xtimebins
%  CIcount: 1xtimebins (#bins that comprise credible interval)
%  MAPvalue: 1xtimebins (maximum value of posterior for that timebin
%  MAPind: 1xtimebins (pos bin which contains posterior maximum for that timebin)

%  ref for entire ep:
%  armedges

% maxstate [0 1 0] for state that exceeds .8 for majority of event, no multiple tags
% frac_state [.1 .7 .2] fraction of event spent >thresh
% contentprop [.8 .2 0 0 0 0 0 0 0] mean of combined posterior across time; proportion of cumulative density in each arm
% contentbybins [10 2 0 0 0 0 0 0 0]

% note that to calculate contentprop, we sum across timetins and then sum density within each arm
% does not matter whether you sum or mean, and makes no difference mathematically which step you do first (bc each column adds to 1)

% content by bins lets you calculate the fraction of the ripple spent in remote vs local segment


%  out is a structure with the following fields
%       index-- Only if appendindex is set to 1 (default)

% define defaults
cred_int_cutoff = .95;
classifier_state_thresh = .8;
appendindex = 1;
version = 'v2';

% process varargin if present and overwrite default values
if (~isempty(varargin))
    assign(varargin{:});
end

d = index(1);
e = index(2);

animspecs = animaldef(animal);
ff_path = animspecs{2};

switch version
    case 'v2'
        postfile = sprintf('%sdecoding/%s_%d_%d_shuffle_0_posterior_acausal_v2.nc',ff_path,animal,d,e);  %
        ripfile = sprintf('%s%sripdecodesv2%02d.mat',ff_path,animal,d);
    case 'v3'
        postfile = sprintf('%sdecoding/%s_%d_%d_shuffle_0_posterior_acausalv2_full2state.nc',ff_path,animal,d,e);  %
        ripfile = sprintf('%s%sripdecodesv3%02d.mat',ff_path,animal,d);
        linposfile = sprintf('%sdecoding/%s_%d_%d_shuffle_0_linearposition_v2.nc',ff_path,animal,d,e); 
    otherwise
        postfile = sprintf('%sdecoding/%s_%d_%d_shuffle_0_posterior_acausal.nc',ff_path,animal,d,e);  %
        ripfile = sprintf('%s%sripdecodes%02d.mat',ff_path,animal,d);
end

if exist(postfile)
    
    disp(sprintf('decode results found for %s d%d e%d',animal, d, e));
    
    acausal_post(:,:,1) = ncread(postfile,'state1_posterior');
    acausal_post(:,:,2) = ncread(postfile,'state2_posterior');
    acausal_post(:,:,3) = ncread(postfile,'state3_posterior');
    posteriorts = ncread(postfile,'time');
    
    if strcmp(version,'v3')
        linpos = double(ncread(linposfile,'linpos_flat')+1);
        linposts = ncread(linposfile,'time');
    end
    
    % simplify acausal_post, calculate MAP and credible interval - faster to do this for whole ep rather than chunk by chunk (?)
    
    % classifier posterior has nancols during undecoded times and 0s in gaps between arms
    post_combined = sum(acausal_post,3);  % sum across classifier posterior to get final posterior
    % determine arm bounds
    nongap = nansum(post_combined(:,:),2)>0;
    armstarts = [1; diff(nongap)==1];
    grps=cumsum(armstarts);
    grps(~nongap)=nan;
    tmp.armedges = [find(armstarts); length(nongap)+1];
    if max(grps)<9
        warning('not all arms visited in this ep - dont use');
        out.success = 0;
    else
        % replace 0s in gaps with nans
        post_combined(~nongap,:) = nan;
        classifier_curves = squeeze(sum(acausal_post,1))';   % sum across posbins to get 1 curve per classifier state. [to work on non-classifier, would have to switch to nansum then replace nans]
        CI = credibleinterval(post_combined,cred_int_cutoff);
        [map, indofmap] = max(post_combined);  % note that indofmap for a nan is 1 (incorrect); but shouldnt matter bc never query a nantime
        
        % valid rips: occur within posterior period, and during immobility
        % quantify the posterior during rip timese (adapted from quantifyclassifier)
        
        valrips = ~isExcluded(rips{d}{e}{1}.starttime, excludeperiods) & ~isExcluded(rips{d}{e}{1}.endtime, excludeperiods) & rips{d}{e}{1}.starttime>posteriorts(1) & rips{d}{e}{1}.endtime<posteriorts(end);
        nanripcount=0;
        tmp.riptimes = [rips{d}{e}{1}.starttime(valrips), rips{d}{e}{1}.endtime(valrips)];
        tmp.ripsizes = rips{d}{e}{1}.maxthresh(valrips);
        
        % iterate through each immorip
        for r = 1:size(tmp.riptimes,1)
            postinds = posteriorts>tmp.riptimes(r,1) & posteriorts<tmp.riptimes(r,2);
            postchunk = post_combined(:,postinds);
            
            if any(isnan(postchunk(1,:))  )%rarely, end of rips will include the start of an encode period , just chop them off
                postinds = postinds' & ~isnan(post_combined(1,:));
                postchunk = post_combined(:,postinds);
                nanripcount = nanripcount+1;
            end
            
            tmp.postts{r} = posteriorts(postinds);
            % classifier state
            tmp.post_curves{r} = classifier_curves(:,postinds);  % change to nansum so that it works for non-classifier posterior too
            bins_per_state = sum(tmp.post_curves{r}>classifier_state_thresh,2);   % # timebins that fit that category
            tmp.valid_states(r,:) = bins_per_state>0;
            tmp.max_state(r,:) = bins_per_state == max(bins_per_state) & bins_per_state > 0;
            tmp.frac_per_state(r,:) = bins_per_state/sum(bins_per_state);
            
            %content
            arm_sum = accumarray(grps(grps>0),sum(postchunk(grps>0,:),2));   % if non-classifier post must change to nansum
            tmp.arm_prop(r,:) = arm_sum/sum(arm_sum);
            tmp.posterior_max{r} = map(postinds);
            tmp.posbin_of_max{r} = indofmap(postinds);
            tmp.maxbins_per_seg(r,:) = histcounts(tmp.posbin_of_max{r},tmp.armedges);
            
            %CI
            tmp.CI_width{r} = nansum(CI(:,postinds));
            
            % linpos
            if strcmp(version,'v3')
                posinds = find(linposts>=tmp.riptimes(r,1) & linposts<=tmp.riptimes(r,2));
                tmp.linpos{r} = [linposts(posinds), linpos(posinds)];
            end
                
        end
        disp(sprintf('Rips including some nans: %d',nanripcount))
        
        % to save results in FF format, first check if a ripdecodes file already exists for this day
        % note that this will overwrite by default
        try
            load(ripfile);
            disp(sprintf('ripdecodes found for %sd%d; adding to it (or overwriting)',animal,d))
        catch
            disp(sprintf('no ripdecodes found for %s d%d; creating it',animal,d))
        end
        
        switch version
            case 'v2'
                ripdecodesv2{d}{e} = tmp;
                save(ripfile,'ripdecodesv2')
            case 'v3'
                ripdecodesv3{d}{e} = tmp;
                save(ripfile,'ripdecodesv3')   
            otherwise
                ripdecodes{d}{e} = tmp;
                save(ripfile,'ripdecodes')
        end
        
        %clearvars ripdecodes % delete after saving so that it doesnt stay in the workspace for the next day?
        out.success = 1;
        
    end
else
     disp(sprintf('NO decode for %s d%d e%d',animal, d, e)); 
     out.success = 0;
end 

if appendindex
    out.index = index;
end

end