
%% DDA import
FilePath = "C:\Users\linus\OneDrive\Messdaten\Donau\25-01-24_Zor04_p_07_171017-02_KW02_Mo_Donau_25-01-06_Inj1.wiff";
fileName = "25-01-24_Zor04_p_07_171017-02_KW02_Mo_Donau_25-01-06_Inj1.wiff";
mzXMLFilePath = string(x2mzxml(FilePath, fileName, Parameters));
[ms1_data, ms2_data] = loadmzxml(mzXMLFilePath);


%% DIA import
FilePath = "C:\Users\linus\OneDrive\Messdaten\DIA\24-05-09_Zor04_p_41_AIO-Mix4_1000ngL_TOF5600-Zor_Sw_Inj3.wiff";
fileName = "24-05-09_Zor04_p_41_AIO-Mix4_1000ngL_TOF5600-Zor_Sw_Inj3.wiff";
mzXMLFilePath = string(x2mzxml(FilePath, fileName, Parameters));
[ms1_datadia, ms2_datadia] = loadmzxml(mzXMLFilePath);

