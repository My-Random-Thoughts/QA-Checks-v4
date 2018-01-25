# QA Checks v4
**PowerShell scripts to ensure consistent and reliable build quality and configuration for your servers.**

## Overview
The QA checks came about as a need to verify the build of new servers for various customers and their different environments.  All new server builds are usually done with a custom gold image template; however this image still lacks many of the additional tools and configuration settings needed before it can be accepted into support.

Most of this extra tooling and configuration should be automated, however checks are still needed to make sure each customer or environment has their specific settings in place.

#### Supported Operating Systems
   - `Windows Server 2008 R1 and R2` (*PowerShell 4 is not installed by default*)
   - `Windows Server 2012 R1 and R2`
   - `Windows Server 2016`

#### Unsupported Operating Systems
   - `Windows 2003 Server`
   - `Any non-server operating system` (*While the checks will work, they are not supported*)
   - `Any non-Windows operating system`

---
## The Checks
There are over 100 checks split over 10 separate sections.  These are executed whenever the QA script is run against one or more servers and can take anywhere between 30 seconds and a couple of minutes to complete.  If you are checking multiple servers then this time is per server.  

For a full list of checks and their sections, check the GitHub Wiki page:
   > https://github.com/My-Random-Thoughts/QA-Checks-v4/wiki/Sections

---
## Quick Start Guide
There are three stages required to get you up and running.  The first one is the quickest and will generate a HTML report of its findings.  This report will have quite a number of failures in most environments.  Don’t worry; stage two will help you fix these failures - either as a scan configuration change or to highlight areas in the environment that may need some work.
   > https://github.com/My-Random-Thoughts/QA-Checks-v4/wiki/Quick-Start-Guide

---
## Language Translations
All the checks, the scanning engine and the settings configuration tool can be displayed in your specific language.  If you want to help out translating this tool, please see the following guide:
   > https://github.com/My-Random-Thoughts/QA-Checks-v4/wiki/Creating-A-New-Language-File


---
## Changes From Version 3
There are quite a number of changes and improvements from version 3 (which are still available).  The following document lists them:
   > https://github.com/My-Random-Thoughts/QA-Checks-v4/blob/master/Changes_From_v3.md
