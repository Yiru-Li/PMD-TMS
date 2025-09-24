subj = 'q006';
subj_dir = ['/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Analysis/Dosing/PMD-TMS/' subj];
msh = mesh_load_gmsh4(fullfile(subj_dir, [subj '.msh']));
subj_coords = mni2subject_coords([-43, -89, -8], fullfile(subj_dir, ['m2m_' subj]));
GM_centers = mesh_get_tetrahedron_centers(msh);
GM_centers = GM_centers(msh.tetrahedron_regions==2, :);
GM_vols = mesh_get_tetrahedron_sizes(msh);
GM_vols = GM_vols(msh.tetrahedron_regions==2);
% limit ROI to 5mm radius sphere
ROI = find(pdist2(subj_coords, GM_centers)<5)';
%%
N = 5*360;
E = 0;
tic
for a = 1%:3
    for r = 1:110
        load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['B_' num2str(r) '.mat']), 'Bi')
        load(fullfile(subj_dir, 'FEM_1', 'Modes_110', ['q_' num2str(r) '.mat']), 'Qi')
        %     E = E+Qi(ROI*3-2)*Bi+Qi(ROI*3-1)*Bi+Qi(ROI*3)*Bi;
        E = E+pdist2([0 0 0], [Qi(1:3:end)*Bi(N) Qi(2:3:end)*Bi(N) Qi(3:3:end)*Bi(N)])';
%         E = E+Qi(a:3:end)*Bi(N)';
    end
    msh.element_data{a}.tetdata = zeros(size(msh.tetrahedron_regions));
    msh.element_data{a}.tetdata(msh.tetrahedron_regions==2) = E;
    msh.element_data{a}.tridata = [];
    msh.element_data{a}.name = ['magnE' num2str(a)];
end
toc
mesh_save_gmsh4(msh, 'test.msh')