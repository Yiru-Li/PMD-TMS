clear all
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Defining Paths
output_directory = '/home/yl647/linux/PMD-TMS/';%output directory for the results
pmd_code_path = fullfile(output_directory, 'PMD_code');
addpath(pmd_code_path)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameter Set-up
subject = 'q005';%name of the subject
NModes=110;%number of modes
msh_file=fullfile(output_directory, subject, [subject '.msh']);
simnibs_installation_directory = '/usr/local/packages/simnibs/4.1.0';
msh_file_read_fcn = 'mesh_load_gmsh4';%useful for '.msh' msh-files. Also make sure the function is in the matlab search path. For '.mat' msh-files, it's not necessary.
msh_file_read_fcn_location = fullfile(simnibs_installation_directory, 'matlab_tools/');
m2m_dir = fullfile(output_directory, subject, ['m2m_' subject]);
FEMORD=1;%FEM order = 1,2, or, 3
run_mode='serial';%options = 'serial','parallel' (for HPC clusters);
%If parallel, provide the cluster parameters in a separate csv file (cluster_parameters.csv) (compatible with slurm scripting)
cluster_parameter_file = '/media/wang3007-1/Nahian_5TB/Research/Purdue_University/Professor_Gomez/Projects/Proj-2.1_PMD/Codes/Code_Github/Example_Scripts/cluster_parameters.csv';
th_hair = 0.0027;%distance of coil bottom center from scalp to accommodate hair thickness

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Mode Calculation
[output_folder] = compile(pmd_code_path,msh_file_read_fcn_location,output_directory,subject,simnibs_installation_directory);
main_offline_stage(pmd_code_path,msh_file,msh_file_read_fcn,msh_file_read_fcn_location,m2m_dir,NModes,FEMORD,...
                        output_folder,run_mode,cluster_parameter_file,th_hair,...
                        'sphere_density', 1, 'mapping_region', 'GM', ...
                        'coil_model_file', fullfile(output_directory, 'MagVenture_Cool-B65.mat'))

%% Optional name-value argument list to be provided to "main_offline_stage()"
%1. sphere_density = 5;%to specify the density of the standardized EEG points density. 
%                         The higher the number, the denser the points. default=5.
%2. patch_angle = 60;%The standardized EEG surface patch angle within which the points are sampled. default=60.
%
%3. eeg_mni_source_file = 'EEG10-10_UI_Jurak_2007.csv';%define the name of standard eeg-coordinate source file inside the
%                                                               m2m folder. Default is 'EEG10-10_UI_Jurak_2007.csv'. 
%                                                               If something different is required, provide the name of the file that
%                                                               is inside the ElectrodeCaps_MNI folder.
%4. coil_model_file = '';%specify the coil model file. If not provided, a Fig-8 coil model will be used.
%5. mapping_region = 'GM';%options = ['GM','WM','GM+WM','head',''];If nothing is specified, 
%                               provide a list of teids inside the msh file as a separate field; default = 'GM+WM';
                                                            
