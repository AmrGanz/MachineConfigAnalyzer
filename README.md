A tool to decode MachineConfig YAML files, it will also extract configuration files from the MachineConfig into a separate directory.

USAGE: ./decode-mc.sh <operation> <MachineConfig file1> <MachineConfig file2> ....

OPERATIONS:
        decode: 
                Can take multiple MachineConfig files to decode them into a readable files and extract the configurations from each one.
                Each provides MachineConfig file will result in a newly created direcory for it. This directory will have the actual name.
                of the provided MachineConfig file.
        
        compare: 
                Will try to find different files that have been extracted from each MachineConfig "this option will rely on the native 'diff' command".
                It will always compare between the first two MachineConfig files, so a third or fourth or ... arguments will be neglected.
