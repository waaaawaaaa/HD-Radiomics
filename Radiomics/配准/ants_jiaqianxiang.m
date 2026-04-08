%配准将标准空间的PD模版配准到结构像  使用ANTS
% 先将T1W T2W配准到T2 FLAIR，再使用PD的T1W R2共同配准到受试者的T2 FLAIR T2W

% 最有应用再LABEL中

%需要再终端输入MATLAB打开，从桌面进去的画跑不了 在终端输入：
% export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6  # 确保这个路径是系统的libstdc++.so.6路径
% matlab
 
% 2025/01/12  zhumengying
% final

clc; clear;

% Set up paths and parameters
root = '/data1/zmy3/mapping_best/';
file_root = [root 'normalize_99'];
out_root = [root 'Register_jiegouxiang']; % Save path
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
outpath_pd = fullfile(out_root, 'PD2T2flair');
if ~exist(outpath_pd, 'dir')
    mkdir(outpath_pd);
end


outpath_t1w = fullfile(out_root, [seq_t1w '_2_t2flair']);
if ~exist(outpath_t1w, 'dir')
    mkdir(outpath_t1w);
end

outpath_t2w = fullfile(out_root, [seq_t2w '_2_t2flair']);
if ~exist(outpath_t2w, 'dir')
    mkdir(outpath_t2w);
end


% List files in the directory

filePattern = fullfile(file_root, seq_t2flair, ['*' seq_t2flair '_normalized.nii.gz']);
files = dir(filePattern);

%%
% 处理每个文件
for i = 1:length(files)
    T2flair_File = fullfile(files(i).folder, files(i).name);
    filename = strrep(files(i).name, ['_' seq_t2flair '_normalized.nii.gz'], '');  %sub001_HC  sub001

    T2W_File = fullfile(file_root, seq_t2w, [filename '_' seq_t2w '_normalized.nii.gz']);
    T1W_File = fullfile(file_root, seq_t1w, [filename '_' seq_t1w '_normalized.nii.gz']);

    % STEP 1: Register T1W to T2flair
    outputFile_t1w = fullfile(outpath_t1w, [filename '_' seq_t1w '_']);
    if ~exist([outputFile_t1w '1Warp.nii.gz'], 'file') || ~exist([outputFile_t1w '0GenericAffine.mat'], 'file')
        cmd1 = [ants_registration ' -d 3 -f ' T2flair_File ' -m ' T1W_File ' -o ' outputFile_t1w ' -n 8'];
        disp(['Running: ' cmd1]);
        system(cmd1);
    else
        disp(['Skipping T1W to T2 flair registration for ' filename ' (results already exist)']);
    end

    % STEP 2: Register T2W to T2flair
    outputFile_t2w = fullfile(outpath_t2w, [filename '_' seq_t2w '_']);
    if ~exist([outputFile_t2w '1Warp.nii.gz'], 'file') || ~exist([outputFile_t2w '0GenericAffine.mat'], 'file')
        cmd1 = [ants_registration ' -d 3 -f ' T2flair_File ' -m ' T2W_File ' -o ' outputFile_t2w ' -n 8'];
        disp(['Running: ' cmd1]);
        system(cmd1);
    else
        disp(['Skipping T2W to T2 flair registration for ' filename ' (results already exist)']);
    end
    

    % STEP 3: Register PD to T2W t1w 
    out_t1t2 = fullfile(outpath_pd, [filename '_t1wt2w_t1r2']);
    t2w_warped = [outputFile_t2w 'Warped.nii.gz'];
    t1w_warped = [outputFile_t1w 'Warped.nii.gz'];

    cmd_t1t2 = [tmp2ind_path ' --T1ind=' t1w_warped ' --T2ind=' t2w_warped ' --T1tmp=' PD_T1 ...
        ' --T2tmp=' PD_R2 ' --Atmp=' PD_LABEL ' --outdir=' out_t1t2 ' --nthreads=16'];

    disp(['Running: ' cmd_t1t2]);
    system(cmd_t1t2);
end


