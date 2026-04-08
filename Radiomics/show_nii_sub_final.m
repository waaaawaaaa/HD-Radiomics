% 查看nii文件  一个受试者五个模态的图像
% 2024/12/14 zhumengying

% 配准前
clc;clear;close all;
% 指定图像文件路径
file_root = 'H:\重建数据\mapping_unet_best\qulugu\';
seqs = {'T2Mapping', 'T2star_Mapping', 'T1W', 'T2W', 'T2W_FLAIR'};

% 列出文件夹中以序列名+.nii.gz结尾的文件
filePattern = fullfile(file_root, seqs{1}, '*brain.nii.gz');
files = dir(filePattern);

% 遍历找到的文件，并进行处理
for i = 1:length(files)
    % 去掉 '_T2Mapping_brain' 部分
    base_name = strrep(files(i).name, ['_' seqs{1} '_brain.nii.gz'], '');  %sub001_HC  sub001
    % 将下划线替换为空格
    filename_title = strrep(base_name, '_', ' ');

    figure('Position', [0, -20, 900, 700]);  % 设置图像大小
    % 使用 tiledlayout 创建一个紧密排布的布局
    tiledlayout(5, 1, 'TileSpacing', 'none', 'Padding', 'none'); % 'none' 去除间隙
    for s = 1:length(seqs)
        if s <3

            inputFile = fullfile(file_root, seqs{s}, [base_name, '_' seqs{s} '_brain.nii.gz']);
        else
            inputFile = fullfile('H:\重建数据\mapping_unet_best\normalize_99', seqs{s}, [base_name, '_' seqs{s} '_normalized.nii.gz']);
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
        
        % 初始化大图像
        h_small = dim1;
        w_small = dim2;
        h_big = 2 * h_small;  % 大图像的高度
        w_big = 11 * w_small;  % 大图像的宽度
        big_image = zeros(h_big, w_big);
        
        % 拼接图像
        count = 1;
        for row = 1:2
            for col = 1:11
                if count <= num_slices
                    % 获取当前切片
                    slice = rot90(squeeze(nii_data(:, :, num_slices+1-count)));
                    
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
        
        nexttile;
        if strcmp(seqs{s}, 'T2Mapping') || strcmp(seqs{s}, 'T2star_Mapping')
            imshow(big_image, [0 2]); % 设置显示范围
            colormap jet;
        else
            imshow(big_image, [0 1]); % 设置显示范围
        end
    end
    sgtitle(filename_title,'FontSize', 11); % 整个大图的标题
end