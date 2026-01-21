<img src="img/Logo.png" align="right" width="250">

# AutoQ4MS – Automated Quality Control for Mass Spectrometry

## About AutoQ4MS

**AutoQ4MS** (Automated Quality Control for Mass Spectrometry) is a [MATLAB](https://de.mathworks.com/products/matlab.html?s_tid=hp_hero_matlab)-based tool designed for automated monitoring of internal standards in chromatography–mass spectrometry (LC–MS/MS) systems.

AutoQ4MS automatically detects completed measurement files, converts them using **msconvert**([ProteoWizard](https://proteowizard.sourceforge.io/)), identifies internal standard peaks, and evaluates them for anomalies in:
- retention time  
- mass accuracy  
- signal intensity

If deviations exceed defined thresholds, the user is automatically notified.

The framework is designed to be highly flexible and scalable, allowing:
- simultaneous monitoring of multiple instruments  
- parallel supervision of multiple analytical methods  

All evaluation results are systematically stored in a [**PostgreSQL database**](https://www.postgresql.org), enabling long-term tracking and trend analysis.

In addition to internal standard monitoring, AutoQ4MS supports tracking of additional compounds, making it suitable for **multi-target analytical workflows**.

For detailed theoretical background and validation, please refer to the associated publication.

---

## Repository Contents

This repository contains **AutoQ4MS**, developed by:

- Linus Strähle  
- Michael Mohr  

---

## Installation

### Requirements

- [**MATLAB R2024a**](https://de.mathworks.com/products/matlab.html?s_tid=hp_hero_matlab)
- **msconvert**  ([ProteoWizard](https://proteowizard.sourceforge.io/))
- [**PostgreSQL database**](https://www.postgresql.org)
- **Windows 11**

A valid MATLAB license is required.

---

### Automated Installation (Recommended)

1. Ensure [MATLAB](https://de.mathworks.com/products/matlab.html?s_tid=hp_hero_matlab) is installed and licensed
2. Download the .zip file from GitHub, extract it, and rename it "AutoQ4MS"  
3. Run the following file:

```cmd
installation.cmd
````

4. Follow the on-screen instructions

The automated installation attempts to:

* install PostgreSQL locally
* install msconvert
* configure all required paths and dependencies

---

### Manual Installation (Alternative)

1. Ensure [MATLAB](https://de.mathworks.com/products/matlab.html?s_tid=hp_hero_matlab) is installed and licensed
2. Install the following manually:
   * [**PostgreSQL database**](https://www.postgresql.org)
   * **msconvert**([ProteoWizard](https://proteowizard.sourceforge.io/))
4. Download the .zip file from GitHub, extract it, and rename it "AutoQ4MS" 
5. Start MATLAB
6. Run:

```matlab
installation
```

---

### Parameter Configuration

During installation, you will be prompted to define global program parameters.

These parameters:

* are stored as default values
* are automatically applied when creating new methods

It is strongly recommended to configure these parameters carefully, as they directly influence subsequent workflows.

After installation, a **desktop shortcut** is created.
AutoQ4MS can be launched directly using this shortcut.

---

## Using the Application

### Method Management (Left Panel)

The left panel displays all available analytical methods.
After selecting a method, the following actions are available:

* **Refresh**
  Updates the method list

* **Create Method**
  Opens a dialog to create a new method
  Correct parameter configuration is essential

* **Edit Method**
  Allows modification of an existing method

* **Create MS Library**
  Generates a library from files defined as internal standards

* **Run Method**
  Executes the selected method

* **Delete Method**
  Deletes the method
  The user is prompted whether the associated database tables should also be deleted
  Deleting the database is strongly recommended to avoid inconsistencies

* **Delete Lock**
  Each run creates a lock file to prevent simultaneous execution
  If an error occurs, the lock file may not be removed automatically
  This option removes the lock file manually

* **SQL**
  If an SQL error occurs while writing data to the database, the SQL file is stored
  This button opens the corresponding directory

* **Log File**
  If a method terminates with an error, a log file is created
  This button opens the directory containing the log files

By activating the checkbox, automatic periodic execution of a method can be enabled, allowing continuous quality monitoring.

---

### Results and Trend Analysis (Second Tab)

The second tab provides visualization of internal standard trends.

Users can select:

* method
* polarity
* time range

to analyze temporal behavior of internal standards.

---

## Parameter Table


### General

| Parameter | Description |
|---------|-------------|
| `MSdataending` | File extension of converted MS data files (e.g. ".mzXML") |
| `RawMS_Format` | File extension of raw MS vendor files (e.g. ".wiff") |
| `SampleOrder` | Order of sample processing: 0 = modification date, 1 = name (A–Z) |
| `sampling_timestamp` | Definition of the sampling timestamp: options see below|
| `timestamp_of_measurement` | Source of the measurement timestamp: options see below|

options for timestamp: 0 = NaT, 1 = current system time, 2 = extract date from MS file (currently .wiff only), 3 = last modification time of MS data file minus measurement duration, 4 = last modification time of raw MS file (e.g. .wiff / .wiff2) minus measurement duration 

---

### Paths

| Parameter | Description |
|---------|-------------|
| `program` | AutoQ4MS base installation directory (set automatically) |
| `desktop` | Path to the system desktop directory |
| `MATLABexe` | Path to the MATLAB executable (matlab.exe) |
| `proteoWizard` | Path to the msconvert executable (msconvert.exe) |
| `psqlExe` | Path to the PostgreSQL command-line executable (psql.exe) |
| `MSDataSource` | Directory containing raw MS data generated by the mass spectrometer |
| `savedMSData` | Archive directory for processed MS data |
| `ISExcel` | Excel file containing internal standard definitions (use the provided template) |
| `CompExcel` | Excel file containing compound definitions (use the provided template) |
| `MS2_ReferencePath` | Directory containing raw MS data files used as MS2 reference standards |

---

### Flags

| Parameter | Description |
|---------|-------------|
| `deletemzXML` | Delete converted mzXML files after successful processing |

---

### Mail

| Parameter | Description |
|---------|-------------|
| `On` | Enable or disable e-mail notifications |
| `Receiver` | List of e-mail recipients |
| `Sender` | Sender e-mail address, use autoq4ms@gmail.com to use our generic email bot |
| `SmtpServer` | URL of SMTP server to send emails. Not required for autoq4ms@gmail.com |
| `Passowrd` | App Password for Google bot account. Insert anything to use autoq4ms@gmail.com. To use a different account, use the corresponding app password |

---

### Database

| Parameter | Description |
|---------|-------------|
| `host` | Database host (typically localhost) |
| `port` | Database port (default: 5432) |
| `dbname` | PostgreSQL database name |
| `username` | Database user |
| `password` | Database password (stored encrypted) |
| `schema` | Database schema used by AutoQ4MS (do not modify) |

---

### MS1 Processing

| Parameter | Description |
|---------|-------------|
| `min_S_N_maximum` | Minimum signal-to-noise ratio at peak maximum |
| `min_Level_in_S_N` | Minimum S/N level used for peak detection |
| `min_points_over_Level` | Minimum number of data points above `min_Level_in_S_N` |
| `XICtolerance_ppm` | Mass tolerance for extracted ion chromatograms (ppm) |
| `NoiseDistancetoPeakMax_sec` | Time window for noise estimation around the peak maximum (seconds) |
| `noisewindowInSec` | Noise window size used for baseline estimation (seconds) |
| `Noise_default` | Default noise value used if noise estimation fails |
| `MSDataRange` | Time range of MS data used for processing (minutes) |

---

### MS2 Processing

| Parameter | Description |
|---------|-------------|
| `libname` | Name of the MS2 spectral library |
| `minIntensity` | Minimum absolute intensity for MS2 noise removal |
| `minIntensityRelative` | Minimum relative intensity used during library generation |
| `mzTolerance_ppm` | Mass tolerance for MS2 spectral matching (ppm) |
| `binWidth` | Bin width used for MS2 spectral binning |
| `binOffset` | Bin offset used for MS2 spectral binning |
| `threshold` | Similarity threshold for MS2 spectral comparison |
| `removePrecursor` | Remove precursor ion during MS2 processing |
| `From` | Source of MS2 data (e.g. directly from MS data files) |

---

### Chromatography

| Parameter | Description |
|---------|-------------|
| `RTToleranceInSec` | Retention time search window size (seconds) |
| `MeasurementTime_min` | Total chromatographic run time (minutes) |
| `TypeforRTCorr` | Sample type used for retention time correction (e.g. "Blank") |
| `maxdaydistanceforRTcorr` | Maximum time difference allowed for RT correction (days) |
| `RTcorrON` | Enable or disable retention time correction |

---

### Pre-Treatment

| Parameter | Description |
|---------|-------------|
| `Savitzky_on` | Enable Savitzky–Golay smoothing |
| `Savitzky_windowsize` | Window size of the Savitzky–Golay filter |
| `Savitzky_loops` | Number of Savitzky–Golay smoothing iterations |
| `Gaussian_on` | Enable Gaussian smoothing |
| `Gaussian_sigma` | Sigma value of the Gaussian kernel |
| `Gaussian_kernelSize` | Kernel size of the Gaussian filter |

---

### Device Control

| Parameter | Description |
|---------|-------------|
| `interval_days` | Evaluation interval for device control (days) |
| `RT_upperLimit` | Upper retention time deviation limit (seconds) |
| `RT_lowerLimit` | Lower retention time deviation limit (seconds) |
| `intensity_upperLimit` | Upper allowed intensity deviation factor |
| `intensity_lowerLimit` | Lower allowed intensity deviation factor |
| `massaccuracy` | Maximum allowed mass accuracy deviation (ppm) |
| `minimumISneg` | Minimum number of internal standards required within limits (negative mode) |
| `minimumISpos` | Minimum number of internal standards required within limits (positive mode) |

---

### Task Manager

| Parameter | Description |
|---------|-------------|
| `On` | Enable automated task execution |
| `Interval` | Execution interval (minutes) |
| `GuiOn` | Enable Task Manager graphical user interface |

---

## References

For theoretical background and validation, please refer to the associated publication:

> Strähle L., Mohr M.,
> **AutoQ4MS: Automated Quality Control for Mass Spectrometry Using Internal Standards**,
> Journal / Conference, Year.


---

## Third-Party Code

AutoQ4MS includes or adapts third-party software components as listed below.

### zmat (Qianqian Fang) — used file: `zmat.m, zipmat.mexw64, zipmat.mexmaci64, zipmat.mexa64`
- Project: ZMat (portable data compression/decompression toolbox for MATLAB/GNU Octave)
- Author: Qianqian Fang
- Source: https://github.com/fangq/zmat/tree/master
- License: GNU General Public License v3 (GPL-3.0)
- Usage in AutoQ4MS: Used for compression/decompression functionality (e.g., zlib-compressed data handling).
  Precompiled MEX binaries are included; corresponding source code is available in the original ZMat repository:
  https://github.com/fangq/zmat


### AriumMS (Adrian Haun) — used file: `readmzXML.m`
- Project: AriumMS
- Copyright: (c) 2022 Adrian Haun
- Source: https://github.com/AdrianHaun/AriumMS
- License: BSD 3-Clause License
- Usage in AutoQ4MS: `readmzXML.m` adapted for reading mzXML files and extracting scan/intensity/retention time data.

Third-party license texts are provided in the `THIRD_PARTY_LICENSES/` directory, and all third-party code is used in accordance with its respective license terms.

---

## Contact

For questions or support, please contact the authors via the repository.

---

## License

AutoQ4MS is released under the GNU General Public License v3.0 (GPL-3.0).
See the LICENSE file for details.

```

