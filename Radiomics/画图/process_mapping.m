% 想画出没有腐蚀的ROI
% 2024/12/16 zhumengying

% 尾状核（CN）、壳核（PU）、苍白球外部/内部（GPe/GPi）、丘脑（TH）、红核（RN）、SN（黑质）和DN（齿状核）

clc; clear;close all;

% 设置输入文件路径
seq = 'T2Mapping';
input_file_root = 'H:\重建数据\mapping_unet_best\peizhun\PD_out_t2m';
input_file_seq = ['H:\重建数据\mapping_unet_best\qulugu\' seq];  %去颅骨后T2mapping的路径，只是作为叠在底下的文件
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
outpath_ROI = [output_path '\ROI_processed\' seq '\T2_腐蚀1'];
if ~exist(outpath_ROI, 'dir')
    mkdir(outpath_ROI);
end

% 列出文件夹中以序列名+.nii.gz结尾的文件
filePattern = fullfile(input_file_root, 'zmy_PD2T2W', 'sub*_t1wt2w_t1r2', 'pA_tmp2ind.nii.gz'); % 35个受试者
files = dir(filePattern);

% 定义颜色映射
colorMap = jet(length(roiInfo)); % 使用JET颜色映射

% 遍历找到的文件，并进行处理
for i = 2%1:length(files)
    atlasFile_gz = fullfile(files(i).folder, files(i).name);
    filename_parts_raw = split(files(i).folder, '\');
    filename = strrep(filename_parts_raw{end}, '_t1wt2w_t1r2', '');  %sub001_HC  sub001

    % 读取 NIfTI 文件数据
    atlas = niftiread(atlasFile_gz);
    atlasRounded = round(atlas);
    seqFile = [input_file_seq '\' filename '_' seq '_brain.nii.gz'];
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

        pro_roiMask = bwareaopen(roiMask, 4); % 删除小区域
%         pro_roiMask = roiMask;

     %% 给他剔除大值
%         修正 mask，将 seq_image 中对应位置值大于2的部分也加入 mask
        pro_roiMask(seq_image > 2) = 0;


        % 计算每个掩膜的和
        originalSum = sum(roiMask(:));
        processedSum = sum(pro_roiMask(:));

        % 将结果保存到结构中
        roiSums(j).ProcessedSum = processedSum;
        roiSums(j).OriginalSum = originalSum;

        % 更新新的 ROI 映射，避免重叠
        newAtlas = newAtlas + pro_roiMask * roiValues(1);  
        
        % 更新 RGB 图像
        for k = 1:3
            rgbImage(:,:,:,k) = rgbImage(:,:,:,k) + uint8(pro_roiMask) * uint8(255 * colorMap(j, k));
        end
    end
    
    % 限制 RGB 值在 [0, 255] 范围内
    rgbImage = min(rgbImage, 255);
    
    
    %% 显示处理后的图像
    figure_handle = figure;
    imshow3D(rgbImage);    
    
    % 保存 .fig 文件
    figFileName = fullfile(outpath_ROI, [filename '_processedROI.fig']);
    savefig(figure_handle, figFileName);    
    
    % 关闭图形窗口（可选）
    close(figure_handle);
    
    % 保存处理后的 ROI 映射为 .nii.gz 文件
    newAtlasFileName = fullfile(outpath_ROI, [filename '_processedROI']);
    niftiwrite(newAtlas, newAtlasFileName, atlasInfo, 'Compressed', true);
    disp([filename '提取并着色完成']);
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

