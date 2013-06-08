function allStat = evalbyclass(Y, R, cat)
% EVALBYCLASS evaludates continuous vs discrete gesture classification.
% Args:
% - R: cell array

allStat = containers.Map();
for c = cat
  nfold = size(R, 2);
  stat = cell(1, nfold);
  for i = 1 : nfold
    % User split from the result.
    split1 = R{i}.split;
    Ytrue.Tr = Y(split1{1});
    Ytrue.Va = Y(split1{2});
    stat{i} = evalOneFold(Ytrue, R{i}.prediction, c);
  end
  allStat = [allStat; stat{i}]; %#ok<AGROW>
end

dataType = {'Tr', 'Va'};
value = {'Precision', 'Recall', 'F1'};
for i = 1 : length(dataType)
  for j = 1 : length(value)
    nclass = length(cat);
    res = zeros(1, nclass);
    key = [dataType{i}, value{j}];
    for c = 1 : nclass
      res(c) = allStat([num2str(cat(c)), key]);
    end
    % Calculate mean and std across all classes.
    allStat([key 'Mean']) = ignoreNaN(res, @mean, 2);
    allStat([key 'Std']) = ignoreNaN(res, @std, 2);
  end
end
end

function stat = evalOneFold(Y, R, cat)
key = {'Tr', 'Va'};
if isfield(Y, 'Te')
  key{end + 1} = 'Te'; 
end

stat = containers.Map();
for i = 1 : length(key)
  res = evaluate(Y.(key{i}), R.(key{i}), cat, key{i});
  stat = [stat; res]; %#ok<AGROW>
end
end

function stat = evaluate(Ytrue, Ystar, cat, datatype)
totalCount = zeros(1, 4); % [tp fp tn fn]
for i = 1 : length(Ytrue)
  for j = 1 : size(Ytrue{i}, 2)
    count = quantify(Ytrue{i}(1, j), Ystar{i}(1, j), cat);
    totalCount = totalCount + count;
  end
end

key = {'Precision', 'Recall', 'F1'};
key = cellfun(@(x) [num2str(cat) datatype x], key, 'UniformOutput', false);
tpfp = sum(totalCount([1 2]));
p = totalCount(1) / tpfp;
r = totalCount(1) / sum(totalCount([1 4]));
f1 = 2 * p * r / (p + r);
value = {p, r, f1};
stat = containers.Map(key, value);
end
