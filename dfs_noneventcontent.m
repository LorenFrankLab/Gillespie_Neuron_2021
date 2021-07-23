%% Sungod Manu: quantify arm content in box inside and outside of rips 

animals = {'jaq','roquefort','despereaux','montague'}; %

for a = 1:length(animals)
    
    epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0 & $gooddecode==1']; % & $decode_error<=1
    %epochfilter{1} = ['$session==6  & isequal($environment,''goal'')'];
    %epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'') | isequal($environment,''hybrid2'') | isequal($environment,''hybrid3''))'];
    
    % resultant excludeperiods will define times when velocity is high
    timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
    iterator = 'epochbehaveanal';
    f(a) = createfilter('animal',animals{a},'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
    
    %args: 
    %converter = {[
    f(a) = setfilterfunction(f(a), 'dfa_noneventcontent', {'ca1rippleskons','trials','pos'},'animal',animals{a});
    f(a) = runfilter(f(a));
end

%save('/media/anna/whirlwindtemp2/ffresults/ctrl_noneventcontent.mat','f','-v7.3')
animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols

%load('/media/anna/whirlwindtemp2/ffresults/ctrl_movementquant_full2state_gooddecode.mat')
%load('/media/anna/whirlwindtemp2/ffresults/ctrl_movementquant_full2state_all_withtrialwise.mat')


%% heatmaps of error distributions per animal across days and summary of all days
all = figure(); set(gcf,'Position',[369 473 1387 408]); 
animcols = get(0,'DefaultAxesColorOrder');

for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.errorhist_bybin),f(a).output{1}));
    erange = f(a).output{1}(eps(1)).errorhist_edges(1:end-1);
    figure;
    for e = 1:length(eps)
        if size(f(a).output{1}(eps(e)).errorhist_bybin,1)<146
            orighist = [f(a).output{1}(eps(e)).errorhist_bybin; nan(1,50)];
            disp('adding a row')
        else
            orighist = f(a).output{1}(eps(e)).errorhist_bybin;
        end
        % normedhist(:,:,e) = orighist./repmat(sum(orighist,2),1,length(erange));
        normedhist(:,:,e) = orighist;
        if e>24  %plot the first 24
            break
        end
        subplot(4,6,e); hold on;
        imagesc(erange,[1:146],normedhist(:,:,e)); set(gca,'YDir','normal'); caxis([0 100]); colorbar;
        axis tight; title(sprintf('%s%de%d',animals{a}(1:3),f(a).epochs{1}(eps(e),1),f(a).epochs{1}(eps(e),2)))
    end
    animmean{a} = nanmean(normedhist,3); % stack data from all trials
    figure(all); subplot(2,3,a); imagesc(erange,[1:146],animmean{a}); 
    set(gca,'YDir','normal'); title(animals{a}); axis tight; ylabel('posbin'); caxis([0 100]); colorbar; xlabel('decode leads ------ decode lags')
    clear normedhist 
end

