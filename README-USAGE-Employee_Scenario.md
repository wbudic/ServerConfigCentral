# Usage Example - Employee Work Scenario

## Introduction

In local small company current employees details are stored in a simple spreadsheet.
These include, name, phone, address, status, etc.
The existing database server is postgres and currently each employee on their internal website has to sign in/off to work.
So their working hours can be calculated for their accounting system.

The new project and  goal is to modernize and automate data operation around the employee's.

## Goals

1. Link card opened door, to sign in/out each employee.
2. Link computer login in/out for each employee.
3. Link home log in/out of the office network.
4. Provide status,  work phone number of each employee for other and further applications.

## Solution

* Solution is to use a central store/access for this data on the network.
* Web based front end would allow for amending securely this data.
* Server side backend would provide current state, configuration and log for the new system.
  * This backend solution is surprise, surprise. The ServerConfigCentral.

---
See also:  [Configuration Network File Format Specifications](https://github.com/wbudic/PerlCNF/CNF_Specs.md)

---
   This document v.1.0 is from project ->  (https://github.com/wbudic/ServerConfigCentral)
   An open source application under <https://choosealicense.com/licenses/isc/>
   Exception, this specification file is not to be modified from an third party.
