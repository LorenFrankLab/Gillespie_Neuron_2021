function trial_interval = label_trial_interval(trials, valtrials);
% 0 = forage
% -.2 = forage "error" - repeat an unrewarded arm. 
% integer = rewarded, value indicates amount of goal experience
% .5 = neighbor error
% .3 = oldgoal error
% .8 = other error
% .9 = final trial of the contingency when he goes to goal and doesn't receive reward

valoutersgoals = [trials.outerwell(valtrials),trials.goalwell(valtrials)];
goalbounds = [0; 1+find(diff(valoutersgoals(:,2))~=0); sum(valtrials)];
goals =valoutersgoals(logical([1; diff(valoutersgoals(:,2))~=0]),2);
typetmp = [];
for g = 1:length(goals)
    gtrials = valoutersgoals(goalbounds(g)+1:goalbounds(g+1),:);
    gtrials = [gtrials, gtrials(:,1)==gtrials(:,2)]; % add success indicator
    tmp = [];
    % assign reward interval (integers) and error types (.5=neighbor, .3=oldgoal, .8=other, .9=final trial of contingency)
    for gg = 1:size(gtrials,1)
       
        if gtrials(gg,3)==1
            tmp(gg) = sum(gtrials(1:gg,3));  %rewarded
            
        elseif sum(gtrials(1:gg,3))==0
            if gg>1 & intersect(gtrials(gg,1), gtrials(1:gg-1,1))
                tmp(gg) = -.2;    % forage repeat to previously foraged arm
            else
                tmp(gg) = 0;     % forage
            end
        else                    % error trials
            if gtrials(gg,1)==goals(g)  % if you visit the goal arm but didnt get reward, must be end
                tmp(gg) = sum(gtrials(1:gg,3)) +.9;
            elseif abs(gtrials(gg,1)-gtrials(gg,2))==1   % neighbor error
                tmp(gg) = sum(gtrials(1:gg,3)) +.5;
            elseif g>1 & gtrials(gg,1) == goals(g-1)   % oldgoal error
                tmp(gg) = sum(gtrials(1:gg,3)) + .3;
            else                                            %random error
                tmp(gg) = sum(gtrials(1:gg,3)) +.8;
            end
        end
    end
    typetmp(goalbounds(g)+1:goalbounds(g+1)) = tmp';
end

trial_interval = typetmp;

end

