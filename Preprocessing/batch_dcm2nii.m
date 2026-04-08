% 计划配准到T1W上，这里先将原始的dcm转成nii文件
% 2024/05/05  zhumengying

clc;clear;
% 设置 dcm2niix.exe 的路径
dcm2niix_exe = 'D:\download\MRIcroGL\Resources\dcm2niix.exe';

Series = 'T2W_FLAIR_SPIR_tra';  %要提取的序列名

% 设置输出文件夹路径
output_folder = ['H:\重建数据\dcm_to_nii\' Series];
if ~isfolder(output_folder)
    mkdir(output_folder); % 如果文件夹不存在，则创建文件夹
end

% 遍历 extract 文件夹下所有以 sub 开头的文件夹
extract_folder = 'H:\重建数据\extract';
sub_folders = dir(fullfile(extract_folder, 'sub*'));
for i = 1:length(sub_folders)
    % 获取受试者文件夹的名称，用作输出文件名
    subject_folder = sub_folders(i).name;
    
    % 构建输入文件夹路径
    input_folder = fullfile(extract_folder, subject_folder, Series);
    
    % 构建命令
    command = sprintf('%s -f "%s_T2W_FLAIR" -p y -z y -b n -o "%s" "%s"', ...
        dcm2niix_exe, subject_folder, output_folder, input_folder);
    
    % 执行命令
    system(command);

    disp(['Finished file: ', subject_folder]);  % 显示完成的受试者
end
