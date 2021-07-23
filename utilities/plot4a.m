function plot4a(data, varargin)
% data is a cell array, 1 cell per anim
% cell can be multiple columns, each will be a different group on the same plot
% 

%set/update defaults
animcol = [27 92 41; 25 123 100; 33 159 169; 123 225 191]./255;  %ctrlcols
%animcol = [115 67 193; 214 83 174; 255 96 135; 255 194 81]./255;  % condcols

style = 'box'; %'dots' 
dotjitter = 1;
gnames = {''};
pooled = 0;  

if (~isempty(varargin))
    assign(varargin{:});
end

groups = size(data{1},2);
hold on;
if pooled
    alldata = vertcat(data{:});
    switch style
        case 'dots'
            if dotjitter
                    jitter = rand(size(alldata,1),groups)/12;
                    x = repmat([1:groups]+.5,size(alldata,1),1)+jitter;
                else
                    x = repmat([1:groups]+.5,size(alldata,1),1);
                end 
            plot(x, alldata,'.','MarkerEdgeColor','k','MarkerSize',10,'FaceAlpha',.3);
        case 'box'
            boxplot(alldata,'Positions',6*[1:groups]+2.5,'Symbol','','Colors','k','Notch','off'); %,'Width',.3
    end
else
    for a = 1:length(data)
        switch style
            case 'dots'
                if dotjitter
                    jitter = rand(size(data{a},1),groups)/12;
                    x = repmat([1:groups]+a/6,size(data{a},1),1)+jitter;
                else
                    x = repmat([1:groups]+a/6,size(data{a},1),1);
                end 
                plotSpread(data{a},'xValues',[1:groups]+a/6,'distributionColors',animcol(a,:),'spreadWidth',.2)
                %plot(x, data{a},'.','MarkerEdgeColor',animcol(a,:),'MarkerSize',10); %
                bar([1:groups]+a/6,mean(data{a}),.2,'FaceColor',animcol(a,:))
            case 'box'
                boxplot(data{a},'Positions',6*[1:groups]+a,'Symbol','','Colors',animcol(a,:),'Notch','off','Width',.8); %
        end
    end
end

switch style
    case 'dots'
        set(gca,'xtick',[1:groups]+.5,'xticklabel',gnames);
    case 'box'
        set(gca,'xtick',6*[1:groups]+2.5,'xticklabel',gnames);
        xlim([6 groups*6+5])
end

end
