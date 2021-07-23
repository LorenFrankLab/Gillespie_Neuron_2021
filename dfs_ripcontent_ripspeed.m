%% Sungod manu: calculate rip speed and use to sepearate outbound from inbound trajectories
%this is just the same as dfs_ripcontent with extra speed info for each rip (useful for determining inbound/outbound)

animals = {'jaq','roquefort','despereaux','montague'};  %,, 'remy',};%};

epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0 & $gooddecode==1']; % & $decode_error<=1
%epochfilter{1} = ['$session==27'];

% resultant excludeperiods will define times when velocity is high
timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
iterator = 'epochbehaveanal';

for a = 1:length(animals)
    
    f(a) = createfilter('animal',animals{a},'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
    f(a) = setfilterfunction(f(a), 'dfa_ripcontent_ripspeed', {'ripdecodesv3','trials','pos'},'animal',animals{a});  
    f(a) = runfilter(f(a));

end
 
animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols
%save('/media/anna/whirlwindtemp2/ffresults/ctrl_ripcontent_ripspeed.mat','f','-v7.3')

%load('/media/anna/whirlwindtemp2/ffresults/ctrl_ripcontent_ripspeed.mat')

%% plot fraction coherent, local, salient, overall and by trial phase and taskphase [2F,3A]
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
contentthresh = .2;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
   
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        homespds = f(a).output{1}(eps(e)).trips.homeripspeed(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rwspds = f(a).output{1}(eps(e)).trips.RWripspeed(valtrials);
        postrwspds = f(a).output{1}(eps(e)).trips.postRWripspeed(valtrials);
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x;y;z],hometypes,rwtypes,postrwtypes,'un',0);
        spds = cellfun(@(x,y,z) [x;y;z],homespds,rwspds,postrwspds,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials); %
        outerspds = f(a).output{1}(eps(e)).trips.outerripspeed(valtrials);
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        goals(tphasenum(:,1)<=1,1) = nan; % turn currgoals during search trials into nans
        goals(goals(:,1)==0,1) = nan;
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        trialstack  = [outers', pastwlock, goals,tphasenum(:,1)];
        clear replays outerreplays 
        % salient - can be past, future, or any previously rewarded arm OR just any previously rewarded arm (p/f not salient)(as for FIG7A)
        for t=1:length(rips)  % extract valid rips and tack on trial info: [replay future past currgoal prevgoal ppgoal tphase salient local TYPE(cont/stat)]
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh; 
                box1armonly = max(rips{t}(valid,2:end),[],2)>contentthresh & rips{t}(valid,1)>contentthresh ; %& sum(rips{t}(valid,2:end)>contentthresh,2)==1
                % [arm trialstack local speed box1armonly]
                replays{t} =[ind(valid)-1,repmat(trialstack(t,:),sum(valid),1),ind(valid)-1==0,spds{t}(valid),box1armonly];
            else replays{t} = []; end
%             if ~isempty(outerrips{t})   % box is considered salient in option 1, not in option 2
%                 [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
%                 valid = outertypes{t}==1 & maxval>contentthresh;
%                 %outerreplays{t} = [ind(valid)-1,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[0,trialstack(t,1:2),unique(goals(1:t,1))']),ind(valid)-1==trialstack(t,1)]; % include box as salient
%                 outerreplays{t} = [ind(valid)-1,repmat(trialstack(t,:),sum(valid),1), ismember(ind(valid)-1,[unique(goals(1:t,1))']),ind(valid)-1==trialstack(t,1),outerspds{t}(valid)]; % include box as salient
%                 if any(valid)
%                     outerreplays{t}(outerreplays{t}(:,9)==1,8) = 0; % correct salience to not include local events
%                 end
%             else outerreplays{t} = []; end
        end
        allbox{a}{e} = vertcat(replays{:});
        frac_outbound_ofremote{a}(e,1) = sum(allbox{a}{e}(:,8)==0 & allbox{a}{e}(:,9)>0)/sum(allbox{a}{e}(:,8)==0); 
        frac_boxarm_ofremote{a}(e,1) = sum(allbox{a}{e}(:,8)==0 & allbox{a}{e}(:,9)>0 & allbox{a}{e}(:,10)==1)/sum(allbox{a}{e}(:,8)==0); 
    end

    subplot(2,4,a); histogram(cell2mat(cellfun(@(x) x(x(:,8)==1,9)',allbox{a},'un',0)),[-1000:50:1000],'Normalization','probability','FaceColor',animcol(a,:)); title('local')
    subplot(2,4,a+4); histogram(cell2mat(cellfun(@(x) x(x(:,8)==0,9)',allbox{a},'un',0)),[-1000:50:1000],'Normalization','probability','FaceColor',animcol(a,:)); title('remote')

end
% legend({'box local cont','box local stat','box remote cont','box remote stat','outer local','outer box','outer remotearm'})

%subplot(1,2,1); bar(horzcat(boxfracs{:})','stacked'); title('box replays'); legend({'local','salient','nonsalient'}); ylim([0 1]); ylabel('fraction of coherent SWRs')
%subplot(1,2,2); bar(horzcat(outerfracs{:})','stacked'); title('outer replays'); legend({'local','box','salient','nonsalient'}); xlabel('subject')
figure;
subplot(1,2,1); hold on; plot4a(frac_outbound_ofremote,'gnames',{'outbound'}); ylim([0 1]); title('out of all remote'); ylabel('frac of all events')
subplot(1,2,2); hold on; plot4a(frac_boxarm_ofremote,'gnames',{'boxarm'}); ylim([0 1]); title('out of all remote')
% text([6:9],[.6 .7 .8 .9],num2str(cellfun(@(x) mean(x),fracremoteall)','%.04f')); text([7:10],[.6 .7 .8 .9],num2str(cellfun(@length,fracremoteall)'))
% subplot(3,3,3); hold on; plot4a(fracsalientall,'gnames',{'salient'}); ylim([0 1]); title('out of all remote')
% subplot(3,3,4); hold on; plot4a(fraccohbyphase,'gnames',{'home','rw','postrw','outer'}); ylim([0 1]); title('coherent'); ylabel('frac of all events')
% subplot(3,3,5); hold on; plot4a(fracremotebyphase,'gnames',{'home','rw','postrw','outer'}); ylim([0 1]); title('remote out of all coh')
% subplot(3,3,6); hold on; plot4a(fracsalientbyphase,'gnames',{'home','rw','postrw','outer'}); ylim([0 1]); title('salient')
% subplot(3,3,7); hold on; plot4a(fraccohboxouter,'gnames',{'box','outer'}); ylim([0 1]); title('coherent'); ylabel('frac of all events')
% subplot(3,3,8); hold on; plot4a(fracremoteboxouter,'gnames',{'box','outer'}); ylim([0 1]); title('remote out of all coh')
% subplot(3,3,9); hold on; plot4a(searchonly_fracNONsalientboxouter,'gnames',{'box'}); ylim([0 1]); title('NOT salient(prevrewarded) of out of all rem')

%% fit linear model of category predictors for each arm, for box and outer  [FIG 3D,E and FIG 4 A,B and FIG 7B]
clearvars -except f animals animcol
contentthresh = .2;
all = figure();
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        homespds = f(a).output{1}(eps(e)).trips.homeripspeed(valtrials);
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rwspds = f(a).output{1}(eps(e)).trips.RWripspeed(valtrials);
        postrwspds = f(a).output{1}(eps(e)).trips.postRWripspeed(valtrials);
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x;y;z],hometypes,rwtypes,postrwtypes,'un',0);
        spds = cellfun(@(x,y,z) [x;y;z],homespds,rwspds,postrwspds,'un',0);       
        clear replays outerreplays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh; % 
                box1armonly = max(rips{t}(:,2:end),[],2)>contentthresh & rips{t}(:,1)>contentthresh & spds{t}>0; % %& sum(rips{t}(:,2:end)>contentthresh,2)==1
                % [arm trialstack local speed box1armonly]
                replays{t} =[ind(valid & box1armonly)-1];
             else replays{t} = []; end
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
        
        % for correct vs error: [future past currg prevg correct/err early/late goalnum]
        valtrials = ~cellfun(@isempty,replays);
        othercountspertrial = zeros(length(valtrials),4);
        othercountspertrial(valtrials,:) = cell2mat(cellfun(@(x,fut,pst,crg,prg) [sum(x==fut), sum(x==pst), sum(x==crg), sum(x==prg)], ...
                    replays(valtrials),num2cell(outers(valtrials)),num2cell(pastwlock(valtrials))',num2cell(goals(valtrials,1)'),...
                    num2cell(goals(valtrials,2))','un',0)'); 
        valtrials = tphasenum(:,1)>1 & ~isnan(goals(:,2)); 
        corrvserrcounts{a}{e} = [othercountspertrial(valtrials,:), (mod(tphasenum(valtrials,1),1)==0 |mod(tphasenum(valtrials,1),1)>.85),tphasenum(valtrials,1)<5, tphasenum(valtrials,1)];   

    end
    figure(all);
    searchcat = vertcat(allsearch{a}{:});
    searchtbl = table(searchcat(:,2),searchcat(:,1),searchcat(:,3),searchcat(:,4),'VariableNames',{'past','future','prevgoal','replaynum'});
    s_mdl = fitglm(searchtbl,'linear','Distribution','poisson');
    CI = coefCI(s_mdl,.01);
    subplot(2,2,1); hold on; title('allsearch')
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
    subplot(2,2,2); hold on; title('allrepeat')
    %errorbar(a+[0:5:24],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
    plot(a+[0:5:24],exp(table2array(r_mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:));
    %cr = [corrcoef(repeatcat(:,1),repeatcat(:,2)), corrcoef(repeatcat(:,1),repeatcat(:,3)),corrcoef(repeatcat(:,1),repeatcat(:,4)), ...
    %    corrcoef(repeatcat(:,2),repeatcat(:,3)), corrcoef(repeatcat(:,2),repeatcat(:,4)),corrcoef(repeatcat(:,3),repeatcat(:,4))];
    %repr2(a,:)=cr(1,[2:2:12]).^2;
    %text(5,2+.2*a,['f vs cg corrcoef=',num2str(cr(2),'%.03f')],'Color',animcol(a,:));
    text(5,2+.2*a,['trial n=',num2str(size(repeatcat,1)/8)],'Color',animcol(a,:));
%     outercat = vertcat(allouterrew{a}{:});
%     mdl = fitglm(outercat(:,1:3),outercat(:,4),'linear','Distribution','poisson'); 
%     CI = coefCI(mdl,.01);
%     subplot(1,3,3); hold on; title('outer rewarded')
%     plot(a+[0:5:19],exp(table2array(mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a+[0:5:19];a+[0:5:19]],exp(CI)','Color',animcol(a,:));
%     text(5,2+.2*a,['trial n=',num2str(size(outercat,1)/8)],'Color',animcol(a,:));
    %for corr vs err
    repcounts = vertcat(corrvserrcounts{a}{:}); %[future past currg prevg correct/err early/late goalnum]
    subplot(2,2,3); hold on;
    errorbar(a+[0 .3],[mean(repcounts(repcounts(:,5)==1,1)),mean(repcounts(repcounts(:,5)==0,1))],[std(repcounts(repcounts(:,5)==1,1))./sqrt(sum(repcounts(:,5)==1)), std(repcounts(repcounts(:,5)==0,1))./sqrt(sum(repcounts(:,5)==0))],'k.');
    bar(a+[0 .3],[mean(repcounts(repcounts(:,5)==1,1)),mean(repcounts(repcounts(:,5)==0,1))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcounts(repcounts(:,5)==1,1),repcounts(repcounts(:,5)==0,1)),sum(repcounts(:,5)==1),sum(repcounts(:,5)==0));
    text(a,.8,wrds);  ylim([0 1]); title('outbound boxarmtraj future num')
    subplot(2,2,4); hold on;
    errorbar(a+[0 .3],[mean(repcounts(repcounts(:,5)==1,3)),mean(repcounts(repcounts(:,5)==0,3))],[std(repcounts(repcounts(:,5)==1,3))./sqrt(sum(repcounts(:,5)==1)), std(repcounts(repcounts(:,5)==0,3))./sqrt(sum(repcounts(:,5)==0))],'k.');
    bar(a+[0 .3],[mean(repcounts(repcounts(:,5)==1,3)),mean(repcounts(repcounts(:,5)==0,3))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(repcounts(repcounts(:,5)==1,3),repcounts(repcounts(:,5)==0,3)),sum(repcounts(:,5)==1),sum(repcounts(:,5)==0));
    text(a,.8,wrds);  ylim([0 1]); title('outbound boxarmtraj currgoal num')      
end
figure(all)
subplot(2,2,1); xlim([0 20]); ylabel('exp(beta)'); set(gca,'XTick',2+[0:5:19],'XTickLabel',{'intrcpt','past','future','prevgoal'})
plot([0 20],[1 1],'k:'); set(gca,'YScale','log'); ylim([.4 3]);
subplot(2,2,2); set(gca,'YScale','log'); ylim([.4 3]); xlim([0 25]);set(gca,'XTick',2+[0:5:24],'XTickLabel',{'intrcpt','past','future','curgoal','prevgoal'})
plot([0 25],[1 1],'k:');
% subplot(1,3,3); set(gca,'YScale','log'); ylim([.7 20]); xlim([0 20]);set(gca,'XTick',2+[0:5:20],'XTickLabel',{'intrcpt','past','current','prevgoal'})
% plot([0 20],[1 1],'k:'); ylabel('[.7 20]')



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
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials);   
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
  
    
    %bar([4,5], [histcounts(repcat(latecorr,1),edges,'Normalization','probability'); histcounts(repcat(lateerr,1),edges,'Normalization','probability')],'stacked') %,.3,'FaceColor',animcol(a,:));
    %bar(edges(1:end-1)-.2,histcounts(repcat(latecorr,1),edges,'Normalization','probability'),.3,'FaceColor',animcol(a,:));
    %bar(edges(1:end-1)+.2, histcounts(repcat(lateerr,1),edges,'Normalization','probability'),.3,'FaceColor',animcol(a,:),'FaceAlpha',.3)
    %[h,p]=kstest2(repcat(latecorr,1),repcat(lateerr,1));
    %wrds = sprintf('kstest\np=%.03f\nn=%d,%d',p,sum(latecorr),sum(lateerr));
    %text(4,.4,wrds); %ylim([0 .8]); xlim([-.5 4.5]); 
    %subplot(2,4,a+4);hold on; title('currgoal ')
    %bar([1,2],[histcounts(repcat(earlycorr,3),edges,'Normalization','probability'); histcounts(repcat(earlyerr,3),edges,'Normalization','probability')],'stacked') %,.3,'FaceColor',animcol(a,:));
    %bar(edges(1:end-1)-.2,histcounts(repcat(earlycorr,3),edges,'Normalization','probability'),.3,'FaceColor',animcol(a,:));
    %bar(edges(1:end-1)+.2, histcounts(repcat(earlyerr,3),edges,'Normalization','probability'),.3,'FaceColor',animcol(a,:),'FaceAlpha',.3)
    %[h,p]=kstest2(repcat(earlycorr,3),repcat(earlyerr,3));
    %wrds = sprintf('kstest\np=%.03f\nn=%d,%d',p,sum(earlycorr),sum(earlyerr));
    %text(1,.4,wrds); % xlim([-.5 4.5]); set(gca,'yTick',[0:.2:.8]); ylim([0 .8]);
    %subplot(4,4,a+12);hold on; title('currgoal late')
    %bar([4 5],[histcounts(repcat(latecorr,3),edges,'Normalization','probability'); histcounts(repcat(lateerr,3),edges,'Normalization','probability')],'stacked') %,.3,'FaceColor',animcol(a,:));
    %bar(edges(1:end-1)-.2,histcounts(repcat(latecorr,3),edges,'Normalization','probability'),.3,'FaceColor',animcol(a,:));
    %bar(edges(1:end-1)+.2, histcounts(repcat(lateerr,3),edges,'Normalization','probability'),.3,'FaceColor',animcol(a,:),'FaceAlpha',.3)
    %[h,p]=kstest2(repcat(latecorr,1),repcat(lateerr,3));
    %wrds = sprintf('kstest\np=%.03f\nn=%d,%d',p,sum(latecorr),sum(lateerr));
    %text(4,.4,wrds); set(gca,'xTick',[1 2 4 5],'xTicklabel',{'earlycor','earlyerr','latecorr','lateerr'}) % ylim([0 .8]); xlim([-.5 4.5]); ylabel('frac trials'); xlabel('#replays'); set(gca,'yTick',[0:.2:.8])
    
%     figure(scat); hold on;
%     ints = 2:16;
%     [means,sds,counts] = grpstats(repcat(repcat(:,5)==1,3),ceil(repcat(repcat(:,5)==1,7)),{'mean','std','numel'});
%     plot(ints(counts>=10),means(counts>=10),'.','Color',animcol(a,:));lsline %plot([2:16;2:16],[means+sds, means-sds]','Color',animcol(a,:));
%     [r,p] = corrcoef(repcat(repcat(:,5)==1,3),ceil(repcat(repcat(:,5)==1,7)));
%     wrds = sprintf('r2=%.03f,p=%.07f,n=%d range %d-%d',r(2)^2,p(2),sum(repcat(:,5)==1),min(counts(counts>=10)),max(counts));
%     text(1,1+a/5,wrds,'Color',animcol(a,:)); ylim([0 2]); ylabel('goal replay rate'); xlabel('visit #'); title('corronly, >=10 trials')

    %       subplot(3,4,[9 10]);hold on;
%     plot(a,mean(mcr_future),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a;a],mean(mcr_future)+mcr_futureCI','Color',animcol(a,:));
%     text(a,.6+a/15,['n=',num2str(size(subsamp,1))]);
%     subplot(3,4,[11 12]); hold on;
%     plot(a,mean(mcr_cg),'.','MarkerSize',20,'Color',animcol(a,:));
%     plot([a;a],mean(mcr_cg)+mcr_cgCI','Color',animcol(a,:));

end
figure(glms); plot([0 15],[.5 .5],'k:'); ylim([.3 .7])
set(gca,'xTick',[2 7 12],'xTicklabel',{'future','cg','all'})
title('5xval x 100reps for supsamp=500df'); ylabel('misclassification rate')
%subplot(3,4,[9 10]); plot([0 5],[.5 .5],'k:'); ylim([0 1]); title('future only'); ylabel('misclassification rate')
%subplot(3,4,[11 12]); plot([0 5],[.5 .5],'k:'); ylim([0 1]); title('currgoal only'); xlabel('99% CI')

%5testdata = [randi([1 12],100,1),zeros(100,1); randi([10 22],100,1),ones(100,1)];



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
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        clear replays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
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

%% epochwise boxplot version of violins [OUTER]  [Fig 7]
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
reps = 100;
mintrials=5;
contentthresh=.3;
for a = 1:length(animals)
    %figure; set(gcf,'Position',[1008 1009 663 833]);
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        rips = f(a).output{1}(eps(e)).trips.outerripcontent;
        types = f(a).output{1}(eps(e)).trips.outerripmaxtypes; %
        goals = f(a).output{1}(eps(e)).trips.goalarm;
        outers = f(a).output{1}(eps(e)).trips.outerarm;
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(:,2);  % only consider the including lockout option
        tphasenum = [f(a).output{1}(eps(e)).trips.taskphase, [1:length(goals)]'];   % add trial numbers
        clear replays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}'==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
            else replays{t} = []; end
        end   
        valtrials = ~cellfun(@isempty, replays);
        if any(valtrials)
            ripcomb = cellfun(@(x,y,z,g,h) [x', repmat([y,z,g,h],length(x),1)], replays(valtrials), num2cell(outers(valtrials)), ...
                num2cell(pastwlock(valtrials))', num2cell(goals(valtrials,:),2)',num2cell(tphasenum(valtrials,:),2)','un',0);
            ripcomb = vertcat(ripcomb{:});
            %salient - past or previously rewarded arms only, not box/future
        salient = ~(ripcomb(:,1)==ripcomb(:,2)) & (ripcomb(:,1)==ripcomb(:,3) | table2array(rowfun(@(x) ismember(x(1),goals(1:x(8),1)),table(ripcomb))));
        contentfracs{a}(e,:) = [length(vertcat(rips{:}))-size(ripcomb,1), sum(ripcomb(:,1)==ripcomb(:,2)), sum(ripcomb(:,1)==0), sum(salient), sum(ripcomb(:,1)~=ripcomb(:,2) & ripcomb(:,1)>0 & ~salient)]./length(vertcat(rips{:}));
        nonlocal = ripcomb(ripcomb(:,1)~=ripcomb(:,2),:);  % get rid of local events
        nonlocal(:,9) = zeros(size(nonlocal,1),1); % add a new column for future: box (zeros) in addition to current location
        trialfracs{a}(e,:) = [sum(~valtrials' & tphasenum(:,1)>=1), sum(valtrials' & tphasenum(:,1)>=1)-length(unique(nonlocal(:,8))),length(unique(nonlocal(:,8)))]/sum(tphasenum(:,1)>=1); % of repeat trials, fractrials no replay, frac local only, frac with nonlocal , 

        % all ripples during repeat trials; future=box, past=currarm/goal vs prevgoal 
        %repeat = nonlocal((nonlocal(:,7) >= 1 &  ~isnan(nonlocal(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        repeat = ripcomb((ripcomb(:,7) >= 1 &  ~isnan(ripcomb(:,5))),:); %~isnan(abovethresh(:,4)) & & ~isnan(abovethresh(:,6))
        alluniqueinds = repeat(:,2)==repeat(:,3) & repeat(:,3)==repeat(:,4) & repeat(:,4)~=repeat(:,5);
        allunique = repeat(alluniqueinds,:); %
        if length(unique(allunique(:,8)))>=1
            rep1_pcg{a}(e) = sum(allunique(:,1)==allunique(:,3))/sum(allunique(:,1)>=0);
            rep1_prevgoal{a}(e) = sum(allunique(:,1)==allunique(:,5))/sum(allunique(:,1)>=0);
            rep1_other{a}(e) = sum(allunique(:,1)>0 & allunique(:,1)~=allunique(:,2) & allunique(:,1)~=allunique(:,5))/6/sum(allunique(:,1)>=0);
            rep1_box{a}(e) = sum(allunique(:,1)==0)/sum(allunique(:,1)>=0);
            for r = 1:reps
                randlist = randi([1 8],size(allunique,1),1);
                rep1_randshuff{a}(e,r) = sum(allunique(:,1)==randlist)/sum(allunique(:,1)>=0);
           end
        end
        rep1_rtcounts{a}(e,:) = [size(allunique,1), length(unique(allunique(:,8))), sum(tphasenum(:,1)>=1)];  % #rips #trials #totalreptrials
                
        end
    end
    repcomb{a} = [rep1_pcg{a}(rep1_rtcounts{a}(:,2)>=mintrials)' rep1_prevgoal{a}(rep1_rtcounts{a}(:,2)>=mintrials)' rep1_other{a}(rep1_rtcounts{a}(:,2)>=mintrials)' rep1_box{a}(rep1_rtcounts{a}(:,2)>=mintrials)'];
    repshuffcomb{a} = reshape(rep1_randshuff{a}(rep1_rtcounts{a}(:,2)>=mintrials,:),[],1); 
    
    %rep_p{a} = [ranksum(repcomb{a}(:,1),repshuffcomb{a}),ranksum(repcomb{a}(:,2),repshuffcomb{a}),ranksum(repcomb{a}(:,3),repshuffcomb{a})];
end
%subplot(1,8,1); ylabel('frac of replay events')
%plot4a(repshuffcomb,'gnames',{'null'}); ylim([0 1]); text(6,.4,num2str(cellfun(@(x) sum(x(:,2)>=mintrials),rep1_rtcounts))); ylim([0 1])
subplot(1,8,[2 3 4]); hold on; title('outer rep')
plot4a(repcomb,'gnames',{'f/past/cg','pg','other','box'});
%text(16,.7,num2str(vertcat(rep_p{:})))
ylim([0 1])

%figure; %plot4a(contentfracs,'gnames',{'incoh','localarm','box','salient','other'}); ylim([0 .75]); title('outer replays')
subplot(1,8,[5 6]); plot4a(trialfracs,'gnames',{'norips','localonly','hasremote'}); ylim([0 1]); title('repeat frac norips/localonly')


%% plot ripple features (size, duration, instfreq, spikerate, numtets) split by cont/frag and by local/remote and corr/err
clearvars -except f animals animcol
bytet = load('/media/anna/whirlwindtemp2/ffresults/ctrl_instfreqspikes.mat');
bars = figure(); set(gcf,'Position',[66 305 1853 551]);
contentthresh = .3;
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trips),f(a).output{1}));
    for e = 1:length(eps)
        de = f(a).epochs{1}(eps(e),:);
        riptsz = [bytet.out{a}.ripstarttimes{de(1)}{de(2)}, bytet.out{a}.instfreq{de(1)}{de(2)}, bytet.out{a}.spikenum{de(1)}{de(2)}, bytet.out{a}.tetnum{de(1)}{de(2)}./bytet.out{a}.totaltetnum{de(1)}{de(2)}];
        tphasenum = f(a).output{1}(eps(e)).trips.taskphase;
        valtrials = ~isnan(tphasenum);
        tphasenum = [tphasenum(valtrials), [1:sum(valtrials)]'];   % add trial numbers
        homerips = f(a).output{1}(eps(e)).trips.homeripcontent(valtrials);
        hometypes = f(a).output{1}(eps(e)).trips.homeripmaxtypes(valtrials);
        homecounts = f(a).output{1}(eps(e)).trips.homecontentcounts(valtrials); %has rip times, which we can use to id the other features
        rwrips = f(a).output{1}(eps(e)).trips.RWripcontent(valtrials);
        postrwrips = f(a).output{1}(eps(e)).trips.postRWripcontent(valtrials);
        rwtypes = f(a).output{1}(eps(e)).trips.RWripmaxtypes(valtrials); %
        postrwtypes = f(a).output{1}(eps(e)).trips.postRWripmaxtypes(valtrials); %
        rwcounts = f(a).output{1}(eps(e)).trips.rwcontentcounts(valtrials);
        postrwcounts = f(a).output{1}(eps(e)).trips.postrwcontentcounts(valtrials);
        boxdur = sum([f(a).output{1}(eps(e)).trips.homewaitlength(valtrials), f(a).output{1}(eps(e)).trips.RWwaitlength(valtrials), f(a).output{1}(eps(e)).trips.postRWwaitlength(valtrials)],2);
        rips = cellfun(@(x,y,z) [x;y;z],homerips,rwrips,postrwrips,'un',0);
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        counts = cellfun(@(x,y,z) [x;y;z],homecounts,rwcounts,postrwcounts,'un',0);
        outerrips = f(a).output{1}(eps(e)).trips.outerripcontent(valtrials);
        outertypes = f(a).output{1}(eps(e)).trips.outerripmaxtypes(valtrials); %
        outercounts = f(a).output{1}(eps(e)).trips.outercontentcounts(valtrials);
        goals = f(a).output{1}(eps(e)).trips.goalarm(valtrials,:);
        goals(tphasenum(:,1)<=1,1) = nan; % turn currgoals during search trials into nans
        goals(goals(:,1)==0,1) = nan;
        outers = f(a).output{1}(eps(e)).trips.outerarm(valtrials);
        pastwlock = f(a).output{1}(eps(e)).trips.prevarm(valtrials,2);  % only consider the including lockout option
        trialstack  = [outers', pastwlock, goals,tphasenum(:,1)];
        clear events outerevents 
        for t=1:length(rips)  % categorize each events as cont/frag and remote/local; use time of event to add other features [c/f r/l amp dur instfrq spkrate tetnum] 
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh; % valid = continuous; local=1; remote=0
                ripinds = lookup(counts{t}(:,6),riptsz(:,1));
                events{t} = [valid,ind-1==0, counts{t}(:,7:8), riptsz(ripinds,2), riptsz(ripinds,3)./counts{t}(:,8),riptsz(ripinds,4)];
            else events{t} = []; end
            if ~isempty(outerrips{t})
                [maxval,ind] = max(outerrips{t},[],2); %(:,2:end)
                valid = outertypes{t}'==1 & maxval>contentthresh;
                ripinds = lookup(outercounts{t}(:,6),riptsz(:,1));
                outerevents{t} = [valid,ind-1==trialstack(t,1),outercounts{t}(:,7:8), riptsz(ripinds,2), riptsz(ripinds,3)./outercounts{t}(:,8),riptsz(ripinds,4)]; 
            else outerevents{t} = []; end
        end
        allevents{a}{e} = [vertcat(events{:}); vertcat(outerevents{:})];
        %split events by correct vs incorrect trials
        error = tphasenum(:,1)>0 & mod(tphasenum(:,1),1)>0 & mod(tphasenum(:,1),1)<.85;
        corr{a}{e} = events(tphasenum(:,1)>1 & ~error);
        err{a}{e} = events(tphasenum(:,1)>1 & error);
        corrtime{a}{e} = boxdur(tphasenum(:,1)>1 & ~error);
        errtime{a}{e} = boxdur(tphasenum(:,1)>1 & error);
    end
    alleventsperan{a} = vertcat(allevents{a}{:});
    grpvar{a} = alleventsperan{a}(:,1); grpvar{a}(alleventsperan{a}(:,1)==1 & alleventsperan{a}(:,2)==0) = 2; % 1=local 2=remote
    %[mn, sd, sm] = grpstats(alleventsperan{a},grpvar,{'mean','std','sem'});
    allcorr = horzcat(corr{a}{:}); allerr = horzcat(err{a}{:});
    noevents_corr = cellfun(@isempty,allcorr); noevents_err = cellfun(@isempty,allerr);
    corrnum(~noevents_corr) = cellfun(@(x) size(x,1),allcorr(~noevents_corr));
    errnum(~noevents_err) = cellfun(@(x) size(x,1),allerr(~noevents_err));
    
    subplot(2,3,1);hold on; title('numrips')
    errorbar(a+[0 .3],[mean(corrnum), mean(errnum)],[std(corrnum)./sqrt(length(corrnum)), std(errnum)./sqrt(length(errnum))],'k.');
    bar(a+[0 .3],[mean(corrnum), mean(errnum)],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(corrnum, errnum),length(corrnum),length(errnum)); text(a,1.5,wrds);  %ylim([0 2])
    
    corrrem(~noevents_corr) = cellfun(@(x) sum(x(:,1)==1& x(:,2)==0),allcorr(~noevents_corr));
    errrem(~noevents_err) = cellfun(@(x) sum(x(:,1)==1& x(:,2)==0),allerr(~noevents_err));
    subplot(2,3,2);hold on; title('numremote')
    errorbar(a+[0 .3],[mean(corrrem), mean(errrem)],[std(corrrem)./sqrt(length(corrrem)), std(errrem)./sqrt(length(errrem))],'k.');
    bar(a+[0 .3],[mean(corrrem), mean(errrem)],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f',ranksum(corrrem, errrem)); text(a,1.5,wrds);
    
    subplot(2,3,3);hold on; title('remote rate')
    errorbar(a+[0 .3],[mean(corrrem'./vertcat(corrtime{a}{:})), mean(errrem'./vertcat(errtime{a}{:}))],[std(corrrem'./vertcat(corrtime{a}{:}))./sqrt(length(vertcat(corrtime{a}{:}))), std(errrem'./vertcat(errtime{a}{:}))./sqrt(length(vertcat(errtime{a}{:})))],'k.');
    bar(a+[0 .3],[mean(corrrem'./vertcat(corrtime{a}{:})), mean(errrem'./vertcat(errtime{a}{:}))],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f',ranksum(corrrem'./vertcat(corrtime{a}{:}), errrem'./vertcat(errtime{a}{:}))); text(a,.2,wrds);
    
    corrsize = nan(length(allcorr),1); errsize = nan(length(allerr),1); % fill no event trials with nan (otherwise zero pull down mean)
    corrsize(~noevents_corr) = cellfun(@(x) mean(x(x(:,1)==1 & x(:,2)==0,3)),allcorr(~noevents_corr));
    errsize(~noevents_err) = cellfun(@(x) mean(x(x(:,1)==1 & x(:,2)==0,3)),allerr(~noevents_err));
    subplot(2,3,4);hold on; title('remote event size')
    errorbar(a+[0 .3],[nanmean(corrsize), nanmean(errsize)],[nanstd(corrsize)./sqrt(sum(~isnan(corrsize))), nanstd(errsize)./sqrt(sum(~isnan(errsize)))],'k.');
    bar(a+[0 .3],[nanmean(corrsize), nanmean(errsize)],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f\nn=%d,%d',ranksum(corrsize, errsize),sum(~isnan(corrsize)),sum(~isnan(errsize))); text(a,1.5,wrds);
    
    corrdur = nan(length(allcorr),1); errdur = nan(length(allerr),1); % fill no event trials with nan (otherwise zero pull down mean)
    corrdur(~noevents_corr) = cellfun(@(x) mean(x(x(:,1)==1 & x(:,2)==0,4)),allcorr(~noevents_corr));
    errdur(~noevents_err) = cellfun(@(x) mean(x(x(:,1)==1 & x(:,2)==0,4)),allerr(~noevents_err));
    subplot(2,3,5);hold on; title('remote event dur')
    errorbar(a+[0 .3],[nanmean(corrdur), nanmean(errdur)],[nanstd(corrdur)./sqrt(sum(~isnan(corrdur))), nanstd(errdur)./sqrt(sum(~isnan(errdur)))],'k.');
    bar(a+[0 .3],[nanmean(corrdur), nanmean(errdur)],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f',ranksum(corrdur, errdur)); text(a,.05,wrds);
    
    corrspk = nan(length(allcorr),1); errspk = nan(length(allerr),1); % fill no event trials with nan (otherwise zero pull down mean)
    corrspk(~noevents_corr) = cellfun(@(x) mean(x(x(:,1)==1 & x(:,2)==0,6)),allcorr(~noevents_corr));
    errspk(~noevents_err) = cellfun(@(x) mean(x(x(:,1)==1 & x(:,2)==0,6)),allerr(~noevents_err));
    subplot(2,3,6);hold on; title('remote event spkrate')
    errorbar(a+[0 .3],[nanmean(corrspk), nanmean(errspk)],[nanstd(corrspk)./sqrt(sum(~isnan(corrspk))), nanstd(errspk)./sqrt(sum(~isnan(errspk)))],'k.');
    bar(a+[0 .3],[nanmean(corrspk), nanmean(errspk)],.8,'FaceColor',animcol(a,:));
    wrds = sprintf('pooled\np=%.03f',ranksum(corrspk, errspk)); text(a,500,wrds);
    
    clear corrnum corrrem corrsize corrspk corrdur errnum errdur errspk errsize errrem
end

figure;set(gcf,'Position',[66 305 1853 551]);
subplot(2,5,1); hold on; for a = 1:4;
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,3),alleventsperan{a}(grpvar{a}>0,3)),ranksum(alleventsperan{a}(grpvar{a}==1,3),alleventsperan{a}(grpvar{a}==2,3))]; 
    boxplot(alleventsperan{a}(:,3),alleventsperan{a}(:,1),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
ylabel('cont vs frag'); title('size'); ylim([0 30]); xlim([0 5]); text(a,20+2*a,num2str(pvals(1))); end

subplot(2,5,6); hold on;  for a=1:4
        pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,3),alleventsperan{a}(grpvar{a}>0,3)),ranksum(alleventsperan{a}(grpvar{a}==1,3),alleventsperan{a}(grpvar{a}==2,3))]; 
        boxplot(alleventsperan{a}(grpvar{a}>0,3),alleventsperan{a}(grpvar{a}>0,2),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
    text(a,20+2*a,num2str(pvals(2))); ylabel('remote vs local'); ylim([0 30]); xlim([0 5]); end

subplot(2,5,2); hold on; for a =1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,4),alleventsperan{a}(grpvar{a}>0,4)),ranksum(alleventsperan{a}(grpvar{a}==1,4),alleventsperan{a}(grpvar{a}==2,4))]; 
    boxplot(alleventsperan{a}(:,4),alleventsperan{a}(:,1),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
    title('dur'); ylim([0 .5]); xlim([0 5]); text(a,.4+a/20,num2str(pvals(1))); end

subplot(2,5,7); hold on; for a =1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,4),alleventsperan{a}(grpvar{a}>0,4)),ranksum(alleventsperan{a}(grpvar{a}==1,4),alleventsperan{a}(grpvar{a}==2,4))]; 
    boxplot(alleventsperan{a}(grpvar{a}>0,4),alleventsperan{a}(grpvar{a}>0,2),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
    text(a,.4+a/20,num2str(pvals(2))); ylim([0 .5]); xlim([0 5]); end 

subplot(2,5,3); hold on; for a=1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,5),alleventsperan{a}(grpvar{a}>0,5)),ranksum(alleventsperan{a}(grpvar{a}==1,5),alleventsperan{a}(grpvar{a}==2,5))]; 
    boxplot(alleventsperan{a}(:,5),alleventsperan{a}(:,1),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
    title('freq'); ylim([150 250]); xlim([0 5]); text(a,230+2*a,num2str(pvals(1))); end

subplot(2,5,8); hold on;  for a=1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,5),alleventsperan{a}(grpvar{a}>0,5)),ranksum(alleventsperan{a}(grpvar{a}==1,5),alleventsperan{a}(grpvar{a}==2,5))]; 
 boxplot(alleventsperan{a}(grpvar{a}>0,5),alleventsperan{a}(grpvar{a}>0,2),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
text(a,230+2*a,num2str(pvals(2))); ylim([150 250]); xlim([0 5]); end

subplot(2,5,4); hold on; for a=1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,6),alleventsperan{a}(grpvar{a}>0,6)),ranksum(alleventsperan{a}(grpvar{a}==1,6),alleventsperan{a}(grpvar{a}==2,6))]; 
    boxplot(alleventsperan{a}(:,6),alleventsperan{a}(:,1),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
    title('spkrate'); ylim([0 5000]); xlim([0 5]); text(a,4000+100*a,num2str(pvals(1))); end

subplot(2,5,9); hold on;   for a=1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,6),alleventsperan{a}(grpvar{a}>0,6)),ranksum(alleventsperan{a}(grpvar{a}==1,6),alleventsperan{a}(grpvar{a}==2,6))]; 
boxplot(alleventsperan{a}(grpvar{a}>0,6),alleventsperan{a}(grpvar{a}>0,2),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
text(a,4000+100*a,num2str(pvals(2))); ylim([0 5000]); xlim([0 5]); end

subplot(2,5,5); hold on; for a=1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,7),alleventsperan{a}(grpvar{a}>0,7)),ranksum(alleventsperan{a}(grpvar{a}==1,7),alleventsperan{a}(grpvar{a}==2,7))]; 
    boxplot(alleventsperan{a}(:,7),alleventsperan{a}(:,1),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
    title('tetfrac'); ylim([0 1]); xlim([0 5]); text(a,.8+a/10,num2str(pvals(1))); text(a,.1+a/10,sprintf('n=%d,%d',sum(grpvar{a}==0),sum(grpvar{a}>0))); end

subplot(2,5,10); hold on;   for a=1:4
    pvals = [ranksum(alleventsperan{a}(grpvar{a}==0,7),alleventsperan{a}(grpvar{a}>0,7)),ranksum(alleventsperan{a}(grpvar{a}==1,7),alleventsperan{a}(grpvar{a}==2,7))]; 
    boxplot(alleventsperan{a}(grpvar{a}>0,7),alleventsperan{a}(grpvar{a}>0,2),'Positions',[a a-.3],'Symbol','','Colors',animcol(a,:),'Width',.25); 
    text(a,.8+a/10,num2str(pvals(2))); ylim([0 1]); xlim([0 5]); text(a,.1+a/10,sprintf('n=%d,%d',sum(grpvar{a}==1),sum(grpvar{a}==2))); end


%% make boxplot quantification of replay fracs that are past, future, pg, etc & GLM plot for LAST EVENT ONLY
clearvars -except f animals animcol
bars = figure(); set(gcf,'Position',[66 305 1853 551]); glms = figure(); set(gcf,'Position',[66 305 1853 551]);

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
        types = cellfun(@(x,y,z) [x,y,z]',hometypes,rwtypes,postrwtypes,'un',0);
        clear replays
        for t=1:length(rips)
            if ~isempty(rips{t})
                [maxval,ind] = max(rips{t},[],2); %(:,2:end)
                valid = types{t}==1 & maxval>contentthresh;
                replays{t} = ind(valid)'-1; %
                % only use last event (even if it's a local event)
%                 if ~isempty(replays{t})
%                     replays{t} = replays{t}(end);
%                 end
                if any(replays{t}>0)  % use last *non-box* event
                    replays{t} = replays{t}(find(replays{t}>0,1,'last'));
                else
                    replays{t} = [];
                end
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
        
        %for the GLM 
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
  
    end
    % past future cg pg 
    searchcomb{a} = [search_past{a}(search_rtcounts{a}(:,2)>=mintrials)' search_future{a}(search_rtcounts{a}(:,2)>=mintrials)' search_prevgoal{a}(search_rtcounts{a}(:,2)>=mintrials)' search_other{a}(search_rtcounts{a}(:,2)>=mintrials)'];
    searchshuffcomb{a} = reshape(search_randshuff{a}(search_rtcounts{a}(:,2)>=mintrials,:),[],1); 
    repcomb{a} = [rep1_pfg{a}(rep1_rtcounts{a}(:,2)>=mintrials)' rep1_prevgoal{a}(rep1_rtcounts{a}(:,2)>=mintrials)' rep1_other{a}(rep1_rtcounts{a}(:,2)>=mintrials)'];
    repshuffcomb{a} = reshape(rep1_randshuff{a}(rep1_rtcounts{a}(:,2)>=mintrials,:),[],1); 
    
    search_p{a} = [ranksum(searchcomb{a}(:,1),searchshuffcomb{a}),ranksum(searchcomb{a}(:,2),searchshuffcomb{a}),ranksum(searchcomb{a}(:,3),searchshuffcomb{a}),ranksum(searchcomb{a}(:,4),searchshuffcomb{a})];
    rep_p{a} = [ranksum(repcomb{a}(:,1),repshuffcomb{a}),ranksum(repcomb{a}(:,2),repshuffcomb{a}),ranksum(repcomb{a}(:,3),repshuffcomb{a})];

    figure(glms);
    searchcat = vertcat(allsearch{a}{:});
    searchtbl = table(searchcat(:,2),searchcat(:,1),searchcat(:,3),searchcat(:,4),'VariableNames',{'past','future','prevgoal','replaynum'});
    s_mdl = fitglm(searchtbl,'linear','Distribution','poisson');
    CI = coefCI(s_mdl,.01);
    subplot(1,3,1); hold on; title('last remote event, search')
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
    subplot(1,3,2); hold on; title('last remote event, repeat')
    %errorbar(a+[0:5:24],table2array(mdl.Coefficients(:,1)), table2array(mdl.Coefficients(:,2)),'.','Color',animcol(a,:))
    plot(a+[0:5:24],exp(table2array(r_mdl.Coefficients(:,1))),'.','MarkerSize',20,'Color',animcol(a,:));
    plot([a+[0:5:24];a+[0:5:24]],exp(CI)','Color',animcol(a,:));
    %cr = [corrcoef(repeatcat(:,1),repeatcat(:,2)), corrcoef(repeatcat(:,1),repeatcat(:,3)),corrcoef(repeatcat(:,1),repeatcat(:,4)), ...
    %    corrcoef(repeatcat(:,2),repeatcat(:,3)), corrcoef(repeatcat(:,2),repeatcat(:,4)),corrcoef(repeatcat(:,3),repeatcat(:,4))];
    %repr2(a,:)=cr(1,[2:2:12]).^2;
    %text(5,2+.2*a,['f vs cg corrcoef=',num2str(cr(2),'%.03f')],'Color',animcol(a,:));
    text(5,2+.2*a,['trial n=',num2str(size(repeatcat,1)/8)],'Color',animcol(a,:));

end
subplot(1,3,1); plot([0 20],[1 1],'k:');
subplot(1,3,2); plot([0 25],[1 1],'k:');

figure(bars)
subplot(1,8,1); ylabel('fraction of remote replay')
plot4a(searchshuffcomb,'gnames',{'null'}); ylim([0 .5]); text(6,.4,num2str(cellfun(@(x) sum(x(:,2)>=mintrials),search_rtcounts)))
subplot(1,8,[2 3 4]); hold on; title('last remote event,search')
plot4a(searchcomb,'gnames',{'past','future','pg','other'});
text(8,.45,num2str(vertcat(search_p{:})))
plot([1 40],[.125 .125],'k:'); ylim([0 .5])
subplot(1,8,5); 
plot4a(repshuffcomb,'gnames',{'null'}); ylim([0 .5]); text(6,.4,num2str(cellfun(@(x) sum(x(:,2)>=mintrials),rep1_rtcounts)))
subplot(1,8,[6 7 8]); hold on; title('last remote event,repeat')
plot4a(repcomb,'gnames',{'pfg','pg','other'});
plot([1 40],[.125 .125],'k:'); ylim([0 .5])
text(8,.45,num2str(vertcat(rep_p{:}))); xlabel(['mintrials=' num2str(mintrials)]);ylabel('fraction of remote replay')
