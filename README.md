# A tool to decode and compare the contents of MachineConfig(s) in OpenShift4.

This script can take one of three options:
- decode:
    Takes multiple MachineConfig YAML files to decode them.
- compare:
    Takes two MachineConfig YAML files, decode and compare between their contents
- help:
    Gives a brief description about this tool


# Using `decode` operation:

Assuming I have generated a YAMl file using the following command:
~~~
# oc get mc <name> -o yaml > mc-file.yaml
~~~        

Normally, this file is encoded and it is difficult to read the configuration file(s) contents directly from it.

You can use this tool to separate between these configuration files and `decode` it into a readable format:

~~~
# ./mca.sh decode mc-file.yaml
~~~
The `decode` option can work with multiple MachineConfig files at the same time.
It will create a directory with the name `metdata.name`-`metadata.creationTimestamp` that are extraced from the YAML file, for example:
~~~
# ./mca.sh mc-file1.yaml mc-file2.yaml mc-file3.yaml

# ls
-rw-r--r--. 1 user user 117349 Sep 24 14:41 mc-file1.yaml
drwxrwxr-x. 3 user user   4096 Sep 27 20:13 rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z
-rw-r--r--. 1 user user 117349 Sep 24 14:41 mc-file2.yaml
drwxrwxr-x. 3 user user   4096 Sep 27 20:13 rendered-master-3130d4b00faa48cef9b9b50252bcbbbbb-2020-01-09T11:26:25Z
-rw-r--r--. 1 user user 117349 Sep 24 14:41 mc-file3.yaml
drwxrwxr-x. 3 user user   4096 Sep 27 20:13 rendered-master-3130d4b00faa48cef9b9b50252bcccccc-2020-09-15T11:26:25Z
~~~

Under the new diretory you will find the **decoded** configuration files, for example:
~~~
# ls -lh rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z/
...
-rw-rw-r--. 1 user user  272 Sep 27 21:14 sdn.conf
-rw-rw-r--. 1 user user 5.9K Sep 27 21:14 storage.conf
-rw-rw-r--. 1 user user 1.4K Sep 27 21:14 tokenize-signer.sh
~~~

It will also extract the services configurations `.spec.config.systemd.units` under **service-units** subdirectory.
~~~
# ls -lh rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z/service-units/
-rw-rw-r--. 1 user user 1.2K Sep 30 21:03 kubelet.service
-rw-rw-r--. 1 user user  661 Sep 30 21:03 machine-config-daemon-firstboot.service
-rw-rw-r--. 1 user user  596 Sep 30 21:03 machine-config-daemon-firstboot-v42.service
-rw-rw-r--. 1 user user  636 Sep 30 21:03 machine-config-daemon-host.service
~~~

# Using `compare` operation:

Assuming you have generated MachineConfig YAMl files using the following command:
~~~
# oc get mc <name> -o yaml > mc-file1.yaml
# oc get mc <another name> -o yaml > mc-file2.yaml
~~~

You can compare between their contents as follows:
~~~
# ./mca.sh compare mc-file1.yaml mc-file2.yaml
~~~

It will show unique files in each machineConfig and also common files with different contents, for example:
~~~
# ./mca.sh compare mc-file1.yaml mc-file2.yaml
checking differences between mc-file1.yaml and mc-file2.yaml MachineConfig files

.... decoding mc-file1.yaml

.... decoding mc-file2.yaml

Unique files existing only in mc-file1.yaml MachineConfig:

Only in rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z/: etcd.conf
Only in rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z/: etcd-generate-certs.yaml.template
...
Only in rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z/: tokenize-signer.sh

Unique files existing only in mc-file2.yaml MachineConfig:

Only in rendered-master-3130d4b00faa48cef9b9b50252bcbbbbb-2020-01-09T11:26:25Z/: 99-kni.conf
Only in rendered-master-3130d4b00faa48cef9b9b50252bcbbbbb-2020-01-09T11:26:25Z/: config.hcl.tmpl
...
Only in rendered-master-3130d4b00faa48cef9b9b50252bcbbbbb-2020-01-09T11:26:25Z/: sshd_config

Files existing in both MachineConfig files mc-file1.yaml and mc-file2 .yaml but differ in contents:
ca.crt
cleanup-cni.conf
crio.conf
kubelet-ca.crt
kubelet.conf
openshift-config-user-ca-bundle.crt
root-ca.crt
sdn.conf
~~~

# Using `extract` operation:
Gives you the ability to extract specific configuration file(s) from the MachineCOnfig YAML file and decode it.
~~~
# ./mca.sh extract <MachineCOnfig file> <configuration file1 path>...
~~~
For example:
~~~
# ./mca.sh extract mc-file1.yaml /etc/crio/crio.conf /wrong/file /etc/kubernetes/ca.crt

/etc/crio/crio.conf got extracted
WARNING: /wrong/file doesn't exist in May19.yaml MahineConfig
/etc/kubernetes/ca.crt got extracted
Check extracted configuration files under rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z/

# ls rendered-master-3130d4b00faa48cef9b9b50252bcaaaaa-2019-03-07T11:26:25Z/
crio.conf
ca.crt
~~~


# Notes:
- machineConfig files should be in YAML format "for now".
- `compare` operation will first `decode`, even if `decode` operation was already done.
- This tool uses `yq` to filter YAML outputs, it can be installed by running the following command:
~~~
# pip install yq
~~~

# limitations:
~~- Services units data are in clear text, so I am still working on a away to exclude and separate them~~
~~- Some configurations are encoded using `base64` and it will require to be decoded separatly, I am also working on it~~
