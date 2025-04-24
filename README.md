# VLSI Design Integrity & Automation Suite

This repository contains a comprehensive suite of Perl and TCL/Tk-based tools for automating RTL-level design integrity checks in VLSI projects. It provides support for Linting, CDC/RDC analysis, RTL file dependency tracking, design rule compliance, and static timing pre-checks, all integrated with a simple GUI.

## Overview

The toolkit consists of the following components:

1. Linting Checker
2. Clock & Reset Domain Crossing (CDC/RDC) Checker
3. RTL File Integrity & Dependency Checker
4. Design Rule Compliance (DRC) Checker
5. Static Timing Analysis (STA) Pre-Check
6. Power, Performance & Area (PPA) Validator
7. GUI-based Checker Launcher
8. Log files generator

## Components

### 1. Linting Checker (linting.pl)
A Perl script that parses Verilog/SystemVerilog files to identify:
- Syntax errors (missing semicolons, incorrect constructs)
- Unconnected/floating signals
- Naming convention violations (e.g., clk_, rst_)
- Hardcoded values vs. parameters/macros
- Combinational loops & inferred latches


### 2. CDC/RDC Checker (cdc_checker.pl)
Detects unsafe crossings between clock or reset domains by analyzing flop-to-flop transfers and missing synchronizers.


### 3. RTL File Integrity Checker (rtl_integrity.pl)
Checks for:
- Missing include files
- Broken module hierarchies
- Unresolved dependencies
- Unauthorized modifications using SHA-256
- Version tracking with Git integration


### 4. DRC Checker (drc_checker.pl)
Performs compliance checks based on custom rules:
- Minimum signal width
- FSM encoding scheme (one-hot, gray, binary)
- Unexpected latches
- Signal naming conventions


### 5. STA Pre-Check (sta_precheck.pl)
Preliminary static timing analysis tool that checks:
- Unconstrained paths
- Missing SDC constraints
- Clock skew
- Floating resets


### 6. PPA Validator (ppa_checker.pl)
Reports missing clock gating, large combinational paths, and other low-power design deficiencies.


### 7. GUI (TCL-Tk based)
A TCL-Tk based graphical user interface allows you to:
- Load RTL folder
- Select which checks to perform
- Launch scripts and see progress
- View output logs and error reports interactively

Launch GUI:
```bash
wish gui.tcl
```

### 8. Report Generator
All checkers generate log files in the log folders.


## Workflow
1. Launch the GUI:
```bash
wish gui.tcl
```

2. Select the RTL folder and the desired checks.
3. Click "Run Checks" to perform analysis.
4. Review log files in the output folder.

## Dependencies

### Perl Modules
```bash
sudo dnf install perl 
```

### TCL/Tk
Install Tcl/Tk (v8.5 or higher):
Ubuntu:
```bash
sudo apt-get install tk
```


## Installation
1. Clone the repository:
```bash
git clone https://github.com/KartikAggawral/vlsi-design-integrity-checker
cd vlsi-design-integrity-checker
```

2. Install the dependencies mentioned above.
