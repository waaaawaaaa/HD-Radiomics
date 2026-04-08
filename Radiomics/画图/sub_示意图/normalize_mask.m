%对结构像归一化   要不要先 × brain_mask??   除去背景来归一化
% 2025/12/29 zhumengying

clc;clear;
file_root = 'H:\重建数据\mapping_unet_best\';
seqs = {'T1W', 'T2W', 'T2W_FLAIR'};
% file_output = fullfile(file_root,'normalize_99');

for s = 1:length(seqs)
    file_seq = fullfile(file_root,'swapdim', seqs{s});
    files = dir(fullfile(file_seq, '*brain.nii.gz'));

    % 遍历找到的文件，并进行处理
    for i = 1:length(files)
        % 去掉 '_T2Mapping_brain' 部分
        base_name = strrep(files(i).name, ['_' seqs{s} '_brain.nii.gz'], '');  %sub001_HC  sub001
        % 将下划线替换为空格
        filename_title = strrep(base_name, '_', ' ');

        % 构建完整的输入文件路径
        input_file = fullfile(file_seq, files(i).name);
        
        % 读取 NIfTI 格式的图像数据
        nii_data = niftiread(input_file);
        nii_info = niftiinfo(input_file);

        % 将图像数据归一化到 [0, 1] 范围
        nii_data_min = min(nii_data(:));  % 获取图像的最小值
%         nii_data_max = max(nii_data(:));  % 获取图像的最大值
        nii_data_max = prctile(nii_data(nii_data>0),99);  % 采用95%的值作为最大值来归一化
        nii_data_normalized = (nii_data - nii_data_min) / (nii_data_max - nii_data_min);  % 归一化

        % 构建输出文件名
        output_filename = fullfile(file_seq, [base_name '_' seqs{s} '_normalized.nii']);

        % 保存修改后的 NIfTI 数据为新文件
        niftiwrite(nii_data_normalized, output_filename, nii_info, 'Compressed', true);
        disp(['NIfTI 文件保存成功：', output_filename]);
    end
end