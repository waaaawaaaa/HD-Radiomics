import os
from os.path import dirname, join
import shutil
import pydicom
from pydicom.filereader import read_dicomdir
import re

path = ' '
dicom_dir = read_dicomdir(path)
base_dir = dirname(path)

for patient_record in dicom_dir.patient_records:  # got through each patient
    path1 = os.path.join(base_dir, patient_record.PatientName.family_name)#拼接目录
    try: os.mkdir(path1) # 创建目录
    except FileExistsError: pass

    studies = patient_record.children  # got through each study
    for study in studies:
        path2 = os.path.join(path1, study.StudyID)
        try: os.mkdir(path2)  # 创建目录
        except FileExistsError: pass

        all_series = study.children  # go through each serie
        for series in all_series:
            series.SeriesDescription = re.sub(r'\W', "", series.SeriesDescription)#偶尔存在非法符号，正则匹配后去掉
            path3 = os.path.join(path2, series.SeriesDescription)
            try: os.mkdir(path3)  # 创建目录
            except FileExistsError: pass

            image_records = series.children  # go through each image
            image_filenames = [join(base_dir, *image_rec.ReferencedFileID) for image_rec in image_records]
            for image_filename in image_filenames:
                try: shutil.move(image_filename, path3)#移动文件
                except shutil.Error: pass
                except FileNotFoundError: pass
