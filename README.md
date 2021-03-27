
==========Register_Agents Script==========

Download the .ps1 and the .log file and put in a directory.  Change to that directory in powershell and run ./register_agents.ps1

This will run the script and ask for the rubrik cluster and credentials and then proceed through all VMs to run an API call to register the rubrik agent.  This will not succeed for a VM if the agent isn't installed and it will just skip to the next VM.

==========================================
