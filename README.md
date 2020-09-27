# A tool to decode and extract configuration files from the MachineConfig resource definition files.

- Example:

Assuming I have generated a YAMl file using the following command:
~~~
# oc get mc <name> -o yaml > mc-file.yaml
~~~        

Normally, this file is encoded and it is hard to read the configuration file contents directly from it. Also, the YAML file can contain multiple configuration files at the same time.

I can use this tool to separate between these configuration files and `decode` it into a readable format:

~~~
# ./mca.sh decode mc-file.yaml
~~~

A new directory will be created, the name of the directory is the name of the MachineConfig resource `extracted from the YAMl file` and not the name of the YAML file itself.

The name of the directly will also contain the `creationTimestamp` part to make it easier to identify it.
~~~
# ./mca.sh mc-file.yaml

# ls
-rw-r--r--. 1 user user 117349 Sep 24 14:41 mc-file.yaml
drwxrwxr-x. 3 user user   4096 Sep 27 20:13 rendered-master-3130d4b00faa48cef9b9b50252bcdwdw9-2020-07-07T11:26:25Z
~~~

Under the new diretory `rendered-master-3130d4b00faa48cef9b9b50252bcdwdw9-2020-07-07T11:26:25Z` you will find the original **encoded** configuration files.
~~~
# ls -lh rendered-master-3130d4b00faa48cef9b9b50252bcdwdw9-2020-07-07T11:26:25Z
...
drwxrwxr-x. 2 user user 4.0K Sep 27 20:13 decoded
...
-rw-rw-r--. 1 user user  272 Sep 27 21:14 sdn.conf
-rw-rw-r--. 1 user user 5.9K Sep 27 21:14 storage.conf
-rw-rw-r--. 1 user user 1.4K Sep 27 21:14 tokenize-signer.sh
~~~
And another sub-directory called **decoded** will be created for the same files but in a readable, decoded format
~~~
# ls -lh rendered-master-3130d4b00faa48cef9b9b50252bcdwdw9-2020-07-07T11:26:25Z/decoded/
...
-rw-rw-r--. 1 user user  272 Sep 27 21:14 sdn.conf
-rw-rw-r--. 1 user user 5.9K Sep 27 21:14 storage.conf
-rw-rw-r--. 1 user user 1.4K Sep 27 21:14 tokenize-signer.sh
~~~
