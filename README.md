# A tool to decode and extract configuration files from the MachineConfig resource definition files.

- Example:

Assuming I have generated a YAMl file using the following command:
~~~
# oc get mc <name> -o yaml > mc-file.yaml
~~~        

Normally, this file is encoded and it is hard to read the configurations files contents directly from it. Also, the YAM file can contain multiple configurations files.

I can use this tool to separate between these configuration files and `decode` it into a readable format.

~~~
# ./mca.sh mc-file.yaml
~~~

A new directory will be created, the name of the directory is the name of the MachineConfig resource `extracted from the YAMl file` and not the name of the YAML file itself.

The name of the directly will also contain the `Creation Timestamp` part to make it easier to identify it.
~~~
# ./mca.sh mc-file.yaml
# ls
-rw-r--r--. 1 user user 117349 Sep 24 14:41 mc-file.yaml
drwxrwxr-x. 3 user user   4096 Sep 27 20:13 rendered-master-3130d4b00faa48cef9b9b50252bcdwdw9-2020-07-07T11:26:25Z
~~~
