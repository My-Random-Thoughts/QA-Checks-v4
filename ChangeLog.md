### 2018-03-23
- `SEC-18` : Removed the patch checking as there were multiple possible values.  Registry checking still exists.

### 2018-03-16
- `SEC-20` : Added check to makes sure you are not using LMHashes.

### 2018-03-12
- `SEC-19` : Added new check for finding any unquoted service paths

### 2018-02-28
- GUI changes to the input form.  It's now sizable for the list and checkbox views.

### 2018-02-21
- It was easier than I thought to convert from COM- to TOL-.  Your settings files will be automatically converted if you use the QASCT.  If you use the compiler manually, it will read in both the new and old versions.

### 2018-02-20
- Renamed Compliance section to Tooling.  This is only a label change, all your settings and configuration will remain intact.  I'll rename the checks from COM- to TOL- at a later date.

### 2018-01-25
- Minor changes to the QASCT to enable links in check descriptions

### 2018-01-18
- `SEC-18` : Added new check for the Spectre issue

### 2017-11-07
- Added 7 news checks for SQL server scanning.  The PowerShell module SQLPS must be installed on the server you are scanning for these to work

### 2017-11-03
- `COM-04` : Bug fix for getting server names

### 2017-11-01
- `COM-12` : Added ignore for domain controllers (also updated `en-GB.ini`)
- `SEC-04` : Bug fix for wrong registry key
- `SYS-12` : Added check for missing/empty registry key

### 2017-10-28
- Initial Version 4 Upload
