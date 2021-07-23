%% Sungod Manu: Plot Decoding error during movement times 

animals = {'jaq','roquefort','despereaux','montague'}; %

for a = 1:length(animals)
    
    epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'')) & $forageassist==0']; %& $epoch==2
    %epochfilter{1} = ['$session==6  & isequal($environment,''goal'')'];
    %epochfilter{1} = ['$ripthresh>=0 & (isequal($environment,''goal'') | isequal($environment,''hybrid2'') | isequal($environment,''hybrid3''))'];
    
    % resultant excludeperiods will define times when velocity is high
    timefilter{1} = {'ag_get2dstate', '($immobility == 1)','immobility_velocity',4,'immobility_buffer',0};
    iterator = 'epochbehaveanal';
    f(a) = createfilter('animal',animals{a},'epochs',epochfilter,'excludetime', timefilter, 'iterator', iterator);
    
    %args: 
    %converter = {[
    f(a) = setfilterfunction(f(a), 'dfa_decodequant_movement', {'pos','ca1rippleskons','ripdecodesv3','trials'},'animal',animals{a},'useclassifier',1,'vers','v3');
    f(a) = runfilter(f(a));
end

%save('/media/anna/whirlwindtemp2/ffresults/ctrl_movementquant_full2state_all_withtrialwise.mat','f','-v7.3')
animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols

%load('/media/anna/whirlwindtemp2/ffresults/ctrl_movementquant_full2state_gooddecode.mat')
%load('/media/anna/whirlwindtemp2/ffresults/ctrl_movementquant_full2state_all_withtrialwise.mat')


%% 1. heatmaps of error distributions per animal across days and summary of all days
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

%% 2. plot measurable fraction, mean error, error across eps/posbins
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

%% 3. plot measurable fraction, mean error, CIs, numtets, numspikes
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
%% 4. save mean error into taskstruct for each epoch for future filtering

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
    
%% 5. plot mean decoding error per day 
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

%% 6. analyze decoding error over the course of a trial block
clearvars -except f animals animcol
bybin = figure(); set(gcf,'Position',[675 1 1202 973]); 
slopes = figure(); set(gcf,'Position',[675 1 1202 973]); 
for a = 1:length(animals)
    eps = find(arrayfun(@(x) ~isempty(x.trialwise),f(a).output{1}));
    for e = 1:length(eps)
        tphase = f(a).output{1}(eps(e)).trialwise.taskphase;
        tphase(mod(tphase,1)>.85) = tphase(mod(tphase,1)>.85)+.1;  % .9 trials should be considere rewarded visits in this case
        tnum = [1:length(tphase)]';
        rewarded = tphase>0 & mod(tphase,1)==0;
        outers = f(a).output{1}(eps(e)).trialwise.outerarm; 
        diffs = f(a).output{1}(eps(e)).trialwise.diffbybin;
        repstarts = [find(tphase==1); length(outers)+1];
        for c = 1:length(repstarts)-1;
            goalarm = outers(repstarts(c));
            if any(outers==goalarm & tnum<repstarts(c))
                pre{c} = diffs(outers==goalarm & tnum<repstarts(c),:); 
            else
                pre{c} = nan(1,13);
            end
            dur{c} = nan(16,13);
            dur{c}(1:sum(rewarded & tnum>=repstarts(c) & tnum<repstarts(c+1)),:) = diffs(rewarded & tnum>=repstarts(c) & tnum<repstarts(c+1),:);
            errs{c} = diffs(~rewarded & tphase>0 & tnum>=repstarts(c) & tnum<repstarts(c+1),:);
            last{c} = dur{c}(sum(rewarded & tnum>=repstarts(c) & tnum<repstarts(c+1)),:);
            if any(outers==goalarm & tnum>repstarts(c+1))  % visits to the previous goal arm later in the ep
                post{c} = diffs(outers==goalarm & tnum>repstarts(c+1),:);  % does not include visits to goal in subs search phase
            else
                post{c} = nan(1,13);
            end
        end
        ep_pre{e} = vertcat(pre{:});
        ep_dur{e} = cat(3,dur{:});
        ep_errs{e} = vertcat(errs{:});
        ep_last{e} = vertcat(last{:});
        ep_post{e} = vertcat(post{:});
        clear pre post dur errs last
    end
    % full arm
    figure(bybin)
     allpre = vertcat(ep_pre{:}); allpost = vertcat(ep_post{:}); alllast = vertcat(ep_last{:}); alldur = cat(3,ep_dur{:});
     subplot(2,4,a); hold on
     %boxplot(nanmean(allpre,2),'Positions',1,'Symbol','','Widths',.8,'Colors',animcol(a,:))
     boxplot(squeeze(nanmean(alldur(1,:,:),2)),'Positions',2,'Symbol','','Widths',.8,'Colors',animcol(a,:)); 
     boxplot(nanmean(alllast,2),'Positions',3,'Symbol','','Widths',.8,'Colors',animcol(a,:)); 
     %boxplot(nanmean(allpost,2),'Positions',4,'Symbol','','Widths',.8,'Colors',animcol(a,:)); 
     xlim([0 5]); set(gca,'xtick',[1:4],'xticklabel',{'pre','first','last','post'}); title('full arm'); ylim([0 3]);
     %text(1,2.5,sprintf('pre-post %.05f',ranksum(nanmean(allpre,2),nanmean(allpost,2))))
     text(1,2,sprintf('first-last %.05f',ranksum(squeeze(nanmean(alldur(1,:,:),2)),nanmean(alllast,2))))
     subplot(2,4,a+4); hold on
     %boxplot(nanmean(allpre(:,9:13),2),'Positions',1,'Symbol','','Widths',.8,'Colors',animcol(a,:))
     boxplot(squeeze(nanmean(alldur(1,9:13,:),2)),'Positions',2,'Symbol','','Widths',.8,'Colors',animcol(a,:)); 
     boxplot(nanmean(alllast(:,9:13),2),'Positions',3,'Symbol','','Widths',.8,'Colors',animcol(a,:)); 
     %boxplot(nanmean(allpost(:,9:13),2),'Positions',4,'Symbol','','Widths',.8,'Colors',animcol(a,:)); 
     xlim([0 5]); set(gca,'xtick',[1:4],'xticklabel',{'pre','first','last','post'}); title('last 25cm'); ylim([0 5]); ylabel('deviation')
     %text(1,3.5,sprintf('pre-post %.05f',ranksum(nanmean(allpre(:,9:13),2),nanmean(allpost(:,9:13),2))))
     text(1,3,sprintf('first-last %.05f',ranksum(squeeze(nanmean(alldur(1,9:13,:),2)),nanmean(alllast(:,9:13),2))))
     text(-1,3.5,sprintf('n=%d',sum(~isnan(nanmean(alldur(1,9:13,:),2)))));
     
     % calculate slope for each contingency
     for cont = 1:size(alldur,3)
         tris = nanmean(alldur(:,:,cont),2);
         if sum(~isnan(tris))>=4  %don't calculate slope if there are less than 4 trials
         slope(cont,:) = polyfit(find(~isnan(tris)),tris(~isnan(tris)),1);
         tris = nanmean(alldur(:,9:13,cont),2);
         slopelast(cont,:) = polyfit(find(~isnan(tris)),tris(~isnan(tris)),1);
         else
             slope(cont,:) = [nan nan];
             slopelast(cont,:) = [nan nan];
         end
     end
     figure(slopes)
     subplot(2,4,a); hold on; histogram(slope(:,1),[-1:.05:1],'Normalization','probability','FaceColor',animcol(a,:)); 
     title([animals{a} ' fullarm']); ylim([0 .6]); ylabel('frac blocks'); xlabel('slope'); xlim([-1 1])
     text(-1,.4,sprintf('n=%d',sum(~isnan(slope(:,1)))));
     subplot(2,4,a+4); hold on; histogram(slopelast(:,1),[-1:.05:1],'Normalization','probability','FaceColor',animcol(a,:)); 
     title([animals{a} ' last 25cm']); ylim([0 .6]); ylabel('frac blocks'); xlabel('slope'); xlim([-1 1])
     text(-1,.4,sprintf('n=%d',sum(~isnan(slopelast(:,1)))));
%      errorbar([1:4]',[nanmean(nanmean(allpre(:,1:4),2)); nanmean(nanmean(alldur(1,1:4,:),2),3); nanmean(nanmean(alllast(:,1:4),2)); nanmean(nanmean(allpost(:,1:4),2))], ...
%          [nanstd(nanmean(allpre(:,1:4),2)); nanstd(nanmean(alldur(1,1:4,:),2),[],3); nanstd(nanmean(alllast(:,1:4),2)); nanstd(nanmean(allpost(:,1:4),2))],'k.');
%      bar([1:4]',[nanmean(nanmean(allpre(:,1:4),2)); nanmean(nanmean(alldur(1,1:4,:),2),3); nanmean(nanmean(alllast(:,1:4),2)); nanmean(nanmean(allpost(:,1:4),2))],'FaceColor',animcol(a,:));
%     set(gca,'xticklabel',{'pre','first','last','post'})
    
     %     bar(18,nanmean(nanmean(allpost(:,1:4),2)),'FaceColor',cols(18,:),'Linewidth',2)
%     title('arm start'); axis tight
%     cols = cool(18);
%     figure(bybin); subplot(3,4,a) ; hold on;
%     plot(nanmean(vertcat(ep_pre{:})),':','Color',cols(1,:),'Linewidth',2);
%     alldur = cat(3,ep_dur{:}); %alldur = nanstd(cat(3,ep_dur{:}),[],3);
%     for t =1:16
%     plot(nanmean(alldur(t,:,:),3),'Color',cols(t,:),'Linewidth',1)
%     end
%     plot(nanmean(vertcat(ep_post{:})),':','Color',cols(18,:),'Linewidth',2);
%     xlabel('arm bins'); xlim([0 14]) % legend({'pre','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','post'})
%     
%     subplot(3,4,a+4); hold on 
%     allpre = vertcat(ep_pre{:}); allpost = vertcat(ep_post{:});
%     errorbar([-1, 1:16,18]',[nanmean(nanmean(allpre(:,1:4),2)); nanmean(nanmean(alldur(:,1:4,:),2),3); nanmean(nanmean(allpost(:,1:4),2))],[nanstd(nanmean(allpre(:,1:4),2)); nanstd(nanmean(alldur(:,1:4,:),2),[],3); nanstd(nanmean(allpost(:,1:4),2))],'k.');
%     bar(-1,nanmean(nanmean(allpre(:,1:4),2)),'FaceColor',cols(1,:),'Linewidth',2)
%     for t =1:16
%         if sum(~isnan(nanmean(alldur(t,1:4,:),2)))>=10
%             bar(t,nanmean(nanmean(alldur(t,1:4,:),2),3),'FaceColor',cols(t+1,:),'Linewidth',2)
%         end
%     end
%     bar(18,nanmean(nanmean(allpost(:,1:4),2)),'FaceColor',cols(18,:),'Linewidth',2)
%     title('arm start'); axis tight
%     subplot(3,4,a+8); hold on
%     errorbar([-1, 1:16,18]',[nanmean(nanmean(allpre(:,10:13),2)); nanmean(nanmean(alldur(:,10:13,:),2),3); nanmean(nanmean(allpost(:,10:13),2))],[nanstd(nanmean(allpre(:,10:13),2)); nanstd(nanmean(alldur(:,10:13,:),2),[],3); nanstd(nanmean(allpost(:,10:13),2))],'k.');
%     bar(-1,nanmean(nanmean(allpre(:,10:13),2)),'FaceColor',cols(1,:),'Linewidth',2)
%     for t =1:16
%         if sum(~isnan(nanmean(alldur(t,10:13,:),2)))>=10
%             bar(t,nanmean(nanmean(alldur(t,10:13,:),2),3),'FaceColor',cols(t+1,:),'Linewidth',2)
%         end
%     end
%     bar(18,nanmean(nanmean(allpost(:,10:13),2)),'FaceColor',cols(18,:),'Linewidth',2)
%     title('arm end'); axis tight
end 
%plot example slope for one contingency
figure
plot(1:16,nanmean(alldur(:,:,2),2),'.','MarkerSize',20); lsline; ylim([0 4]); ylabel('deviation'); xlabel('rewarded visit number')
title('single block example, monty block2')