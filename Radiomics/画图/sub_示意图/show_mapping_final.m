% 查看nii文件  一个受试者4个模态的图像 还要加上T1W/T2W
% 2025/08/02 zhumengying

% 配准前
clc;clear;close all;
% 指定图像文件路径
file_root = 'H:\重建数据\mapping_unet_best\swapdim\';
seqs = {'T2Mapping', 'T2star_Mapping', 'T1W', 'T2W', 'T2W_FLAIR', 'T1W_T2W'};

% 去掉 '_T2Mapping_brain' 部分
base_name = 'sub011_HC';  %sub011_HC  sub022  
% 将下划线替换为空格
filename_title = strrep(base_name, '_', ' ');

for s = 1:length(seqs)
    if s <3

        inputFile = fullfile(file_root, seqs{s}, [base_name, '_' seqs{s} '_brain.nii.gz']);
%         inputFile = fullfile(file_root, [seqs{s} '2'], [base_name, '_' seqs{s} '_brain.nii.gz']);
%     elseif s==6
%         inputFile = fullfile('H:\重建数据\mapping_unet_best\normalize_99_mask\t1w_t2w', [base_name, '_t1w_t2w_normalized_mask.nii.gz']);
    else
        inputFile = fullfile(file_root, seqs{s}, [base_name, '_' seqs{s} '_normalized.nii.gz']);
    end

    if exist(inputFile, 'file')
        % 读取NIfTI格式图像文件
        nii_data = niftiread(inputFile);

    else
        % 文件不存在，跳过
        fprintf('File not found: %s\n', inputFile);
        continue; % 跳过当前循环，继续下一个
    end
    
    % 获取图像的尺寸和切片数
    [dim1, dim2, num_slices] = size(nii_data);        
    
    if strcmp(seqs{s}, 'T2Mapping') || strcmp(seqs{s}, 'T2star_Mapping')
        slices = [13,12,11,8];  %mapping间隔是3正好对应结构像间隔2张
    else
        slices = [13,12,11,9];
    end

    % 初始化大图像
    h_small = dim1;
    w_small = dim2;
    h_big = 1 * h_small;  % 大图像的高度
    w_big = length(slices) * w_small;  % 大图像的宽度
    big_image = zeros(h_big, w_big);
    
    % 拼接图像
    count = 1;
    for row = 1:2
        for col = 1:11
            if count <= length(slices)
                % 获取当前切片
                slice = rot90(squeeze(nii_data(:, :, slices(count))));
                
                % 计算在大图像中的位置
                start_row = (row - 1) * h_small + 1;
                end_row = row * h_small;
                start_col = (col - 1) * w_small + 1;
                end_col = col * w_small;
                
                % 将切片放入大图像
                big_image(start_row:end_row, start_col:end_col) = slice;
                
                % 更新计数器
                count = count + 1;
            end
        end
    end
    
    if strcmp(seqs{s}, 'T2Mapping') || strcmp(seqs{s}, 'T2star_Mapping')  
%         big_image
        figure();imshow(big_image*100, [0 200]); % 设置显示范围
%         colormap jet; %colorbar;
        % 添加颜色条并设置单位标签
%         c = colorbar;
%         c.Label.String = 'ms'; % 设置单位标签
%         c.Label.FontSize = 12; % 调整字体大小
        
        % 可选：手动设置刻度和标签
        c.Ticks = 0:50:200; % 设置刻度位置
        c.TickLabels = {'0', '50', '100', '150', '200'}; % 设置刻度标签
        c.FontSize = 14; % 增大字体大小（默认值通常为 10）
    else
        figure();imshow(big_image, [0 1]); % 设置显示范围
        colorbar;
%         c = colorbar;
        c.Ticks = 0:0.2:1; % 设置刻度位置
        c.TickLabels = {'0', '0.2', '0.4', '0.6', '0.8', '1'}; % 设置刻度标签
        c.FontSize = 14; % 增大字体大小（默认值通常为 10）
    end
end
% sgtitle(filename_title,'FontSize', 11); % 整个大图的标题