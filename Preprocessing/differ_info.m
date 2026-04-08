% 要比较两张 DICOM 图像的头文件（header）
% 2024/03/07 zhumengying

% clc;clear;
% 读取第一个 DICOM 文件的头信息
% dicomFile1 = 'G:\重建数据\亨廷顿舞蹈症\sub033\20230709 zhang tao\S72615\S4010\I10'; % 替换为第一个 DICOM 文件路径
dicomFile1 = 'H:\重建数据\extract\sub003\OLED_T2\I10'; % 替换为第一个 DICOM 文件路径
% dicomFile1 = 'G:\重建数据\亨廷顿舞蹈症\sub017\20230514 xu ai zhen\S72653\S8010\I10';
info1 = dicominfo(dicomFile1);

% 读取第二个 DICOM 文件的头信息
dicomFile2 = 'H:\重建数据\extract\sub020\OLED_T2\I10'; % 替换为第二个 DICOM 文件路径
info2 = dicominfo(dicomFile2);

% 比较两个 DICOM 文件的头信息字段
fields1 = fieldnames(info1);
fields2 = fieldnames(info2);

% 查找第一个 DICOM 文件中存在但第二个文件中不存在的字段
uniqueFields1 = setdiff(fields1, fields2);
disp('第一个 DICOM 文件独有的字段：');
disp(uniqueFields1);

% 查找第二个 DICOM 文件中存在但第一个文件中不存在的字段
uniqueFields2 = setdiff(fields2, fields1);
disp('第二个 DICOM 文件独有的字段：');
disp(uniqueFields2);

% 比较相同字段的值
commonFields = intersect(fields1, fields2);
for i = 1:length(commonFields)
    field = commonFields{i};
    value1 = info1.(field);
    value2 = info2.(field);
    
    if ~isequal(value1, value2)
        disp(['不同的值在字段 ', field]);
        value1 = info1.(field)
        value2 = info2.(field)
%         disp(['文件1值: ', num2str(value1)]);
%         disp(['文件2值: ', num2str(value2)]);
    end
end
