%% Sungod manu: Plot main results of likelihoods rather than full decodes
% WAY fewer events that reach .3 criterion, so lower it [WITH 2MS BINS only]
% thresh is fine for 20ms bins

animals = {'jaq','roquefort','despereaux','montague'};  %,, 'remy',};%};

epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0 & $gooddecode==1']; %& $epoch==2
%epochfilter{1} = ['$session==27'];

% resultant excludeperiods will define times when velocity is high
timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
iterator = 'epochbehaveanal';

f = createfilter('animal',animals,'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
f = setfilterfunction(f, 'dfa_likcontent', {'lik20decodesv2','trials','pos'});
f = runfilter(f);

animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols

%% boxplot version of violin with epoch means [HOME / RW] [3A,B]
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
reps = 100;
mintrials = 5;
contentthresh = .3;
for a = 1:length(animals)
    %figure; set(gcf,'Position',[1008 1009 663 833]);
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x;y;z],hometypes,rwtypes,postrwtypes,'un',0);
        clear replays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1' & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
        end
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        
        valtrials = ~cellfun(@isempty, replays);
        if any(valtrials)
            ripcomb = cellfun(@(x,y,z,g,h) [x', repmat([y,z,g,h],length(x),1)], replays(valtrials), num2cell(outers(valtrials)), ...
                num2cell(pastwlock(valtrials))', num2cell(goals(valtrials,:),2)',num2cell(tphasenum(valtrials,:),2)','un',0);
            ripcomb = vertcat(ripcomb{:});
        salient = ripcomb(:,1)>0 & (ripcomb(:,1)==ripcomb(:,2) | ripcomb(:,1)==ripcomb(:,3) | table2array(rowfun(@(x) ismember(x(1),goals(1:x(8),1)),table(ripcomb))));
        contentfracs{a}(e,:) = [length(vertcat(rips{:}))-size(ripcomb,1), sum(ripcomb(:,1)==0), sum(salient), sum(ripcomb(:,1)>0 & ~salient)]./length(vertcat(rips{:}));

        % all ripples during search trials; f vs past vs pgoal
        search = ripcomb((ripcomb(:,7) <= 1 &  ~isnan(ripcomb(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([2,3,5])))==3,table(search)));
        allunique = search(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            search_future{a}(e) = sum(allunique(:,1)==allunique(:,2))/sum(allunique(:,1)>0);
            search_past{a}(e) = sum(allunique(:,1)==allunique(:,3))/sum(allunique(:,1)>0);
            search_prevgoal{a}(e) = sum(allunique(:,1)==allunique(:,5))/sum(allunique(:,1)>0); 
            search_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,3) & allunique(:,1)~=allunique(:,5))/5/sum(allunique(:,1)>0);
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                search_randshuff{a}(e,r) = sum(allunique(:,1)==randlist)/sum(allunique(:,1)>0);
           end
        end
        search_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)<1)];  % #rips #trials #totalsearchtrials 

        % all ripples during repeat trials; future==past==goal vs pg
        repeat = ripcomb((ripcomb(:,7) > 1 &  ~isnan(ripcomb(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        alluniqueinds = table2array(rowfun(@(x) length(unique(x([2,3,4])))==1,table(repeat))) & repeat(:,5)~=repeat(:,2);
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            rep1_pfg{a}(e) = sum(allunique(:,1)==allunique(:,2))/sum(allunique(:,1)>0);
            rep1_prevgoal{a}(e) = sum(allunique(:,1)==allunique(:,5))/sum(allunique(:,1)>0);
            rep1_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,5))/6/sum(allunique(:,1)>0);
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep1_randshuff{a}(e,r) = sum(allunique(:,1)==randlist)/sum(allunique(:,1)>0);
           end
        end
        rep1_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
        end
    end
    % past future cg pg 
    searchcomb{a} = [search_past{a}(search_rtcounts{a}(:,2)>=mintrials)' search_future{a}(search_rtcounts{a}(:,2)>=mintrials)' search_prevgoal{a}(search_rtcounts{a}(:,2)>=mintrials)' search_other{a}(search_rtcounts{a}(:,2)>=mintrials)'];
    searchshuffcomb{a} = reshape(search_randshuff{a}(search_rtcounts{a}(:,2)>=mintrials,:),[],1); 
    repcomb{a} = [rep1_pfg{a}(rep1_rtcounts{a}(:,2)>=mintrials)' rep1_prevgoal{a}(rep1_rtcounts{a}(:,2)>=mintrials)' rep1_other{a}(rep1_rtcounts{a}(:,2)>=mintrials)'];
    repshuffcomb{a} = reshape(rep1_randshuff{a}(rep1_rtcounts{a}(:,2)>=mintrials,:),[],1); 
    
    search_p{a} = [ranksum(searchcomb{a}(:,1),searchshuffcomb{a}),ranksum(searchcomb{a}(:,2),searchshuffcomb{a}),ranksum(searchcomb{a}(:,3),searchshuffcomb{a}),ranksum(searchcomb{a}(:,4),searchshuffcomb{a})];
    rep_p{a} = [ranksum(repcomb{a}(:,1),repshuffcomb{a}),ranksum(repcomb{a}(:,2),repshuffcomb{a}),ranksum(repcomb{a}(:,3),repshuffcomb{a})];
end
subplot(1,8,1); ylabel('fraction of remote replay')
plot4a(searchshuffcomb,'gnames',{'null'}); ylim([0 .5]); text(6,.4,num2str(cellfun(@(x) sum(x(:,2)>=mintrials),search_rtcounts)))
subplot(1,8,[2 3 4]); hold on; title('search')
plot4a(searchcomb,'gnames',{'past','future','pg','other'});
text(8,.45,num2str(vertcat(search_p{:})))
plot([1 40],[.125 .125],'k:'); ylim([0 .5])
subplot(1,8,5); 
plot4a(repshuffcomb,'gnames',{'null'}); ylim([0 .5]); text(6,.4,num2str(cellfun(@(x) sum(x(:,2)>=mintrials),rep1_rtcounts)))
subplot(1,8,[6 7 8]); hold on; title('repeat')
plot4a(repcomb,'gnames',{'pfg','pg','other'});
plot([1 40],[.125 .125],'k:'); ylim([0 .5])
text(8,.45,num2str(vertcat(rep_p{:}))); xlabel(['mintrials=' num2str(mintrials)]);ylabel('fraction of remote replay')

%% fit linear model of category predictors for each arm, for box and outer  [FIG 3D,E and FIG 4 A,B and FIG 7B]
clearvars -except f animals animcol
contentthresh = .3;
all = figure(); 
search_pooled = [];  repeat_pooled = [];
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x;y;z],hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);
        
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1' & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        future = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        past = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(pastwlock'),'un',0));
        prevgoal = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(goals(:,2)'),'un',0));
        currgoal = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(goals(:,1)'),'un',0));
        allsearch{a}{e} = [reshape(future(:,tphasenum(:,1)<=1),[],1),reshape(past(:,tphasenum(:,1)<=1),[],1),reshape(prevgoal(:,tphasenum(:,1)<=1),[],1) ...
                    reshape(countspertrial(:,tphasenum(:,1)<=1),[],1)]; % [future past prevgoal #replays];
        allrepeat{a}{e} = [reshape(future(:,tphasenum(:,1)>1),[],1),reshape(past(:,tphasenum(:,1)>1),[],1),reshape(currgoal(:,tphasenum(:,1)>1),[],1) ...
                    ,reshape(prevgoal(:,tphasenum(:,1)>1),[],1), reshape(countspertrial(:,tphasenum(:,1)>1),[],1)]; % [future past currgoal prevgoal #replays];
        earlycorr = tphasenum(:,1)>1 & tphasenum(:,1)<5 & outers'==goals(:,1);
        earlycorrrepeat{a}{e} = [reshape(future(:,earlycorr),[],1),reshape(past(:,earlycorr),[],1),reshape(currgoal(:,earlycorr),[],1) ...
                    ,reshape(prevgoal(:,earlycorr),[],1), reshape(countspertrial(:,earlycorr),[],1)]; % [future past currgoal prevgoal #replays];
        latecorr = tphasenum(:,1)>4 & outers'==goals(:,1);
        latecorrrepeat{a}{e} = [reshape(future(:,latecorr ),[],1),reshape(past(:,latecorr ),[],1),reshape(currgoal(:,latecorr ),[],1) ...
                    ,reshape(prevgoal(:,latecorr ),[],1), reshape(countspertrial(:,latecorr ),[],1)]; % [future past currgoal prevgoal #replays];
        earlyerr = tphasenum(:,1)>1 & tphasenum(:,1)<5 & outers'~=goals(:,1);
        earlyerrrepeat{a}{e} = [reshape(future(:,earlyerr),[],1),reshape(past(:,earlyerr),[],1),reshape(currgoal(:,earlyerr),[],1) ...
                    ,reshape(prevgoal(:,earlyerr),[],1), reshape(countspertrial(:,earlyerr),[],1)]; % [future past currgoal prevgoal #replays];
        lateerr = tphasenum(:,1)>4 & outers'~=goals(:,1);
        lateerrrepeat{a}{e} = [reshape(future(:,lateerr ),[],1),reshape(past(:,lateerr ),[],1),reshape(currgoal(:,lateerr ),[],1) ...
                    ,reshape(prevgoal(:,lateerr ),[],1), reshape(countspertrial(:,lateerr ),[],1)]; % [future past currgoal prevgoal #replays];

        for arm = 1:8
            searchbyarm{a}{arm}{e} = [future(arm,tphasenum(:,1)<=1)',past(arm,tphasenum(:,1)<=1)',prevgoal(arm,tphasenum(:,1)<=1)',countspertrial(arm,tphasenum(:,1)<=1)'];
            repeatbyarm{a}{arm}{e} = [future(arm,tphasenum(:,1)>1)',past(arm,tphasenum(:,1)>1)',currgoal(arm,tphasenum(:,1)>1)',prevgoal(arm,tphasenum(:,1)>1)',countspertrial(arm,tphasenum(:,1)>1)'];
        end
        outercountspertrial = zeros(8,length(outers));
        outercountspertrial(:,~cellfun(@isempty,outerreplays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',outerreplays(~cellfun(@isempty,outerreplays)),'un',0));
        rewd = mod(tphasenum(:,1),1)==0 & tphasenum(:,1)>0;
        allouterrew{a}{e} = [reshape(past(:,rewd),[],1),reshape(currgoal(:,rewd),[],1), ...
                    reshape(prevgoal(:,rewd),[],1), reshape(outercountspertrial(:,rewd),[],1)]; % [ past current prevgoal #replays];

    end
    figure(all);
    searchcat = vertcat(allsearch{a}{:});
    searchtbl = table(searchcat(:,2),searchcat(:,1),searchcat(:,3),searchcat(:,4),'VariableNames',{'past','future','prevgoal','replaynum'});
    s_mdl = fitglm(searchtbl,'linear','Distribution','poisson');
    CI = coefCI(s_mdl,.01);
    subplot(1,3,1); hold on; title('likelihoods - allsearch')
    %errorbar(a+[0:5:19],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
    plot(a+[0:5:19],exp(table2array(s_mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:));
    %cr = [corrcoef(searchcat(:,1),searchcat(:,2)), corrcoef(searchcat(:,1),searchcat(:,3)), corrcoef(searchcat(:,2),searchcat(:,3))];
    %searchr2(a, :)=cr(1,[2 4 6]).^2;
    text(5,2+.2*a,['trial n=',num2str(size(searchcat,1)/8)],'Color',animcol(a,:));
    repeatcat = vertcat(allrepeat{a}{:});
    reptbl = table(repeatcat(:,2),repeatcat(:,1),repeatcat(:,3),repeatcat(:,4),repeatcat(:,5),'VariableNames',{'past','future','currgoal','prevgoal','replaynum'});
    r_mdl = fitglm(reptbl,'linear','Distribution','poisson'); 
    CI = coefCI(r_mdl,.01);
    subplot(1,3,2); hold on; title('likelihoods - allrepeat')
    %errorbar(a+[0:5:24],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
    plot(a+[0:5:24],exp(table2array(r_mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:));
    %cr = [corrcoef(repeatcat(:,1),repeatcat(:,2)), corrcoef(repeatcat(:,1),repeatcat(:,3)),corrcoef(repeatcat(:,1),repeatcat(:,4)), ...
    %    corrcoef(repeatcat(:,2),repeatcat(:,3)), corrcoef(repeatcat(:,2),repeatcat(:,4)),corrcoef(repeatcat(:,3),repeatcat(:,4))];
    %repr2(a,:)=cr(1,[2:2:12]).^2;
    %text(5,2+.2*a,['f vs cg corrcoef=',num2str(cr(2),'%.03f')],'Color',animcol(a,:));
    text(5,2+.2*a,['trial n=',num2str(size(repeatcat,1)/8)],'Color',animcol(a,:));
    outercat = vertcat(allouterrew{a}{:});
    mdl = fitglm(outercat(:,1:3),outercat(:,4),'linear','Distribution','poisson'); 
    CI = coefCI(mdl,.01);
    subplot(1,3,3); hold on; title('outer rewarded')
    plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:));
    text(5,2+.2*a,['trial n=',num2str(size(outercat,1)/8)],'Color',animcol(a,:));
    
     search_pooled = [search_pooled;searchcat]; repeat_pooled = [repeat_pooled;repeatcat];
end
figure(all)
subplot(1,3,1); xlim([0 20]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:19],'XTickLabel',{'intrcpt','past','future','prevgoal'})
plot([0 20],[1 1],'k:'); set(gca,'YScale','log'); ylim([.4 3]);
subplot(1,3,2); set(gca,'YScale','log'); ylim([.4 3]); xlim([0 25]);set(gca,'XTick',2+[0:5:24],'XTickLabel',{'intrcpt','past','future','curgoal','prevgoal'})
plot([0 25],[1 1],'k:');
subplot(1,3,3); set(gca,'YScale','log'); ylim([.7 20]); xlim([0 20]);set(gca,'XTick',2+[0:5:20],'XTickLabel',{'intrcpt','past','current','prevgoal'})
plot([0 20],[1 1],'k:'); ylabel('[.7 20]')


%%  measure effect of recency on replay rate; compare PGreplay rate on pg and nonpg visits   [FIG 6 and SUP FIG 5D]
clearvars -except f animals animcol
bars = figure();  set(gcf,'Position',[110 446 1747 518]); reg = figure(); set(gcf,'Position',[110 446 1747 518]);
contentthresh = .3;
plt=1;
sinceedges = [-40:1];
untiledges = [0:40];
kernel = gaussian(1,5);
window =50;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
   
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x;y;z],hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials); %
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        goals(tphasenum(:,1)<=1,1) = nan; % turn currgoals during search trials into nans
        goals(goals(:,1)==0,1) = nan;
        goals(mod(tphasenum(:,1),1)>.85,:) = goals(find(mod(tphasenum(:,1),1)>.85)-1,:); % fix the last visit of cont (.9) to not reflect new goal yet
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastNOlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,1);  % only consider the including lockout option
        trialstack  = [outers', pastNOlock, goals,tphasenum(:,1)];
        clear replays outerreplays recency pgvisit
        for t=1:length(rips)  % extract valid rips and tack on trial info: [replay future past currgoal prevgoal ppgoal tphase salient local]
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1' & maxval>contentthresh;
                replays{t} =[ind(valid)-1]; %,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==0];
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
               valid = outertypes{t}==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
           % for each arm, calc trialdist to/from visit, categorize and replayed, salient 
            for r = 1:8  %[since until boxreplayed outerreplayed salient]
                if any(outers(1:t-1)==r)
                    recency{t}(r,1) = -(t-find(outers(1:t-1)==r,1,'last'));
                else recency{t}(r,1) = nan; end
                if any(outers(t+1:end)==r)
                    recency{t}(r,2) = find(outers(t:end)==r,1,'first');
                else recency{t}(r,2) = nan; end
                recency{t}(r,[3 4]) = [sum(r==replays{t}) sum(r==outerreplays{t})];
                recency{t}(r,5) = ismember(r,trialstack(1:t,4));  % salient= any previously rewarded arm (OR just prevgoal any(r==trialstack(t,4)))
            end
            % is this trial a visit to previous goal and if so, is there pgreplay? future replay? [pgvis pgreplay futurereplay]
            pgoals = goals(t,2);  % nans still included, but doesnt matter
            if any(pgoals)
                pgvisit(t,:) = [any(outers(t)==pgoals) any(intersect(replays{t},pgoals)) any(replays{t}==outers(t))];
            else pgvisit(t,:) = [nan nan any(replays{t}==outers(t))];
            end
        end
        countspertrial = zeros(8,length(outers));
        countspertrial(:,~cellfun(@isempty,replays)) = cell2mat(cellfun(@(x) histcounts(x,[1:9])',replays(~cellfun(@isempty,replays)),'un',0));
        %for r = 1:8; countspertrial(r,:) = smoothvect(countspertrial(r,:), kernel); end
        vispertrial = cell2mat(cellfun(@(x) histcounts(x,[1:9])',num2cell(outers),'un',0));
        % group recency into 1,2,3,4,5+
        recencypertrial = cellfun(@(x) [abs(x(:,1))==1,abs(x(:,1))==2,abs(x(:,1))==3,abs(x(:,1))==4,abs(x(:,1))>=5] ,recency,'un',0);
        untilpertrial = cellfun(@(x) [x(:,2)==1,x(:,2)==2,x(:,2)==3,x(:,2)==4,x(:,2)>=5] ,recency,'un',0);
        allsearchrecency{a}{e} = [vertcat(recencypertrial{tphasenum(:,1)<=1}), reshape(countspertrial(:,tphasenum(:,1)<=1),[],1)]; % [recency #replays];
        allsearchuntil{a}{e} = [vertcat(untilpertrial{tphasenum(:,1)<=1}), reshape(countspertrial(:,tphasenum(:,1)<=1),[],1)]; % [until #replays];

         %for each search trial, plot replay count curve
        goallist = unique(goals(~isnan(goals(:,1)),1),'stable');
        %tri = find(tphasenum(:,1)<1 & ~ismember(outers,goallist)'); %
        tri = find(outers'==goals(:,2) & tphasenum(:,1)<1);
%         tri = [];
%         for r = 1:8
%             if any(outers==r)
%                 tri = [tri find(outers==r,1,'first')];
%             end
%         end
        for t = 1:length(tri)
            inds = tri(t)-window:tri(t)+window;
            searchcurve{a}{e}(t,:) = nan(1,2*window+1);
            searchcurve{a}{e}(t,find(inds>0 & inds<=length(outers)))= countspertrial(outers(tri(t)),inds(inds>0 & inds<=length(outers)));
            visitcurve{a}{e}(t,:) = nan(1,2*window+1);
            visitcurve{a}{e}(t,find(inds>0 & inds<=length(outers)))= vispertrial(outers(tri(t)),inds(inds>0 & inds<=length(outers)));
        end
        clear tri
        
        since_replayed_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==1,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_replayed_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==1,2)',recency,'un',0)),untiledges,'Normalization','probability');
        since_non_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==1,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_non_sal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==1,2)',recency,'un',0)),untiledges,'Normalization','probability');
        since_replayed_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==0,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_replayed_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==1 & x(:,5)==0,2)',recency,'un',0)),untiledges,'Normalization','probability');
        since_non_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==0,1)',recency,'un',0)),sinceedges,'Normalization','probability');
        until_non_nonsal{a}(e,:) = histcounts(cell2mat(cellfun(@(x) x(x(:,3)==0 & x(:,5)==0,2)',recency,'un',0)),untiledges,'Normalization','probability');
        
        % what is the replay rate of -x recencies get replayed? [-1, -2, -3, -4, -5, any]; (mean per epoch
        recencyfrac{a}(e,:) = [mean(cellfun(@(x) x(x(:,1)==-1 & x(:,5)==0,3), recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-1 & x(:,5)==0),recency)'))), ...
                               mean(cellfun(@(x) x(x(:,1)==-2 & x(:,5)==0,3), recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-2 & x(:,5)==0),recency)'))), ...
                                mean(cellfun(@(x) x(x(:,1)==-3 & x(:,5)==0,3),recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-3 & x(:,5)==0),recency)'))), ...
                                mean(cellfun(@(x) x(x(:,1)==-4 & x(:,5)==0,3),recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-4 & x(:,5)==0),recency)'))), ...
                                mean(cell2mat(cellfun(@(x) x(x(:,1)<=-5 & x(:,5)==0,3)',recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)<=-5 & x(:,5)==0),recency)'),'un',0)))];
       % for pooling across epochs instead
        recencyfrac1{a}{e} = cellfun(@(x) x(x(:,1)==-1 & x(:,5)==0,3), recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-1 & x(:,5)==0),recency)'));
        recencyfrac2{a}{e} = cellfun(@(x) x(x(:,1)==-2 & x(:,5)==0,3), recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-2 & x(:,5)==0),recency)'));
        recencyfrac3{a}{e} = cellfun(@(x) x(x(:,1)==-3 & x(:,5)==0,3),recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-3 & x(:,5)==0),recency)'));
        recencyfrac4{a}{e} = cellfun(@(x) x(x(:,1)==-4 & x(:,5)==0,3),recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-4 & x(:,5)==0),recency)'));
        %recencyfrac5p{a}{e} = cell2mat(cellfun(@(x) x(x(:,1)<=-5 & x(:,5)==0,3)',recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)<=-5 & x(:,5)==0),recency)'),'un',0));
        recencyfrac5p{a}{e} = cell2mat(cellfun(@(x) x(x(:,1)==-5 & x(:,5)==0,3)',recency(tphasenum(:,1)<=1 & cellfun(@(x) any(x(:,1)==-5 & x(:,5)==0),recency)'),'un',0));
    
        tmp = recency(tphasenum(:,1)<=1); tmp = vertcat(tmp{:});
        searchrecencies{a}{e} = tmp(tmp(:,5)==0 & ~isnan(tmp(:,1)),[1 3]);
        % what fraction of possible pgreplay prevgoal visits are preceded by a replay pgvisit = [pgvis pgreplay futurereplay]
        % fraction of pg visits with replay compared to fraction of other visits with pgreplay = similar chance of pgreplay whether your about to  visit it or not
        %[fracpgvis with replay/totalpgvis, othervis with pgreplay/possiblepgvis. nonpgfuturerep/nonpgvistrials
        fracpg{a}(e,:) = [sum(pgvisit(:,3)>0 & pgvisit(:,1)>0)/sum(pgvisit(:,1)>0), sum(pgvisit(:,2)==1 &  pgvisit(:,1)==0)/sum(pgvisit(:,1)==0)]; %, sum(pgvisit(:,3)>0 & pgvisit(:,1)~=1)/sum(pgvisit(:,1)~=1) don't bother with overall futurefrac
    end

    figure(bars)
    subplot(2,4,a); hold on; %boxplot(recencyfrac{a},'Color',animcol(a,:),'Symbol','','Notch','on')
    % by session
    %errorbar(1:5, nanmean(recencyfrac{a}),nanstd(recencyfrac{a})/sqrt(length(eps)),'Color',animcol(a,:),'Linestyle','none');
    %bar(1:5, nanmean(recencyfrac{a}),.5,'Facecolor',animcol(a,:)  );
    % pooled actoss sessions
    errorbar(1:5,[nanmean(horzcat(recencyfrac1{a}{:})),nanmean(horzcat(recencyfrac2{a}{:})),nanmean(horzcat(recencyfrac3{a}{:})),nanmean(horzcat(recencyfrac4{a}{:})),nanmean(horzcat(recencyfrac5p{a}{:}))], ...
        [nanstd(horzcat(recencyfrac1{a}{:})),nanstd(horzcat(recencyfrac2{a}{:})),nanstd(horzcat(recencyfrac3{a}{:})),nanstd(horzcat(recencyfrac4{a}{:})),nanstd(horzcat(recencyfrac5p{a}{:}))]./ ...
        sqrt([length(horzcat(recencyfrac1{a}{:})),length(horzcat(recencyfrac2{a}{:})),length(horzcat(recencyfrac3{a}{:})),length(horzcat(recencyfrac4{a}{:})),length(horzcat(recencyfrac5p{a}{:}))]),'k.');
    bar(1:5,[nanmean(horzcat(recencyfrac1{a}{:})),nanmean(horzcat(recencyfrac2{a}{:})),nanmean(horzcat(recencyfrac3{a}{:})),nanmean(horzcat(recencyfrac4{a}{:})),nanmean(horzcat(recencyfrac5p{a}{:}))],.5,'FaceColor',animcol(a,:));
    for r = 1:4
       % [p{a}(r),~]=ranksum(recencyfrac{a}(:,r),recencyfrac{a}(:,5));  % by sesssion
        eval(sprintf('tmp=horzcat(recencyfrac%d{a}{:});',r))
        [p{a}(r),~]=ranksum(tmp,horzcat(recencyfrac5p{a}{:})); 
    end
    text([1:4],[.5 .6 .7 .8],num2str(p{a}','%.03f')); ylim([0 1]); ylabel('replayrate'); xlabel('recency'); xlim([0 6]);
    text(1,.2,num2str([length(horzcat(recencyfrac1{a}{:})),length(horzcat(recencyfrac2{a}{:})),length(horzcat(recencyfrac3{a}{:})),length(horzcat(recencyfrac4{a}{:})),length(horzcat(recencyfrac5p{a}{:}))])); 
    title('pooled over eps, just 1-5')
    subplot(2,4,a+4); hold on;  allrec = vertcat(searchrecencies{a}{:});
    [meanrec, semrec,numelrec] = grpstats(allrec(:,2),allrec(:,1),{'mean','sem','numel'});
    grp = unique(allrec(:,1));
    h = fill([grp(numelrec>20)', fliplr(grp(numelrec>20)')], [meanrec(numelrec>20)'-semrec(numelrec>20)', fliplr(meanrec(numelrec>20)'+semrec(numelrec>20)')],animcol(a,:),'FaceAlpha',.3);%
    set(h,'EdgeColor','none'); plot(grp(numelrec>20), meanrec(numelrec>20),'.-','Color',animcol(a,:),'Linewidth',1); 
 
    %plot(grp(end-10:end),meanrec(end-10:end),'.','Color',animcol(a,:));
    [r,pc] = corrcoef(allrec(allrec(:,1)>=-5,1),allrec(allrec(:,1)>=-5,2));
    text(-25,.2,sprintf('for 1-5 only: r2 = %.03f,\np=%d',r(2)^2, pc(2)));
    
    figure(reg); hold on;
    subplot(1,4,a); hold on;
    %boxplot(fracpg{a},'Color',animcol(a,:),'Symbol','','Notch','on')
    errorbar([0 .5], nanmean(fracpg{a}),nanstd(fracpg{a})/sqrt(length(eps)),'k.');
    bar([0 .5], nanmean(fracpg{a}),'Facecolor',animcol(a,:)  );
    p{a} = [ranksum(fracpg{a}(:,1),fracpg{a}(:,2))]; %,ranksum(fracpg{a}(:,1),fracpg{a}(:,3))
    text(0,.9,num2str(p{a}')); ylim([0 1]); set(gca, 'xticklabel',{'','pgvisit','othervisit',''}); ylabel('frac of trials with pgreplay');


end
%figure(bars);
% title('pgvisitswithpgreplay, othervisitswithpgreplay, othervisitswithfuturereplay'); 
%  figure(reg)
%  subplot(1,2,1); xlim([0 30]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:29],'XTickLabel',{'intrcpt','1','2','3','4','5+'})
% plot([0 30],[1 1],'k:'); set(gca,'YScale','log'); ylim([.4 3]);
% subplot(1,2,2); xlim([0 30]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:29],'XTickLabel',{'intrcpt','1','2','3','4','5+'})
% plot([0 30],[1 1],'k:'); set(gca,'YScale','log'); ylim([.4 3]);

%plot4a(fracpg,'gnames',{'pgvisitwithrep','otherviswithpgrep','nonpgvisfuturerep'}); ylim([0 1])
 
%% Compare replay on  correct/incorrect (repeat only)  (used to be GLM to predict corr/err) [FIG 4C and SUP FIG 5 B,C]
clearvars -except f animals animcol
contentthresh = .3;
dists = figure(); set(gcf,'Position',[675 1 974 973]); scat = figure(); glms = figure();
reps = 100;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x;y;z],hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);   
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1' & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}==1 & maxval>contentthresh;
                outerreplays{t} = ind(valid)'-1; %
            else outerreplays{t} = []; end
        end
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        goals(mod(tphasenum(:,1),1)>.85,:) = goals(find(mod(tphasenum(:,1),1)>.85)-1,:); % fix the last visit of cont (.9) to not reflect new goal yet
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        countspertrial = zeros(length(outers),4);
        valtrials = ~cellfun(@isempty,replays);
        countspertrial(valtrials,:) = cell2mat(cellfun(@(x,fut,pst,crg,prg) [sum(x==fut), sum(x==pst), sum(x==crg), sum(x==prg)], ...
                    replays(valtrials),num2cell(outers(valtrials)),num2cell(pastwlock(valtrials))',num2cell(goals(valtrials,1)'),...
                    num2cell(goals(valtrials,2))','un',0)'); 
        valtrials = tphasenum(:,1)>1 ; %& ~isnan(goals(:,2))
        % [future past currg prevg correct/err early/late goalnum]
        allrep{a}{e} = [countspertrial(valtrials,:), (mod(tphasenum(valtrials,1),1)==0 |mod(tphasenum(valtrials,1),1)>.85),tphasenum(valtrials,1)<5, tphasenum(valtrials,1)];   
    end
    repcat = vertcat(allrep{a}{:});
    %repcat(:,5) = repcat(randperm(size(repcat,1)),5);  % for shufffle
    corr = repcat(repcat(:,5)==1,:);
    folds = 5;
    for r = 1:reps
        subsamp = [repcat(repcat(:,5)==0,:);corr(randperm(size(corr,1),sum(repcat(:,5)==0)),:)]; %match number of corr and err trials
        cv = cvpartition(size(subsamp,1),'kfold',folds);
        %cv = cvpartition(size(repcat,1),'kfold',folds);
        for k = 1:folds
            %mdl_int = fitglm(repcat(cv.training(k),1),repcat(cv.training(k),5),'constant','Distribution','binomial');
            %sim_int = random(mdl_int,repcat(cv.test(k),1));
            mdl = fitglm(subsamp(cv.training(k),1),subsamp(cv.training(k),5),'linear','Distribution','binomial');
            sim = random(mdl,subsamp(cv.test(k),1));
            tmp_future(r,k) = mean(sim~=subsamp(cv.test(k),5)); %-mean(sim_int==subsamp(cv.test(k),5))
            mdl = fitglm(subsamp(cv.training(k),3),subsamp(cv.training(k),5),'linear','Distribution','binomial');
            sim = random(mdl,subsamp(cv.test(k),3));
            tmp_cg(r,k) = mean(sim~=subsamp(cv.test(k),5)); %-mean(sim_int==subsamp(cv.test(k),5))
            mdl = fitglm(subsamp(cv.training(k),[1:4]),subsamp(cv.training(k),5),'linear','Distribution','binomial');
            sim = random(mdl,subsamp(cv.test(k),[1:4]));
            tmp_all(r,k) = mean(sim~=subsamp(cv.test(k),5)); %-mean(sim_int==subsamp(cv.test(k),5))
            %mdl = fitglm(subsamp(cv.training(k),8),subsamp(cv.training(k),5),'linear','Distribution','binomial');
            %sim = random(mdl,subsamp(cv.test(k),8));
            %tmp_ripno(r,k) = mean(sim~=subsamp(cv.test(k),5)); %-mean(sim_int==subsamp(cv.test(k),5))
        end
        
    end
    mcr_future{a} = mean(tmp_future,2);
    mcr_cg{a} = mean(tmp_cg,2);
    mcr_all{a} = mean(tmp_all,2);
    %mcr_ripno{a} = mean(tmp_ripno,2);
    %mcr_future{a} = reshape(tmp_future,[],1);
    %mcr_cg{a} = reshape(tmp_cg,[],1);
    %mcr_all{a} = reshape(tmp_all,[],1);
    ci99 = tinv([.005 .995],reps-1); 
    mcr_futureCI = (std(mcr_future{a})/sqrt(reps))*ci99; %reps*
    mcr_cgCI = (std(mcr_cg{a})/sqrt(reps))*ci99; %reps*
    mcr_allCI = (std(mcr_all{a})/sqrt(reps))*ci99; %reps*
    %mcr_ripnoCI = (std(mcr_ripno{a})/sqrt(reps))*ci99; %reps*

    figure(glms); hold on;
    plot(a+[0 5 10],[mean(mcr_future{a}) mean(mcr_cg{a}) mean(mcr_all{a})],'.','MarkerSize',20,'Color',animcol(a,:));
    plot(repmat(a+[0 5 10],2,1),[mean(mcr_future{a})+mcr_futureCI' mean(mcr_cg{a})+mcr_cgCI' mean(mcr_all{a})+mcr_allCI'],'Color',animcol(a,:));
    
    figure(dists);
    subplot(2,4,a);hold on; title('future (incl1stcont) early and late')
    earlycorr = repcat(:,5)==1 & repcat(:,6)==1;
    latecorr = repcat(:,5)==1 & repcat(:,6)==0;
    earlyerr = repcat(:,5)==0 & repcat(:,6)==1;
    lateerr = repcat(:,5)==0 & repcat(:,6)==0;
    
    errorbar(a+[0 .3],[mean(repcat(earlycorr|latecorr,1)),mean(repcat(earlyerr|lateerr,1))],[std(repcat(earlycorr|latecorr,1))./sqrt(sum(earlycorr|latecorr)), std(repcat(earlyerr|lateerr,1))./sqrt(sum(earlyerr|lateerr))],'k.');
    bar(a+[0 .3],[mean(repcat(earlycorr|latecorr,1)),mean(repcat(earlyerr|lateerr,1))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcat(earlycorr|latecorr,1),repcat(earlyerr|lateerr,1)),sum(earlycorr|latecorr),sum(earlyerr|lateerr));
    text(a,1.5,wrds);  ylim([0 2])
  
    %edges = [0:5];
    %bar([1,2],[histcounts(repcat(earlycorr,1),edges,'Normalization','probability'); histcounts(repcat(earlyerr,1),edges,'Normalization','probability')],'stacked') %,.3,'FaceColor',animcol(a,:));
    %[h,p]=kstest2(repcat(earlycorr,1),repcat(earlyerr,1));
    %wrds = sprintf('kstest\np=%.03f\nn=%d,%d',p,sum(earlycorr),sum(earlyerr));
    %text(1,.4,wrds);  %ylim([0 .8]); xlim([-.5 4.5]); set(gca,'yTick',[0:.2:.8])
    subplot(2,4,a+4);hold on; title('currgoal early and late')
    errorbar(a+[0 .3],[mean(repcat(earlycorr|latecorr,3)),mean(repcat(earlyerr|lateerr,3))],[std(repcat(earlycorr|latecorr,3))./sqrt(sum(earlycorr|latecorr)), std(repcat(earlyerr|lateerr,3))./sqrt(sum(earlyerr|lateerr))],'k.');
    bar(a+[0 .3],[mean(repcat(earlycorr|latecorr,3)),mean(repcat(earlyerr|lateerr,3))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcat(earlycorr|latecorr,3),repcat(earlyerr|lateerr,3)),sum(earlycorr|latecorr),sum(earlyerr|lateerr));
    text(a,1.5,wrds);  ylim([0 2])
  
    

end
figure(glms); plot([0 15],[.5 .5],'k:'); ylim([.3 .7])
set(gca,'xTick',[2 7 12],'xTicklabel',{'future','cg','all'})
title('5xval x 100reps for supsamp=500df'); ylabel('misclassification rate')
%subplot(3,4,[9 10]); plot([0 5],[.5 .5],'k:'); ylim([0 1]); title('future only'); ylabel('misclassification rate')
%subplot(3,4,[11 12]); plot([0 5],[.5 .5],'k:'); ylim([0 1]); title('currgoal only'); xlabel('99% CI')

%5testdata = [randi([1 12],100,1),zeros(100,1); randi([10 22],100,1),ones(100,1)];
