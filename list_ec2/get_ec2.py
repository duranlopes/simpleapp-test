import boto3

ec2 = boto3.resource('ec2')

for instance in ec2.instances.all():
    print(
        "\nId: {0}\nPlatform: {1}\nType: {2}\nPublic IPv4: {3}\nAMI: {4}\nState: {5}\n\n".format(
        instance.id, instance.platform, instance.instance_type, instance.public_ip_address, instance.image.id, instance.state
        )
    
    )
