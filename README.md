# GeoDAS-Diagnostic-Suite: Advanced Geophysical Research & Visualization for Subsurface Mining

[![MATLAB](https://img.shields.io/badge/MATLAB-Research--Oriented-orange.svg)](https://www.mathworks.com/products/matlab.html)
[![ICDS Rising Researcher](https://img.shields.io/badge/Research-ICDS%20PSU-blue.svg)](https://www.icds.psu.edu/)

## 🚀 Overview
**GeoDAS-Diagnostic-Suite** is a MATLAB-based research toolkit designed for the high-fidelity characterization of mining-induced seismic events and geohazard precursors. 

While `OpenDAS-Stream` handles extreme-scale data throughput, this suite provides the "Scientific Lens" to diagnose complex wavefield phenomena in subsurface environments.

## ✨ Key Research Capabilities
* **Precision Event Characterization**: Specialized modules to distinguish between high-frequency operational signals (e.g., TNT blasting) and transient geomechanical responses (e.g., CO2 injection).
* **Real-time Spatiotemporal Mapping**: A custom visualization engine that projects dynamic DAS wavefields onto satellite-based mine geometry for intuitive event localization.
* **Automated Phase Picking**: Implements optimized **STA/LTA pipelines** with grid-search parameter tuning to ensure reliable arrival detection across heterogeneous rock masses.
* **Spatial Calibration Diagnostics**: Tools for identifying fiber turning points and validating channel-to-depth geometry through advanced zero-lag correlation analysis.

## 📊 Research Showcase: Mining Event Localization
The following visualization demonstrates the suite's ability to synchronize kilometer-scale fiber data with precise geospatial satellite imagery, providing a direct link between acoustic energy release and physical mine excavation stages.

![Real-time Spatiotemporal Mapping](./spatiotemporal_mapping_demo.jpg)
*Figure: Simultaneous display of DAS wavefield propagation (left) and its corresponding geospatial projection on the mine site (right).*

## 🛠️ Module Breakdown
* `STA_LTA.m`: High-frequency event detection and parameter optimization.
* `Geom.m`: The primary engine for geospatial integration and animated mapping.
* `Find_turning_point2.m`: Precision geometry validation and turning point analysis.
* `Center_trace.m`: Energy distribution and source trace diagnostics.
---
**Author**: Xinxin  
**Affiliation**: Penn State University | ICDS Rising Researcher Program  
