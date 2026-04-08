% 画出ROI 看看配准效果 AAL,发现有很多小点点，肯定是不太对的    PD模板
% % 对配准之后的ROI进行处理 没有形态学操作  合并  阈值  腐蚀，对DN，小roi有两个阈值
% 对结构像处理
% 2025/02/27 zhumengying

% 尾状核（CN）、壳核（PU）、苍白球外部/内部（GPe/GPi）、丘脑（TH）、红核（RN）、SN（黑质）和DN（齿状核）

clc; clear;close all;

% 设置输入文件路径
seq = 't1w_t2w';
t2w_file_root = 'H:\重建数据\mapping_unet_best\peizhun\Register_jiegouxiang_1vs1\T2W';
input_file_root = ['H:\重建数据\mapping_unet_best\peizhun\Register_jiegouxiang_1vs1\' 'T1W_T2W'];
input_file_seq = ['H:\重建数据\mapping_unet_best\normalize_99_mask\' 'T1W_T2W'];  %去颅骨后T2mapping的路径，只是作为叠在底下的文件
output_path = input_file_root;

% 打开文件，如果文件不存在会创建一个新文件
fileID = fopen([output_path '\ROI_processed\腐蚀.txt'], 'a');  % 'a' 表示追加模式

% 定义合并后的ROI
roiInfo = struct('Value', { [301, 302], ...  % Pu
                            [303, 304], ...  % Ca
                            [309, 310], ...  % GPe
                            [311, 312], ...  % GPi
                            [313, 314, 315, 316], ...  % SN
                            [317, 318], ...  % RN
                            [323, 324, 325, 326, 327, 328, 329, 330, 331, 332], ...  % TH
                            [333, 334]}, ... % DN
                 'Name', {'Pu', 'Ca', 'GPe', 'GPi', 'SN', 'RN', 'TH', 'DN'});

% 定义输出文件夹
outpath_ROI = [output_path '\ROI_processed\T2_腐蚀1'];
if ~exist(outpath_ROI, 'dir')
    mkdir(outpath_ROI);
end

% 列出文件夹中以序列名+.nii.gz结尾的文件
filePattern = fullfile(t2w_file_root, 'sub*_PD_LABEL_registered.nii.gz'); % 35个受试者
files = dir(filePattern);

% 定义颜色映射
colorMap = jet(length(roiInfo)); % 使用JET颜色映射

% 遍历找到的文件，并进行处理
for i = 1:length(files)
    atlasFile_gz = fullfile(files(i).folder, files(i).name);
    filename = strrep(files(i).name, '_PD_LABEL_registered.nii.gz', '');  %sub001_HC  sub001

    % 排除 "sub009_HC"
    if ~strcmp(filename, 'sub009_HC') % 检查是否为 "sub009_HC

        % 读取 NIfTI 文件数据
        atlas = niftiread(atlasFile_gz);
        atlasRounded = round(atlas);
        seqFile = [input_file_seq '\' filename '_' seq '_normalized.nii.gz'];
        seq_image = niftiread(seqFile);
    
        % 读取头文件信息
        atlasInfo = niftiinfo(atlasFile_gz);
    
        % 初始化保存求和结果的变量
        roiSums = struct('Name', {roiInfo.Name}, 'OriginalSum', [], 'ProcessedSum', []);
    
        % 创建一个RGB图像，初始化为原始图像
        rgbImage = repmat(seq_image, [1 1 1 3]);
        rgbImage = uint8(255 * mat2gray(rgbImage)); % 将图像转换为0-255范围内的uint8类型
    
        % 初始化新的 ROI 映射
        newAtlas = zeros(size(atlasRounded));
    
        % 提取 ROI 并使用不同颜色表示
        for j = 1:length(roiInfo)
            roiValues = roiInfo(j).Value; % 直接使用数值数组
            roiMask = ismember(atlasRounded, roiValues); % 创建ROI掩膜
    
    %         % 定义形态学结构元素
    %         se_open_small = strel('cube', 2); % 2x2x2 的立方体结构元素
    %         se_close_small = strel('cube', 2); % 2x2x2 的立方体结构元素
    % 
    %         pro_roiMask = imclose(roiMask, se_close_small);  %填补空洞  膨胀后再腐蚀
    % %         pro_roiMask = imopen(pro_roiMask, se_open_small);% 这会失去很多很多mask，因为尾状核有一些尖尖
            pro_roiMask = bwareaopen(roiMask, 4); % 删除小区域
    %         pro_roiMask = roiMask;
    
         %% 给他剔除大值
    %         修正 mask，将 seq_image 中对应位置值大于2的部分也加入 mask
            pro_roiMask(seq_image < 0.2) = 0;
            pro_roiMask_raw = pro_roiMask;
    
            % 对每个切片进行腐蚀操作，想腐蚀边边一个圈
            se = strel('disk', 2);  % 创建一个圆形结构元素
    
            % 假设 pro_roiMask 是你的三维数据集，例如 pro_roiMask(:,:,z) 表示第 z 层
            for z = 1:size(pro_roiMask, 3)
                for n = 1:1  %腐蚀多次,但这样尖尖也就没了，但细细长长的尾状核，一腐蚀也没了
                    pro_roiMask(:,:,z) = imerode(pro_roiMask(:,:,z), se);  % 对每一层面进行腐蚀操作
                end
            end
    
            if sum(pro_roiMask(:))<5
                outputStr = ['腐蚀后roi小于5 ', filename, ' ', roiInfo(j).Name, ' ', num2str(sum(pro_roiMask(:)))];
                % 将字符串写入到文件
                fprintf(fileID, '%s\n', outputStr);
                pro_roiMask_raw(seq_image < 0.4) = 0;  % 给他多设置一个阈值
                pro_roiMask = pro_roiMask_raw;
            end
    
    %         se = strel('square', 2);
    %         for z = 1:size(pro_roiMask, 3)
    %             for n = 1:1  %腐蚀多次
    %                 pro_roiMask(:,:,z) = imerode(pro_roiMask(:,:,z), se);
    %             end
    %         end
    
    %         Data = seq_image(pro_roiMask);
    %         Mean = mean(Data)
    
    
            % 计算每个掩膜的和
            originalSum = sum(roiMask(:));
            processedSum = sum(pro_roiMask(:));
    
            % 将结果保存到结构中
            roiSums(j).ProcessedSum = processedSum;
            roiSums(j).OriginalSum = originalSum;
    
    %         figure;imshow3D(roiMask)
    %         figure;imshow3D(pro_roiMask)
    %         figure;imshow3D(abs(roiMask-pro_roiMask))
    
            % 更新新的 ROI 映射，避免重叠
            newAtlas = newAtlas + pro_roiMask * roiValues(1);  
            
            % 更新 RGB 图像
            for k = 1:3
                rgbImage(:,:,:,k) = rgbImage(:,:,:,k) + uint8(pro_roiMask) * uint8(255 * colorMap(j, k));
            end

        end
    
        % 限制 RGB 值在 [0, 255] 范围内
        rgbImage = min(rgbImage, 255);
        
        %% 保存成 GIF
        [~, ~, numFrames, ~] = size(rgbImage);
        gifFileName = fullfile(outpath_ROI, [filename '_processedROI.gif']);
        
        for frame = 1:numFrames
            [A, map] = rgb2ind(squeeze(rgbImage(:,:,frame,:)), 256);
            if frame == 1
                imwrite(A, map, gifFileName, 'gif', 'LoopCount', Inf, 'DelayTime', 0.8);
            else
                imwrite(A, map, gifFileName, 'gif', 'WriteMode', 'append', 'DelayTime', 0.8);
            end
        end
        
        %% 显示处理后的图像
        figure_handle = figure;
        imshow3D(rgbImage);    
        
        % 保存 .fig 文件
        figFileName = fullfile(outpath_ROI, [filename '_processedROI.fig']);
        savefig(figure_handle, figFileName);    
        
        % 关闭图形窗口（可选）
        close(figure_handle);
        
        % 保存求和结果
        save(fullfile(outpath_ROI, [filename '_roiSums.mat']), 'roiSums');
        
        % 保存处理后的 ROI 映射为 .nii.gz 文件
        newAtlasFileName = fullfile(outpath_ROI, [filename '_processedROI']);
        niftiwrite(newAtlas, newAtlasFileName, atlasInfo, 'Compressed', true);
        disp([filename '提取并着色完成']);
    end
end

% 关闭文件
fclose(fileID);

disp('所有ROI提取并着色完成');

% PD 模板中的具体编号：
%   301     "Left Pu"        Pu
%   302     “Right Pu”       Pu
%   303     "Left Ca"        CN
%   304      Right Ca”       CN
%   309     “Left GPe”
%   310     “Right GPe”
%   311     “Left GPi”
%   312     “Right GPi”
%   313     “Left SNr”      SN
%   314     “Right SNr”     SN
%   315      Left SNc”      SN
%   316     “Right SNc”     SN
%   317     “Left RN”
%   318     “Right RN”
%   323     “Left TH.AN”
%   324     “Right TH.AN”
%   325     “Left TH.MN”
%   326     “Right TH.MN”
%   327     “Left TH.IM”
%   328     “Right TH.IM”
%   329     “Left TH.VN”
%   330     “Right TH.VN”
%   331     “Left TH.P”
%   332     “Right TH.P”
%   333     “Left DN”
%   334     “Right DN”

