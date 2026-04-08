% 为了做vbm分析，一般需要配准到标准空间，因为FSL的randomise spm都是基于标准空间的 使用ANTS
% 现在将其他模态配准到PD_T1


%需要再终端输入MATLAB打开，从桌面进去的画跑不了 在终端输入：
% export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6  # 确保这个路径是系统的libstdc++.so.6路径
% matlab
 
% 2025/03/01  zhumengying
% final

clc; clear;

% Set up paths and parameters
root = '/data1/zmy3/mapping_best/';
file_root = [root 'qulugu'];
file_t1t2_root = [root 'normalize_99'];
out_root = [root 't2m_2_pd']; % Save path
seq_t2m = 'T2Mapping';
seq_t2s = 'T2star_Mapping';
seq_t1w = 'T1W';
seq_t2w = 'T2W';
seq_t2flair = 'T2W_FLAIR';
ants_path = '/opt/ants/bin/'; % Path to ANTs binaries

root_pd = '/data1/zmy3/HD_registration/zmy2/';
PD_T1 = [root_pd 'HybraPD/PD_template_T1_flip_pa.nii.gz'];
% /data1/zmy3/HD_registration/zmy2/HybraPD/PD_template_T1_flip_pa.nii
PD_R2 = [root_pd 'HybraPD/PD_template_R2_flip_pa.nii.gz'];
PD_LABEL = [root_pd 'HybraPD/PD_template_label_Whole_flip_pa.nii.gz'];

% ANTs commands
ants_registration = [ants_path 'antsRegistrationSyN.sh'];
ants_apply_transforms = [ants_path 'antsApplyTransforms'];
tmp2ind_path = '/data1/zmy3/HD_registration/qulugu/tmp2ind_T1T2_zmy.sh';

% Create output directories if they do not exist
outpath_t2m = fullfile(out_root, seq_t2m);
if ~exist(outpath_t2m, 'dir')
    mkdir(outpath_t2m);
end

outpath_t2s = fullfile(out_root, seq_t2s);
if ~exist(outpath_t2s, 'dir')
    mkdir(outpath_t2s);
end

% List files in the directory
filePattern = fullfile(file_root, seq_t2m, ['*' seq_t2m '_brain.nii.gz']);
files = dir(filePattern);

%%
% 处理每个文件
for i = 1:length(files)
    T2Map_File = fullfile(files(i).folder, files(i).name);
    filename = strrep(files(i).name, ['_' seq_t2m '_brain.nii.gz'], '');  %sub001_HC  sub001

    T2star_Map_File = fullfile(file_root, seq_t2s, [filename '_' seq_t2s '_brain.nii.gz']);
    T2W_File = fullfile(file_t1t2_root, seq_t2w, [filename '_' seq_t2w '_normalized.nii.gz']);
    T1W_File = fullfile(file_t1t2_root, seq_t1w, [filename '_' seq_t1w '_normalized.nii.gz']);
    T2W_flair_File = fullfile(file_t1t2_root, seq_t2flair, [filename '_' seq_t2flair '_normalized.nii.gz']);

    % STEP 1: Register T2 mapping to PD_T1
    outputFile_t2m = fullfile(outpath_t2m, [filename '_' seq_t2m '_']);
    if ~exist([outputFile_t2m '1Warp.nii.gz'], 'file') || ~exist([outputFile_t2m '0GenericAffine.mat'], 'file')
        cmd1 = [ants_registration ' -d 3 -f ' PD_T1 ' -m ' T2Map_File ' -o ' outputFile_t2m ' -n 8'];
        disp(['Running: ' cmd1]);
        system(cmd1);
    else
        disp(['Skipping T2 mapping to PD_T1 registration for ' filename ' (results already exist)']);
    end

    % STEP 2: Register T2star mapping to PD_T1
    outputFile_t2s = fullfile(outpath_t2s, [filename '_' seq_t2s '_']);
    if ~exist([outputFile_t2s '1Warp.nii.gz'], 'file') || ~exist([outputFile_t2s '0GenericAffine.mat'], 'file')
        cmd2 = [ants_registration ' -d 3 -f ' PD_T1 ' -m ' T2star_Map_File ' -o ' outputFile_t2s ' -n 8'];
        disp(['Running: ' cmd2]);
        system(cmd2);
    else
        disp(['Skipping T2star mapping to PD_T1 registration for ' filename ' (results already exist)']);
    end

end


