% 删掉读进去为空的文件，以及DIRFILE文件
% 2024/03/07 zhumengying

% 创建一个空表格来存储数据
data = cell(0, 6);
headers = {'受试者id', 'Series Description', 'Rows', 'Columns', 'dicom文件个数'};
 
% % 创建一个空表格来存储数据
% data = cell(0, 4);
% headers = {'受试者id', 'Series Description', 'dicom文件个数'};

rootFolder = 'H:\重建数据\extract';%提取后放的位置
% 获取所有受试者文件夹
subjectIDS = dir(fullfile(rootFolder, 'sub*'));

% 遍历每个受试者文件夹
for i = 1:length(subjectIDS)
    subjectID = subjectIDS(i).name;

    % 获取序列文件夹路径 
    subFolder = fullfile(rootFolder, subjectID);
    sequenceFolders = dir(subFolder);
    sequenceFolders = sequenceFolders([sequenceFolders.isdir]); % 仅选择文件夹
    sequenceFolders = sequenceFolders(~ismember({sequenceFolders.name}, {'.', '..'})); % 排除当前和上级文件夹

    % 遍历每个序列文件夹
    for k = 1:length(sequenceFolders)
        sequenceName = sequenceFolders(k).name;
        
        % 获取序列文件夹路径
        sequenceFolder = fullfile(subFolder, sequenceName);
        
        % 读取.dcm文件并提取Series Description信息
        dcmFiles = dir(sequenceFolder);
        dcmFiles = dcmFiles(~ismember({dcmFiles.name}, {'.', '..'})); % 排除当前和上级文件夹
        for m = 1:length(dcmFiles)
            dcmFile = fullfile(sequenceFolder, dcmFiles(m).name);
            try
            % 读取 DICOM 文件
                image = dicomread(dcmFile);
                
                % 检查图像内容是否为空
                if isempty(image)
                    % 删除空文件
                    delete(dcmFile);
                    disp(['Deleted empty file: ', dcmFile]);
                else
                    info = dicominfo(dcmFile);
                    Rows = info.Rows;
                    Columns = info.Columns;
                end
            catch
                % 处理读取错误的情况
                disp(['Error reading file: ', dcmFile]);
            end

        end
        dcmFiles = dir(sequenceFolder);
        dcmFiles = dcmFiles(~ismember({dcmFiles.name}, {'.', '..'})); % 排除当前和上级文件夹
        N_dcmFiles = length(dcmFiles);
        % 将数据添加到表格中
        data = [data; {subjectID, sequenceName, Rows, Columns, N_dcmFiles}];
%         data = [data; {subjectID, sequenceName, N_dcmFiles}];
    end
end

% 将数据写入表格
dataTable = cell2table(data, 'VariableNames', headers);

% 将表格写入 Excel 文件
excelFileName = [rootFolder,'\数据集信息0926.xlsx']; % 输出 Excel 文件名
writetable(dataTable, excelFileName);
disp(['数据已成功写入 Excel 文件: ', excelFileName]);