%受试者序列名和Series Description没有对应上，想输出每个受试者名，以及序列命名和Series Description
%2024/03/06 zhumengying

clc;clear;

% 创建一个空表格来存储数据
data = cell(0, 6);
headers = {'受试者id', '受试者名', 'study名', '序列名', 'Series Description', '仪器名', 'TE', 'dicom文件个数'};

% 根文件夹路径
rootFolder = 'H:\重建数据\亨廷顿舞蹈症'; % 替换为您的根文件夹路径

% 获取所有受试者文件夹
subjectIDS = dir(fullfile(rootFolder, 'sub*'));

% 遍历每个受试者文件夹
for i = 1:length(subjectIDS)
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
            N_dcmFiles = length(dcmFiles);
%             for m = 1:length(dcmFiles)
            dcmFile = fullfile(sequenceFolder, dcmFiles(1).name);
            info = dicominfo(dcmFile);
            seriesDescription = info.SeriesDescription;
            manufacturer_model = info.ManufacturerModelName;
            % 检查是否存在 EchoTime (TE)
            if isfield(info, 'EchoTime')
                TE = info.EchoTime;
            else
                TE = '没有找到';
            end

            % 将数据添加到表格中
            data = [data; {subjectID, subjectname.name, studyName, sequenceName, seriesDescription, manufacturer_model, TE, N_dcmFiles}];
                
%                 % 显示受试者名、序列名和Series Description
%                 disp(['受试者名: ', subjectName, ', 序列名: ', sequenceName, ', Series Description: ', seriesDescription]);
%             end
        end
    end
end

% 将数据写入表格
dataTable = cell2table(data, 'VariableNames', headers);

% 将表格写入 Excel 文件
excelFileName = [rootFolder,'\数据集信息.xlsx']; % 输出 Excel 文件名
writetable(dataTable, excelFileName);
disp(['数据已成功写入 Excel 文件: ', excelFileName]);
