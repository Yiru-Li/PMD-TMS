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
%% gather info from spreadsheet
for k = 234:height(masterlist) %229
    subj = masterlist.Subject{k};
    subjects_folder = masterlist.Location{k};
    mesh_path = '';
    while isempty(mesh_path)
        subjects_folder = [subjects_folder filesep '*'];
        mesh_path = dir([subjects_folder filesep subj '.msh']);
    end
    th_hair = masterlist.HT(k)/1e3;
    %% run stage 1 locally
    if ~isfolder([cluster_loc subj '/FEM_1'])
        if ~isfolder(fullfile('../Cluster', subj))
            mkdir(fullfile('../Cluster', subj));
            copyfile(fullfile(mesh_path.folder, mesh_path.name), fullfile('../Cluster', subj));
            %         copyfile(fullfile(mesh_path.folder, ['m2m_' subj]), fullfile('../Cluster', subj, ['m2m_' subj]), 'f');
            system(sprintf('cp -r %s %s', fullfile(mesh_path.folder, ['m2m_' subj]), fullfile('../Cluster', subj, ['m2m_' subj])))
        end
        alt_stage_1(subj, th_hair, 1, 1);
        % push info to cluster
        system(['mv ../Cluster/' subj ' ' cluster_loc]);
%         system(['rsync -rv --size-only --delete ../Cluster/ ' cluster_loc]);
    end
    system(['ssh ' cluster_user ' qsub PMD-TMS/array_run_mode_generation_cpu.sh ' subj ' ' num2str(th_hair)]);
%     % stage 2
%     subTime = tic;
%     while length(dir(['/Volumes/Data/Neacsiu/NATURE.01/Analysis/efield_scripts/E-ref/' subj '/FEM_1/Modes_110/coil2roi_*']))<110
%         pause(60)
%         if toc(subTime)>60*60*2 % if job hanged, delete and resubmit
%             system(['ssh ' cluster_user ' qdel ' subj '.msh-2.sh ' subj '.msh-3.sh ' subj '.msh-4.sh']);
%             system(['ssh ' cluster_user ' qsub PMD-TMS/array_run_mode_generation_cpu.sh ' subj ' ' num2str(th_hair)]);
%             subTime = tic;
%         end
%     end
%     % stage 3
%     subTime = tic;
%     while length(dir(['/Volumes/Data/Neacsiu/NATURE.01/Analysis/efield_scripts/E-ref/' subj '/FEM_1/Modes_110/B_*']))<110
%         pause(60)
%         if toc(subTime)>60*60*2 % if job hanged, delete and resubmit
%             system(['ssh ' cluster_user ' qdel ' subj '.msh-3.sh ' subj '.msh-4.sh']);
%             system(['ssh ' cluster_user ' qsub PMD-TMS/array_run_mode_generation_cpu.sh ' subj ' ' num2str(th_hair)]);
%             subTime = tic;
%         end
%     end
%     % stage 4
%     subTime = tic;
%     while length(dir(['/Volumes/Data/Neacsiu/NATURE.01/Analysis/efield_scripts/E-ref/' subj '/FEM_1/Modes_110/Q_*']))<110
%         pause(60)
%         if toc(subTime)>60*60*2 % if job hanged, delete and resubmit
%             system(['ssh ' cluster_user ' qdel ' subj '.msh-4.sh']);
%             system(['ssh ' cluster_user ' qsub PMD-TMS/array_run_mode_generation_cpu.sh ' subj ' ' num2str(th_hair)]);
%             subTime = tic;
%         end
%     end
%     while ~system(['ssh ' cluster_user ' qstat -j ' subj '.msh-4.sh']) % if job is still running
%         pause(60);
%         if toc(subTime)>60*60*2 % job hanged
%             system(['ssh ' cluster_user ' qsub PMD-TMS/array_run_mode_generation_cpu.sh ' subj ' ' num2str(th_hair)]);
%             subTime = tic;
%             pause(600);
%         end
%     end
    while length(dir([cluster_loc subj '/FEM_1/Modes_110/B_*']))<110
        pause(600);
        while ~system(['ssh ' cluster_user ' qstat -j S' subj '.msh-4.sh']) % if job is still running
            pause(60);
        end
        pause(60);
        if length(dir([cluster_loc subj '/FEM_1/Modes_110/B_*']))<110 % failed during stage 4
            system(['ssh ' cluster_user ' qsub PMD-TMS/array_run_mode_generation_cpu.sh ' subj ' ' num2str(th_hair)]);
        end
    end
    %% pull info from cluster
    pause(60); % give the system a minute to react
    system(['mv ' cluster_loc subj ' ' out_loc filesep]);
    system(['rsync -dv --include="*.out" --exclude="*" ' ...
        cluster_user ':./PMD-TMS/ ' out_loc filesep subj]);
    system(['ssh ' cluster_user ' "rm ./PMD-TMS/*.out"']);
end