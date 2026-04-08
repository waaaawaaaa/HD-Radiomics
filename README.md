# 🧠 HD-Radiomics


> 📄 *"Multimodal MRI integrating anti-motion multi-parametric mappings for investigating subcortical nuclei microstructural alterations in Huntington’s disease."* Journal of Huntington's Disease, 2026.  
> 🔗 **链接**: `https://doi.org/10.1177/18796397251411608` 

---

## 📖 项目简介
本项目开源了针对**亨廷顿病（HD）早期检测与临床分期**的多模态影像组学分析框架。研究融合定量与常规结构影像，通过提取 8 个深部核团的一阶直方图特征与体积特征，三阶段特征筛选与机器学习分类，实现对 HD 微观结构异质性的高灵敏度刻画。
主要是影像组学方面的代码（图像采集与重建、ROI分割、特征提取、特征筛选与降维、以及模型构建与验证）

---
## 运行逻辑
step.m文件里面有代码的主要功能以及运行顺序

## 🔬 方法学细节

### 📐 1. 预处理流程
- **定量 重建**：采用U-Net网络仿真数据训练，实采数据测试。
- **结构像处理**：`N4 偏场校正` → `仿射配准至 MNI152` → `逆变换生成个体空间脑掩膜` → `99th 分位强度归一化`。
- **空间配准**：将 T1W 配准至 T2W 空间生成 `T1W/T2W 比值图`；HybraPD 图谱（T1 + R2）联合配准至个体 T1W–T2W 空间，确保深部核团 ROI 精确映射。
- **掩膜净化**：强度阈值剔除脑脊液（CSF）污染 → 逐层 `1 像素形态学腐蚀` → 若腐蚀后 ROI `< 4 体素` 则回退至低阈值 → 最终经人工视觉校验与手动修正。

### 📊 2. 特征提取
- **目标 ROI**：共 8 个深部核团（尾状核 `Cd`、壳核 `Put`、外苍白球 `GPe`、内苍白球 `GPi`、丘脑 `TH`、红核 `RN`、黑质 `SN`、齿状核 `DN`）。
- **特征维度**：每模态提取 12 项一阶直方图统计量（`Mean`, `Variance`, `RMS`, `Kurtosis`, `Skewness`, `P10`, `P25`, `P50`, `P75`, `P90`, `Max`, `Min`） + ROI 体积（体素数 × 体素分辨率³）。
- **统计检验**：`Shapiro-Wilk` 正态性检验 → `Levene` 方差齐性检验 → 满足条件采用 `ANOVA + Tukey HSD` 事后检验；否则采用 `Kruskal-Wallis + Dunn` 事后检验（显著性阈值 $P < 0.05$，经多重比较校正）。

### 🤖 3. 机器学习流水线
| 步骤 | 方法 | 说明 |
|:---|:---|:---|
| **缺失值处理** | 线性插补 | 处理因缺失 T1W 或 DN 数据导致的空缺 |
| **数据标准化** | Z-score 归一化 | 消除量纲差异，降低尺度方差 |
| **特征筛选 ①** | Pearson 相关性过滤 | 剔除 $\|r\| > 0.8$ 的高冗余特征 |
| **特征筛选 ②** | ANOVA 排序 | 保留组间差异最显著的 Top 80 特征 |
| **特征筛选 ③** | LASSO + RF-RFE | 结合 L1 正则化与随机森林递归特征消除，最终保留 8 个核心特征（≈样本量 1/6，防过拟合） |
| **分类器训练** | LR, RF, SVM, XGBoost, KNN | 采用分层 5 折交叉验证（Stratified 5-Fold CV）确保类别平衡 |
| **评估指标** | Macro-averaged | `F1-macro`, `Sensitivity-macro`, `Specificity-macro`, `Accuracy`, `ROC-AUC` |
