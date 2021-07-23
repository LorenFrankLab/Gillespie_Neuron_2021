function p = permutationp(realval, shuffvals, varargin)
% arguments: real value, shuffled values, n vals that go into realval(ie trials), permutations, tails (1=greater, -1=less than, 2=2tailed)

% defaults:
n = 0;  % for display, not calculation
reps = 1000;
tails = 2;
mkplot = 0;
takelog = 0;
% process varargin if present and overwrite default values
if (~isempty(varargin))
    assign(varargin{:});
end

shuffdiffs = shuffvals - mean(shuffvals);
realdiff = realval - mean(shuffvals);

switch tails
    case 1
        p = (sum(shuffdiffs>realdiff)+1)/(reps+1);
    case -1
        p = (sum(shuffdiffs<realdiff)+1)/(reps+1);
    case 2
        p = (sum(abs(shuffdiffs)>abs(realdiff))+1)/(reps+1);
end

% check that data is not just nans 
if isnan(realdiff) | all(isnan(shuffvals))
    warning('realdiff or shuff are nans')
    p=nan;
end
if all(diff(shuffvals)==0)
    warning('all shuffles are identical, p=nan')
    p=nan;
end

if takelog % return the logged values for p; -log if real>shuff; log if real < shuff
    if realdiff>mean(shuffdiffs)
       p = -log10(p);
    else
        p = log10(p);
    end
end

if mkplot    
    figure; hold on;
    histogram(shuffdiffs, 'Normalization','probability');
    plot([realdiff, realdiff], [0, .2], 'r', 'LineWidth',2)
    title(sprintf('p= %.03f, ntrials=%d',p,n));
end

end