%% plot measurable fraction, mean error, error across eps/posbins
figure; 
% 1-measurable = arm-arm; measurable-sameseg = box-arm
for a = 1:length(animals)
    measurable{a} = cell2mat(arrayfun(@(x) x.measurable_bin_frac,f(a).output{1},'UniformOutput',0))';
    sameseg = cell2mat(arrayfun(@(x) x.same_seg,f(a).output{1},'UniformOutput',0))';
    bycat{a} = [sameseg, measurable{a}-sameseg, 1-measurable{a}];
    binerr = arrayfun(@(x) abs(x.meanerror),f(a).output{1},'UniformOutput',0)';
    short = find(cellfun(@(x) length(x)<140,binerr));
    for s = short'
        binerr{s} = [binerr{s} nan(1,140-length(binerr{s}))];
    end
    binerr = vertcat(binerr{:});
    meanerr{a} = nanmean(binerr,2);
    %if we want to exclude the worse days:
    %binerr(meanerr{a}>1,:) = nan;
    %meanerr{a}(meanerr{a}>1) = nan;
    
    subplot(4,2,[3 4]); hold on; title('error over eps')
    plot(repmat([1:size(binerr,1)],2,1),[nanmean(binerr,2)'+nanstd(binerr,[],2)'./sqrt(size(binerr,2));nanmean(binerr,2)'-nanstd(binerr,[],2)'./sqrt(size(binerr,2))],'Color',animcol(a,:));
    plot([1:size(binerr,1)], nanmean(binerr,2),'.-','Color',animcol(a,:),'Linewidth',2); 
    subplot(4,2,[5 6]); hold on; title('error over posbins')
    plot(repmat([1:size(binerr,2)],2,1),[nanmean(binerr)+nanstd(binerr)./sqrt(sum(~isnan(binerr(1,:))));nanmean(binerr)-nanstd(binerr)./sqrt(sum(~isnan(binerr(1,:))))],'Color',animcol(a,:));
    plot([1:size(binerr,2)], nanmean(binerr),'.-','Color',animcol(a,:),'Linewidth',2); 
   
    segnum = [0, cumsum(diff(~isnan(binerr(2,:)))==1)]+1;
    segnum(isnan(binerr(2,:)))=nan;
    errbyseg{a} = grpstats(binerr',segnum,'mean')';
end
subplot(4,2,1); hold on; plot4a(bycat,'gnames',{'sameseg','box-arm','diffarms'}); title('by category'); ylim([0 1]); ylabel('fraction samples');
text(9,.5,sprintf('ss mean: %.02f',mean(cellfun(@(x) nanmean(x(:,1)),bycat))))
text(9,.3,['n=' num2str(cellfun(@(x) sum(~isnan(x(:,1))), bycat))])
subplot(4,2,2); hold on; plot4a(meanerr); title('mean err'); ylabel('deviation (bins)'); xlabel('over epochs'); ylim([0 2])
subplot(4,2,[7 8]); hold on; plot4a(errbyseg,'gnames',{'box','1','2','3','4','5','6','7','8'}); ylim([0 5]); ylabel('deviation (bins)');

%% plot measurable fraction, mean error, CIs, numtets, numspikes
figure; 
parentdir = '/mnt/stelmo/anna/';
for a = 1:length(animals)
   
    sameseg{a} = cell2mat(arrayfun(@(x) x.same_seg,f(a).output{1},'UniformOutput',0))';
    binerr = arrayfun(@(x) abs(x.meanerror),f(a).output{1},'UniformOutput',0)';
    short = find(cellfun(@(x) length(x)<140,binerr));
    for s = short'
        binerr{s} = [binerr{s} nan(1,140-length(binerr{s}))];
    end
    binerr = vertcat(binerr{:});
    meanerr{a} = nanmean(binerr,2);

    subplot(4,1,1); hold on; title('frac same segment'); plot(sameseg{a},'.-','Color',animcol(a,:)); ylim([.5 1])
    subplot(4,1,2); hold on; title('mean err during movement')
    plot(repmat([1:size(binerr,1)],2,1),[nanmean(binerr,2)'+nanstd(binerr,[],2)'./sqrt(size(binerr,2));nanmean(binerr,2)'-nanstd(binerr,[],2)'./sqrt(size(binerr,2))],'Color',animcol(a,:));
    plot([1:size(binerr,1)], nanmean(binerr,2),'.-','Color',animcol(a,:)); 
    subplot(4,1,3); hold on; title('CI')
    movemeanCI = cell2mat(arrayfun(@(x) x.movemeanCI,f(a).output{1},'UniformOutput',0))';
    plot(movemeanCI,'.-','Color',animcol(a,:))
    immomeanCI = cell2mat(arrayfun(@(x) x.immomeanCI_norips,f(a).output{1},'UniformOutput',0))';
    plot(immomeanCI,'.:','Color',animcol(a,:));
    ripsmeanCI  = cell2mat(arrayfun(@(x) x.immomeanCI_rips,f(a).output{1},'UniformOutput',0))';
    plot(ripsmeanCI,'.--','Color',animcol(a,:)); ylim([0 75]);
    
    subplot(4,1,4); hold on; title('tetnums')
    tetinfo = loaddatastruct([parentdir animals{a} '/filterframework/'],animals{a},'tetinfo');
    tetlist = evaluatefilter(tetinfo,'isequal($area,''ca1'')');
    tetnum = table2array(rowfun(@(x) sum(tetlist(:,1)==x(1) & tetlist(:,2)==x(2)),table(f(a).epochs{1})));
    plot(tetnum,'.-','Color',animcol(a,:))
end
%% save mean error into taskstruct for each epoch for future filtering

for a = 1:length(animals)
    destdir = sprintf('/mnt/stelmo/anna/%s/filterframework/',animals{a});
    dayep = f(a).epochs{1};
    binerr = arrayfun(@(x) nanmean(abs(x.meanerror)),f(a).output{1},'UniformOutput',0)';
    sameseg = arrayfun(@(x) x.same_seg,f(a).output{1},'UniformOutput',0)';
   for e = 1:size(dayep,1)
        AG_addtaskinfo(destdir,animals{a},dayep(e,1),dayep(e,2),'decode_error',binerr{e});
        if sameseg{e}<.75
            AG_addtaskinfo(destdir,animals{a},dayep(e,1),dayep(e,2),'gooddecode',0);
        else
            AG_addtaskinfo(destdir,animals{a},dayep(e,1),dayep(e,2),'gooddecode',1);
        end
            
    end
end
    
%% plot mean decoding error per day 
figure; set(gcf,'Position',[369 473 862 408]); 
animcols = get(0,'DefaultAxesColorOrder');
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.meanerror),f(a).output{1}));
    meanerr = (arrayfun(@(x) x.meanerror,f(a).output{1}(eps),'UniformOutput',0));
    wronglength = cellfun(@(x) size(x,2),meanerr)~= median(cellfun(@(x) size(x,2),meanerr));
    disp(sprintf('%s %d eps with abnormal length',animals{a},sum(wronglength)));
    meanerr = vertcat(meanerr{~wronglength});
    subplot(2,1,1); hold on; plot(eps(~wronglength),nanmean(meanerr,2),'-o','Color',animcols(a,:),'MarkerSize',3); title('mean error across track by epoch')
    subplot(2,1,2); hold on; plot(nanmean(meanerr,1),'-o','Color',animcols(a,:),'MarkerSize',3); title('mean error across days by posbin')
