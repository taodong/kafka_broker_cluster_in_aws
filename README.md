# Multiple Kafka broker cluster in an AWS VPC
An example project to build multiple Kafka broker cluster within an AWS VPC. With default setting, this project will create a Kafka broker cluster contains three Kafka servers within a given AWS VPC. All servers will be controlled by auto scaling group and assigned private DNS for clients to connect to.

## Prerequisites
* Linux or Mac system only
* Java 8 or later required
* Maven required
* Python 2.7 and up required
* Pip 2.7 and up required
* AWS environment (awscli) installed and configured
* Ansible local installation is required
* Terraform local installation is required

## Configuration
Before build, you need to update files src/kafka/aws.properties and src/kafka/terraform.tfvars to provide information of target VPC.

To update aws.properties, please replace all "TO_FILL" fields to actual values according to your VPC. You can find detailed information in comment above each property.

To update terraform.tfvars, you need create a S3 bucket and put the bucket and region information in terraform.tfvars
```xml
bucket = "${s3-bucket-put-terraform-state}"
region = "${region}"
``` 
You also need to create a DynamoDB table terraform_locks in your region to store terraform state locks. You can change the table name by updating dynamodb_table field in terraform.tfvars
```xml
dynamodb_table = "terraform_locks"
```

## Build
### Build AMI
Grant executable permission to all .sh files and ran kafka-ami.sh to prepare Anisible scripts
```xml
chmod +x *.sh
./kafka-ami.sh
```
Then navigate to target folder and run build.sh
```xml
cd target
./build.sh
```
When the script finished, by default it will create an AMI named sample-kafka-2018 in your VPC.
### Creating Kafka servers
After the AMI is ready, you can create Kafka broker servers by running
```xml
./kafka-aws-create.sh
cd target
./build.sh
```

## Test
By default, scripts above will create 3 kafka brokers servers with private DNS kafka1, kafka2 and kafka3. Any server has security group ${server.app.sg.id} will allow to connect them through Zookeeper with port 2181 and Kafka with port 9092. The server also can be sshed by any server with security group id ${server.jump.sg.id}. Both server.app.sg.id and server.jump.sg.id should be defined in aws.properties.

## Customization
### Update DNS name
Kafka servers' private DNS names are decided by type properties and kafka.server.number in aws.properties. The following definition will create DNS abc1, abc2 and abc3.
```xml
type=abc
kafka.server.number=3
```
### Update Zookeeper configuration
Zookeeper configuration is defined in zookeeper.properties under src/shared/roles/kafka/templates/zookeeper.properties. If you want to update Zookeeper default port, you also need to update src/ami/kafka-broker-server/ansible/roles/cloud-init/files/setup-evn.sh line 53. Change port number from 2181 to a new port number.
```xml
ZOOKEEPER_LIST+="${DNS_PREFIX}${i}:2181"
```
### Update Kafka configuration
Kafka configuration is defined in server.properties under src/shared/roles/kafka/templates/server.properties. 

### Building tool changes
The infrastructure is build by Packer and Terragrunt. If you want to update building tools, please refer building configuration details at https://github.com/taodong/cloud-maven-plugin

## Possible issues
The current Ansible java role is using the latest Java 8 with minor version 171. When there is new Java 8 version released, Oracle will retire the existing download link. In that case, you have to update java version information shared/roles/java/defaults/main.yml otherwise the Ansible java task will fail.

## Future enhancement
For better fault tolerate, Kafka need to be mounted on an EBS volume.

## License
MIT 




