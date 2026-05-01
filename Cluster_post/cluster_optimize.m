function cluster_optimize(subj)
cd(subj)
fprintf('%s: loading subject info%s', datetime, newline)
load('tmp.mat', 'pp_standardized', 'GM_centers', 'targets', 'GM', 'GM_sizes', 'dIdt')
%% load B and Q
subj_dir = pwd;
pp_standardized = pp_standardized*1e3;
B = zeros(110, length(pp_standardized)*360);
Q = zeros(length(GM_centers)*3, 110);
fprintf('%s: loading B and Q%s', datetime, newline)
for r = 1:110
    load(fullfile(subj_dir, ['B_' num2str(r) '.mat']), 'Bi')
    load(fullfile(subj_dir, ['Q_' num2str(r) '.mat']), 'Qi')
    B(r, :) = Bi;
    Q(:, r) = Qi;
end

%% find ROI for each MNI
E50 = zeros(length(targets), 1);
coil_idx = zeros(length(targets), 1);
fprintf('%s: optimizing%s', datetime, newline)
parfor (t = 1:length(targets), 8)
    [dist, target] = min(pdist2(GM.nodes, targets(t, :)));
    if dist<5 % if target is close enough to GM, snap to GM and find ROI
        target = GM.nodes(target, :);
        ROI = find(pdist2(GM_centers, target)<5);
        % search within 25mm of closest coil position
        [~, target] = min(pdist2(pp_standardized, targets(t, :)));
        coil_pos = find(pdist2(pp_standardized, pp_standardized(target, :))<25);
        % find E-field given coil and mesh element index
        C = reshape((coil_pos*360+(1:360)-360)', [], 1); % coil positions
        T = reshape((ROI*3+(1:3)-3)', [], 1); % mesh elements
        E = Q(T, :)*B(:, C);
        % calculate magnE in ROI for limited coil positions
        magnE = sqrt(E(1:3:end, :).^2+E(2:3:end, :).^2+E(3:3:end, :).^2);
        [magnE_sorted, sort_idx] = sort(magnE, 'descend');
        magnE_sizes = cumsum(GM_sizes(ROI(sort_idx)));
        E50_tmp = max(magnE_sorted.*(magnE_sizes>50)); % max E50 at each coil position
        [E50(t), coil_idx(t)] = max(E50_tmp); % find max E50 for target
        E50(t) = E50(t)*dIdt;
        coil_idx(t) = C(coil_idx(t)); % convert coil position to location
%         fprintf('%s: %i/%i%s', datetime, t, length(targets), newline)
    end
end
writetable([MNIs_full table(E50) table(coil_idx)], 'E50.xlsx')
save('E50.mat', 'E50', 'coil_idx')
fprintf('%s: optimization complete%s', datetime, newline)
end