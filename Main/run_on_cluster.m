clear all
masterlist = readtable('/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Data/Head_Model_Masterlist_20250514.csv');
% limit to biphasic RMT
masterlist = masterlist(strcmp(masterlist.Waveform, 'Biphasic'), :);
% adjust filepaths
masterlist.Location = strrep(masterlist.Location, 'smb://duhsnas-pri/dusom_psych/Private/IRB', '/Volumes');
masterlist.Location = strrep(masterlist.Location, 'smb://munin6.biac.duke.edu', '/Volumes');
cluster_loc = 'yl647@cluster.biac.duke.edu';
out_loc = '/Volumes/Peterchev/MT_Predict/MT_Predict_Data/Analysis/Dosing/PMD-TMS';
%% gather info from spreadsheet
for k = 26:height(masterlist)
    subj = masterlist.Subject{k};
    subjects_folder = masterlist.Location{k};
    mesh_path = '';
    while isempty(mesh_path)
        subjects_folder = [subjects_folder filesep '*'];
        mesh_path = dir([subjects_folder filesep subj '.msh']);
    end
    if ~isfolder(fullfile('../Cluster', subj))
        mkdir(fullfile('../Cluster', subj));
        copyfile(fullfile(mesh_path.folder, mesh_path.name), fullfile('../Cluster', subj));
%         copyfile(fullfile(mesh_path.folder, ['m2m_' subj]), fullfile('../Cluster', subj, ['m2m_' subj]), 'f');
        system(sprintf('cp -r %s %s', fullfile(mesh_path.folder, ['m2m_' subj]), fullfile('../Cluster', subj, ['m2m_' subj])))
    end
    th_hair = masterlist.HT(k)/1e3;
    mkdir(fullfile(out_loc, subj))
    for a = 1:4
        if isfolder(fullfile(out_loc, subj, num2str(a)))
            continue
        end
        %% run stage 1 locally
        alt_stage_1(subj, th_hair, a, 4);
        % push info to cluster
        system(['rsync -rv --size-only --delete ../Cluster/ ' cluster_loc ':PMD-TMS/']);
        system(['ssh ' cluster_loc ' qsub PMD-TMS/array_run_mode_generation_cpu.sh ' subj ' ' num2str(th_hair)]);
        while system(['ssh ' cluster_loc ' test -f "PMD-TMS/' subj '/FEM_1/Modes_110/tmp_done.txt"'])
            pause(60);
        end
        system(['ssh ' cluster_loc ' mv "PMD-TMS/' subj '/*.out" PMD-TMS/' subj '/FEM_1/Modes_110/']);
        %% pull info from cluster
        system(['rsync -rv --size-only ' cluster_loc ':PMD-TMS/' subj '/FEM_1/Modes_110/ ' out_loc filesep subj filesep num2str(a)]);
    end
    movefile(fullfile('../Cluster', subj, '*'), fullfile(out_loc, subj))
    rmdir(fullfile('../Cluster', subj))
end