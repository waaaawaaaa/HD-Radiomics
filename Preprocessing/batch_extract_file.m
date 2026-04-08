% 提取出需要的数据，放到extract文件夹,dicom文件要大于1，不然可能是错的
% 将所有序列采集的文件提取出来，文件夹以序列名命名,删除打不开的文件
% 2024/03/18 zhumengying

clc;clear;

% 根文件夹路径
rootFolder = 'G:\重建数据\亨廷顿舞蹈症'; % 替换为您的根文件夹路径
% Series = 'OLED_T2';  %要提取的序列名OLED_T2star   T2W_TSE
outFolder = 'G:\重建数据\extract_batch';%提取后放的位置

% 获取所有受试者文件夹
subjectIDS = dir(fullfile(rootFolder, 'sub*'));

% 遍历每个受试者文件夹
% parfor i = 6:length(subjectIDS)
parfor i = 6:16
    subjectID = subjectIDS(i).name;
    
    % 获取受试者姓名文件夹路径
    subjectname = dir(fullfile(rootFolder, subjectID));
    subjectname = subjectname([subjectname.isdir]); % 仅选择文件夹
    subjectname = subjectname(~ismember({subjectname.name}, {'.', '..'})); % 排除当前和上级文件夹
    
    % 获取study文件夹
    subject_path = fullfile(rootFolder,subjectID,subjectname.name);
    studyFolders = dir(fullfile(subject_path, 'S*'));
    
    % 遍历每个study文件夹
    for j = 1:length(studyFolders)
        studyName = studyFolders(j).name;
        
        % 获取study文件夹路径
        studyFolder = fullfile(subject_path, studyName);
        
        % 获取序列文件夹
        sequenceFolders = dir(fullfile(studyFolder, 'S*'));
        
        % 遍历每个序列文件夹
        for k = 1:length(sequenceFolders)
            sequenceName = sequenceFolders(k).name;
            
            % 获取序列文件夹路径
            sequenceFolder = fullfile(studyFolder, sequenceName);
            
            % 读取.dcm文件并提取Series Description信息
            dcmFiles = dir(fullfile(sequenceFolder, 'I*'));
%             N_dcmFiles = length(dcmFiles);
            for m = 1:length(dcmFiles)  % 读取每一个image文件
                dcmFile = fullfile(sequenceFolder, dcmFiles(m).name);

                try
                % 读取 DICOM 文件
                    image = dicomread(dcmFile);
    
                    % 检查图像内容是否为空
                    if ~isempty(image)
                        info = dicominfo(dcmFile);
                        seriesDescription = info.SeriesDescription;
%                         Rows = info.Rows;
%                         Columns = info.Columns;
                        % 指定新文件夹路径
                        % 创建新文件夹用于存储符合条件的文件
                        outputFolder = fullfile(outFolder,subjectID, seriesDescription); % 替换为您希望存储文件的文件夹路径
                        if ~exist(outputFolder, 'dir')
                            mkdir(outputFolder);
                        end
                        
                        % 复制文件并更改文件名
                        newFileName = fullfile(outputFolder, dcmFiles(m).name);
                        copyfile(dcmFile, newFileName);
%                         disp(['Copied non-empty file to new folder: ', newFilePath]);
                    end
                catch
                    % 处理读取错误的情况
                    disp(['Error reading file: ', dcmFile]);
                end
                    
%                 % 检查Series Description是否为"OLED"或"OLED2"
%                 if contains(seriesDescription, Series) || contains(seriesDescription, [Series,'2'])
%                     if N_dcmFiles>1
%                         seriesDescriptionFound = true;
%                         break; % 只需在文件夹中找到一个符合条件的文件即可
%                     end
%                 end
            end
        end

%         if seriesDescriptionFound
%             % 复制文件夹到输出文件夹并更改名称
%             outputFolder = fullfile(outFolder,subjectID, Series); % 替换为您希望存储文件的文件夹路径
%             
%             copyfile(sequenceFolder, outputFolder);
%         end

%                 % 创建新文件夹用于存储符合条件的文件
%                 outputFolder = fullfile(outFolder,subjectID, Series); % 替换为您希望存储文件的文件夹路径
%                 if ~exist(outputFolder, 'dir')
%                     mkdir(outputFolder);
%                 end
%                 
%                 % 复制文件并更改文件名
%                 newFileName = fullfile(outputFolder, 'oled.dcm');
% %                 copyfile(dcmFile, newFileName);
%             end
% 
%             
%         end
    end
    disp(['copied file: ', subjectID]);  % 显示完成的受试者
end

