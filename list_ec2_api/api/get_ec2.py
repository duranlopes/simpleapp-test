import boto3
import uvicorn
from fastapi import FastAPI
from fastapi.encoders import jsonable_encoder

app = FastAPI()

ec2 = boto3.resource('ec2')

data = []
for instance in ec2.instances.all():
    item = {"id": instance.id,
            "plataform": instance.platform,
            "type": instance.instance_type,
            "public_ip": instance.public_ip_address,
            "ami": instance.image.id,
            "state": instance.state['Name']}
    data.append(item)


@app.get("/ec2", tags=['Ec2 instances'])
def get_instances():
    return jsonable_encoder(data)


if __name__ == "__main__":
    uvicorn.run("get_ec2:app", host="0.0.0.0", port=5000,
               log_level="info", debug=True)