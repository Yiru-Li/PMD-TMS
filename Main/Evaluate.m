clear all
masterlist = readtable('/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Data/Head_Model_Masterlist_20250514.csv');
% limit to biphasic RMT
masterlist = masterlist(strcmp(masterlist.Waveform, 'Biphasic'), :);
% adjust filepaths
masterlist.Location = strrep(masterlist.Location, 'smb://duhsnas-pri/dusom_psych/Private/IRB', '/Volumes');
masterlist.Location = strrep(masterlist.Location, 'smb://munin6.biac.duke.edu', '/Volumes');
cluster_user = 'yl647@cluster.biac.duke.edu';
cluster_loc = '/Volumes/Data/Neacsiu/NATURE.01/Analysis/efield_scripts/E-ref/';
out_loc = '/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Analysis/Dosing/PMD-TMS';
% MNI coordinates to evaluate
MNIs = readtable('MNI_coords_5mm.xlsx');
MNIs = MNIs(:, contains(MNIs.Properties.VariableNames, 'MNI'));
% coil info
dIdtmax = 149.77e6;
%% mesh info
k = 3;
subj = masterlist.Subject{k};
subjects_folder = masterlist.Location{k};
mesh_path = '';
while isempty(mesh_path)
    subjects_folder = [subjects_folder filesep '*'];
    mesh_path = dir([subjects_folder filesep subj '.msh']);
end
MT = masterlist.MT(k);
dIdt = dIdtmax*MT/100;
%% Find targets
msh = mesh_load_gmsh4(fullfile(mesh_path.folder, mesh_path.name));
GM = mesh_extract_regions(msh, 'region_idx', 2);
GM_centers = mesh_get_tetrahedron_centers(GM);
GM_sizes = mesh_get_tetrahedron_sizes(GM);
targets = mni2subject_coords(MNIs{:, :}, fullfile(mesh_path.folder, ['m2m_' subj]));

%% load B and Q
subj_dir = [out_loc filesep subj];
load(fullfile(subj_dir, 'FEM_1', 'Modes_110', [subj '_FEM_1.mat']), 'pp_standardized')
pp_standardized = pp_standardized*1e3;
subj = masterlist.Subject{k};
B = zeros(110, length(pp_standardized)*360);
Q = zeros(length(GM_centers)*3, 110);
for r = 1:110
    load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['B_' num2str(r) '.mat']), 'Bi')
    load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['Q_' num2str(r) '.mat']), 'Qi')
    B(r, :) = Bi;
    Q(:, r) = Qi;
end

%% find ROI for each MNI
E = zeros(sum(msh.tetrahedron_regions==2), 3);
E50 = zeros(length(targets), 1);
coil_idx = zeros(length(targets), 1);
for t = 1:length(targets)
    [dist, target] = min(pdist2(GM.nodes, targets(t, :)));
    if dist<5 % if target is close enough to GM, snap to GM and find ROI
        target = GM.nodes(target, :);
        ROI = find(pdist2(GM_centers, target)<5);
        % search within 25mm of closest coil position
        [~, target] = min(pdist2(pp_standardized, targets(t, :)));
        coil_pos = find(pdist2(pp_standardized, pp_standardized(target, :))<25);
        % find E-field at coil and mesh element index
        C = reshape((coil_pos*360+(1:360)-360)', [], 1); % coil positions
        T = reshape((ROI*3+(1:3)-3)', [], 1); % mesh elements
        E = Q(T, :)*B(:, C);
        % calculate magnE in ROI for limited coil positions
        magnE = sqrt(E(1:3:end, :).^2+E(2:3:end, :).^2+E(3:3:end, :).^2);
        [magnE_sorted, sort_idx] = sort(magnE, 'descend');
        magnE_sizes = cumsum(GM_sizes(ROI(sort_idx)));
        E50_tmp = max(magnE_sorted.*(magnE_sizes>50)); % max E50 at each coil position
        [E50(t), coil_idx(t)] = max(E50_tmp); % find max E50 for target
        coil_idx(t) = floor((coil_idx(t)+359)/360); % convert coil position to location
    end
end