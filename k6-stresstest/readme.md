
### Install in ubuntu:

```bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 379CE192D401AB61
echo "deb https://dl.bintray.com/loadimpact/deb stable main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update
sudo apt-get install k6
```

### Running with official docker image:

```
docker run --rm -i loadimpact/k6 run - <script.js
```

### Running with building ubuntu image (test host)

```
docker run --rm -v $(pwd):/app --network="host" -it k6test:latest bash
```