end

%% analyze decoding error over the course of a trial block
clearvars -except f animals animcol
figure; set(gcf,'Position',[675 1 1202 973]);  plt=1;
contentthresh = .3;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        cont = f(a).output{1}(eps(e)).trips.contingency;
        valtrials = cont<=8;  % don't use any part of the epoch with repeat goals
        cont=cont(valtrials);
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);
        
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        tphasenum = [f(a).output{1}(eps(e)).trips.taskphase(valtrials), [1:length(goals)]'];   % add trial numbers
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
               valid = outertypes{t}'==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        % smoothing is ok here bc this is just used for visualizing the curves across trial, not quantification per phase
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        for r = 1:8; countspertrial(r,:) = smoothvect(countspertrial(r,:), kernel); end
        vispertrial = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        ind=1;
        for c = 1:max(cont)  % for each contingency, count search and repeat phases separately
            searchreplays = replays(cont==c & tphasenum(:,1)<=1);  
                replaycount{a}{e}(ind,:) = histcounts(cell2mat(searchreplays),[1:9]);
                trialcount{a}{e}(ind,:) = repmat(sum(cont==c & tphasenum(:,1)<=1),1,8);
                visitcount{a}{e}(ind,:) = histcounts(outers(cont==c & tphasenum(:,1)<=1),[1:9]);
                ecp{a}{e}(ind,:) = [e, c, 1]; % epoch cont phase (search=1, repeat=2);
                goalarm{a}{e}(ind) = nan;
                if ind==1
                goalreplay{a}{e}(ind,:) = [nan sum(replaycount{a}{e}(ind,:))];
                cumgoalreplay{a}{e}(ind,:) = goalreplay{a}{e}(ind,:);
                else
                    goalsofar = goalarm{a}{e}(~isnan(goalarm{a}{e}));
                goalreplay{a}{e}(ind,:) = [sum(replaycount{a}{e}(ind,goalsofar)),sum(replaycount{a}{e}(ind,~ismember([1:8],goalsofar)))]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = nansum([goalreplay{a}{e}(ind,:);cumgoalreplay{a}{e}(ind-1,:)]);
                end
            ind = ind+1;
            
            if any(cont==c & tphasenum(:,1)==4)  % needs to earn at least 4 goals for this cont to count
                replaycount{a}{e}(ind,:) = histcounts(cell2mat(replays(cont==c & tphasenum(:,1)>1)),[1:9]);
                trialcount{a}{e}(ind,:) = repmat(sum(cont==c & tphasenum(:,1)>1),1,8);
                goalarm{a}{e}(ind) = goals(cont==c & tphasenum(:,1)==1); % convenient to use first trial to indicate goal
                visitcount{a}{e}(ind,:) = histcounts(outers(cont==c & tphasenum(:,1)>1),[1:9]);
                ecp{a}{e}(ind,:) = [e c 2]; % epoch cont phase (search=1, repeat=2);
                goalsofar = goalarm{a}{e}(~isnan(goalarm{a}{e}));
                goalreplay{a}{e}(ind,:) = [sum(replaycount{a}{e}(ind,goalsofar)),sum(replaycount{a}{e}(ind,~ismember([1:8],goalsofar)))]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = nansum([goalreplay{a}{e}(ind,:);cumgoalreplay{a}{e}(ind-1,:)]);
                searchlength{a}{e}(c) = sum(cont==c & tphasenum(:,1)<1); % if complete cont, store search length for later

            else % not enough of this goal experienced
                replaycount{a}{e}(ind,:) = nan(1,8);
                trialcount{a}{e}(ind,:) = nan(1,8);
                visitcount{a}{e}(ind,:) = nan(1,8);
                goalarm{a}{e}(ind) = nan; 
                ecp{a}{e}(ind,:) = [nan nan nan]; % epoch cont phase (search=1, repeat=2);
                goalreplay{a}{e}(ind,:) = [nan nan]; % totalgoalreplay totalngreplay cumgoalreplay cumngreplay
                cumgoalreplay{a}{e}(ind,:) = [nan nan];
            end
            ind = ind+1;
        end
        replaypertrial{a}{e} = [nan(4,8); replaycount{a}{e}./trialcount{a}{e}; nan(6,8)];  % pad with nans for alignment
        goalarm{a}{e} = [nan(1,4), goalarm{a}{e},nan(1,6)];
        visitcount{a}{e} = [nan(4,8); visitcount{a}{e}; nan(6,8)];  
        goallist = unique(goalarm{a}{e}(~isnan(goalarm{a}{e})),'stable');
        nevergoals{a}{e} = find(~ismember([1:8],goallist));
        %subplot(1,4,a);hold on;
        %if length(goallist)>3
        realignednongoal{a}{e} = [];
        realignednongoalvis{a}{e} = [];
        bytrial_firstrew_non{a}{e} = [];
        bytrial_lastrew_non{a}{e} = [];
        bytrial_start_non{a}{e} = [];
        bytrial_firstrewvis_non{a}{e} = [];
        bytrial_lastrewvis_non{a}{e} = [];
        for c = 1:length(goallist)
            inds = [-4+find(goalarm{a}{e}==goallist(c)):find(goalarm{a}{e}==goallist(c))+6];
            realigned{a}{e}(c,:) = replaypertrial{a}{e}(inds,goallist(c));
            realignedvis{a}{e}(c,:) = visitcount{a}{e}(inds,goallist(c));
            if ~isempty(nevergoals{a}{e})
            %randnongoal = randi(length(nevergoals{a}{e}));  % choose a random unrewarded arm
            %allbutgoal = find(goallist(c)~=[1:8]);
            realignednongoal{a}{e} = [realignednongoal{a}{e}; replaypertrial{a}{e}(inds,nevergoals{a}{e})']; % add all nonrewarded arms to list
            %realignednongoal{a}{e} = [realignednongoal{a}{e}; replaypertrial{a}{e}(inds,allbutgoal)']; % add all nonrewarded arms to list
            realignednongoalvis{a}{e} = [realignednongoalvis{a}{e}; visitcount{a}{e}(inds,nevergoals{a}{e})'];
            end
            goalnum{a}{e}(c) = sum(tphasenum(cont==c,1)>=1 & mod(tphasenum(cont==c,1),1)==0);
            % trialwise curves (aligned to first and last reward of cont)
            start = find(cont==c & tphasenum(:,1)==1);
            firstinds = start-window:start+window;
            bytrial_firstrew{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_firstrew{a}{e}(c,find(firstinds>0 & firstinds<=length(outers)))= countspertrial(goallist(c),firstinds(firstinds>0 & firstinds<=length(outers)));
            bytrial_firstrewvis{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_firstrewvis{a}{e}(c,find(firstinds>0 & firstinds<=length(outers)))= vispertrial(goallist(c),firstinds(firstinds>0 & firstinds<=length(outers)));
            start= find(cont==c & tphasenum(:,1)==max(tphasenum(cont==c & mod(tphasenum(:,1),1)==0,1)));
            lastinds = start-window:start+window;
            bytrial_lastrew{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_lastrew{a}{e}(c,find(lastinds>0 & lastinds<=length(outers)))= countspertrial(goallist(c),lastinds(lastinds>0 & lastinds<=length(outers)));
            bytrial_lastrewvis{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_lastrewvis{a}{e}(c,find(lastinds>0 & lastinds<=length(outers)))= vispertrial(goallist(c),lastinds(lastinds>0 & lastinds<=length(outers)));
            %post-cont replay/visit count
            if sum(lastinds>start & lastinds<=length(outers))==window % only collect data if all trials available
                postreplaycount{a}{e}(c) = sum(countspertrial(goallist(c),lastinds(lastinds>start & lastinds<=length(outers))));
                postviscount{a}{e}(c) = sum(vispertrial(goallist(c),lastinds(lastinds>start & lastinds<=length(outers)))); 
            else
                postreplaycount{a}{e}(c) = nan;
                postviscount{a}{e}(c) = nan;
            end
            
            start= find(cont==c,1);
            startinds = start-window:start+window;
            bytrial_start{a}{e}(c,:) = nan(1,2*window+1);
            bytrial_start{a}{e}(c,find(startinds>0 & startinds<=length(outers)))= countspertrial(goallist(c),startinds(startinds>0 & startinds<=length(outers)));
 
            if ~isempty(nevergoals{a}{e})
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(firstinds>0 & firstinds<=length(outers)))= countspertrial(nevergoals{a}{e},firstinds(firstinds>0 & firstinds<=length(outers)));
                bytrial_firstrew_non{a}{e} = [bytrial_firstrew_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(firstinds>0 & firstinds<=length(outers)))= vispertrial(nevergoals{a}{e},firstinds(firstinds>0 & firstinds<=length(outers)));
                bytrial_firstrewvis_non{a}{e} = [bytrial_firstrewvis_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(lastinds>0 & lastinds<=length(outers)))= countspertrial(nevergoals{a}{e},lastinds(lastinds>0 & lastinds<=length(outers)));
                bytrial_lastrew_non{a}{e} = [bytrial_lastrew_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(lastinds>0 & lastinds<=length(outers)))= vispertrial(nevergoals{a}{e},lastinds(lastinds>0 & lastinds<=length(outers)));
                bytrial_lastrewvis_non{a}{e} = [bytrial_lastrewvis_non{a}{e}; tmp];
                tmp = nan(length(nevergoals{a}{e}),2*window+1);
                tmp(:,find(startinds>0 & startinds<=length(outers)))= countspertrial(nevergoals{a}{e},startinds(startinds>0 & startinds<=length(outers)));
                bytrial_start_non{a}{e} = [bytrial_start_non{a}{e}; tmp];
            end
            
            
            
        %    plot([1:9],replaypertrial{a}{e}(inds,goallist(c)),'k-o');
        end
        %realigned{a}{e} = realigned{a}{e}(searchlength(1:length(goallist))>=4,:);
        %realignednongoal{a}{e} = realignednongoal{a}{e}(searchlength(1:length(goallist))>=4,:);
        
        %end
        %figure; subplot(3,1,1); plot(replaypertrial{a}{e}); legend; title(['ep',num2str(e)])
        %subplot(3,1,2); hold on; plot(realigned{a}{e}'); plot(realignednongoal{a}{e}',':'); title(num2str(unique(goalarm{a}{e}(~isnan(goalarm{a}{e})),'stable')));
        %subplot(3,1,3); hold on; plot(nanmean(realigned{a}{e})); plot(nanmean(realignednongoal{a}{e}),':');
    end
    
    % BY TRIAL CURVES - aligned to first reward of cont
%     xvals = -window:window;
%     firstrewcurve = vertcat(bytrial_firstrew{a}{:}); firstrewcurve_non = vertcat(bytrial_firstrew_non{a}{:}); 
%     %firstrewcurve = vertcat(bytrial_start{a}{:}); firstrewcurve_non = vertcat(bytrial_start_non{a}{:}); 
%     %valeps = ~cellfun(@isempty,bytrial_firstrew{a}) & cellfun(@(x) sum(~isnan(x)),goalarm{a})>=1;
%     %firstrewcurve = cell2mat(cellfun(@(x) x(1,:)',bytrial_firstrew{a}(valeps),'un',0))';  % just plot a single contingency#
%     %firstrewcurve_non = cell2mat(cellfun(@(x,y) x((1-1)*length(y)+[1:length(y)],:)',bytrial_firstrew_non{a}(valeps),nevergoals{a}(valeps),'un',0))';  % just plot a single contingency#
%     subplot(4,4,a+12); hold on; ylabel('replay/trial'); xlabel('trials from first rew of block')
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstrewcurve)-nanstd(firstrewcurve)./sqrt(sum(~isnan(firstrewcurve))), fliplr(nanmean(firstrewcurve)+nanstd(firstrewcurve)./sqrt(sum(~isnan(firstrewcurve))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstrewcurve),'Color',animcol(a,:),'Linewidth',1);
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstrewcurve_non)-nanstd(firstrewcurve_non)./sqrt(sum(~isnan(firstrewcurve_non))), fliplr(nanmean(firstrewcurve_non)+nanstd(firstrewcurve_non)./sqrt(sum(~isnan(firstrewcurve_non))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstrewcurve_non),':','Color',animcol(a,:),'Linewidth',1);
%     ylim([0 2]); plot([0 0],[0 2],'k');  title(animals{a}); xlim([-40 40]);
%     for r = 1:length(xvals)
%        [p{a}(r),~]=ranksum(firstrewcurve(:,r),firstrewcurve_non(:,r)); % ttest for paired, ttest2 for unpaired
%     end
%     plot(xvals(p{a}<.05/length(xvals)),1.8*ones(sum(p{a}<.05/length(xvals)),1),'r.');
%     firstviscurve = vertcat(bytrial_firstrewvis{a}{:}); firstviscurve_non = vertcat(bytrial_firstrewvis_non{a}{:}); 
%     %valeps = ~cellfun(@isempty,bytrial_lastrew{a}) & cellfun(@(x) sum(~isnan(x)),goalarm{a})>=1;
%     %lastrewcurve = cell2mat(cellfun(@(x) x(1,:)',bytrial_lastrew{a}(valeps),'un',0))';  % just plot a single contingency#
%     %lastrewcurve_non = cell2mat(cellfun(@(x,y) x((1-1)*length(y)+[1:length(y)],:)',bytrial_lastrew_non{a}(valeps),nevergoals{a}(valeps),'un',0))';  % just plot a single contingency#
%     subplot(4,4,a+12); hold on; ylabel('visits/trial'); xlabel('trials from first reward of block')
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstviscurve)-nanstd(firstviscurve)./sqrt(sum(~isnan(firstviscurve))), fliplr(nanmean(firstviscurve)+nanstd(firstviscurve)./sqrt(sum(~isnan(firstviscurve))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstviscurve),'Color',animcol(a,:),'Linewidth',1);
%     h = fill([xvals, fliplr(xvals)], [nanmean(firstviscurve_non)-nanstd(firstviscurve_non)./sqrt(sum(~isnan(firstviscurve_non))), fliplr(nanmean(firstviscurve_non)+nanstd(firstviscurve_non)./sqrt(sum(~isnan(firstviscurve_non))))],animcol(a,:),'FaceAlpha',.3);%
%     set(h,'EdgeColor','none'); plot(xvals, nanmean(firstviscurve_non),':','Color',animcol(a,:),'Linewidth',1);
%     plot([0 0],[0 12],'k'); ylim([0 1.5]);   title(animals{a}); xlim([-40 40]);
%     for r = 1:length(xvals)
%        [p{a}(r),~]=ranksum(firstviscurve(:,r),firstviscurve_non(:,r)); % ttest for paired, ttest2 for unpaired
%     end
%     plot(xvals(p{a}<.05/length(xvals)),1.2*ones(sum(p{a}<.05/length(xvals)),1),'r.');
    % TRIALCURVES - aligned to last reward of cont
    xvals = -window:window;
    lastrewcurve = vertcat(bytrial_lastrew{a}{:}); lastrewcurve_non = vertcat(bytrial_lastrew_non{a}{:}); 
    subplot(4,4,a); hold on; ylabel('replay/trial'); xlabel('trials from last rew of block')
    h = fill([xvals, fliplr(xvals)], [nanmean(lastrewcurve)-nanstd(lastrewcurve)./sqrt(sum(~isnan(lastrewcurve))), fliplr(nanmean(lastrewcurve)+nanstd(lastrewcurve)./sqrt(sum(~isnan(lastrewcurve))))],animcol(a,:),'FaceAlpha',.3);%
    set(h,'EdgeColor','none'); plot(xvals, nanmean(lastrewcurve),'Color',animcol(a,:),'Linewidth',1);
    h = fill([xvals, fliplr(xvals)], [nanmean(lastrewcurve_non)-nanstd(lastrewcurve_non)./sqrt(sum(~isnan(lastrewcurve_non))), fliplr(nanmean(lastrewcurve_non)+nanstd(lastrewcurve_non)./sqrt(sum(~isnan(lastrewcurve_non))))],animcol(a,:),'FaceAlpha',.3);%
    set(h,'EdgeColor','none'); plot(xvals, nanmean(lastrewcurve_non),':','Color',animcol(a,:),'Linewidth',1);
    ylim([0 2]); plot([0 0],[0 2],'k');  title(animals{a}); xlim([-40 40]);
    for r = 1:length(xvals)
       [p{a}(r),~]=ranksum(lastrewcurve(:,r),lastrewcurve_non(:,r)); % ttest for paired, ttest2 for unpaired
    end