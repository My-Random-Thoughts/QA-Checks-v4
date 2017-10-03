# Changes Of Note
The following changes have been made from v3 of the QA checks.  These might affect the way you perform your scans.

## Requirements
- The QA checks now requires PowerShell v4 as a minimum.


## Checks
- All checks have been rewritten to take advantage of the v4 changes (faster, more native commands).
    As well as numerous bug fixes and enhancements, there are some speed increases too.
    They have also all been renamed to remove the "C-" prefix.  It is no longer needed.

- The following checks have been removed and are no longer available:
    - _c-hvh-02-no-other-server-roles_
    - _c-net-06-network-agent_

- The following checks have been renames, but continues in all other functionality:
    - _c-net-02-unused-network-interfaces_    -->    _net-02-dhcp-enabled-network-interfaces_

- The following checks are new:
    - _hvh-02-thick-disks_ : Check all virtual machines are using thick provisioned disks.
    - _hvh-07-vhdx-disks_  : Check all virtual machines are using VHDX disks if the host is Windows 2012 or above.
    - _sys-23-environment-variables_ : Allows you to checks a specific list of system environment variables and values to see if they are set correctly.

## Engine
- Remote server scanning is now handled by using WinRM sessions.
    This can be configured to use either HTTP (default) or HTTPS on either the standard ports (5985/5986) or a custom one.
    Further configuration may be added at a later date (request it if required).

- The checks, engine and all output is now fully language independent (currently only "English UK" exists)
    The only part of the QA project that is language specific is the GUI Configuration Tool.  That will be translated at a later date.
    New languages can be created by following the instructions in the "i18n" folder.


## Settings File(s)
- All existing settings files should continue to work as is, but will need passing through the GUI Configuration Tool first, or making the following changes:
    - Add the following two lines to the end of the [settings] section:
   
          SessionPort   = 5985
          SessionUseSSL = False

    - Change all ` = (` to ` = @(`    (add a @ symbol to the front of all lists.
        
    - Checks `SYS-03` asks for Windows Service display names, these need to be changed to use the service name.
        This is usually a shorter version of the language specific display name.  For example:
        
          Display Name  (Service Name)
          ----------------------------
          Print Spooler (spooler)
          Software Protection (sppsvc)
          Background Intelligent Transfer Service (bits)


- Where more than one settings file exists, the compiler script will prompt you with a menu to choose which settings to use.
    You no longer need to specify the name on the command line, but you still can if you like (for automation tools).

## GUI Configuration Tool

- The GUI Configuration Tool has had a bit of a make over.  Most of the pages are the same, but little tweaks and enhancements have been made.
    - The language and settings drop-down boxes now show flags and icons.
    - Within the Additional Options window, you can now specify some WinRM settings (Port and HTTP(s))

