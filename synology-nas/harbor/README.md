# README

How to setup Harbor on Synology NAS

1. SSH into the Synology NAS and run the following commands to download the specific Harbor installer and setup the required directories.

    ``` bash
    cd /volume1/docker/
    curl -fsSL https://github.com/goharbor/harbor/releases/download/v2.12.2/harbor-online-installer-v2.12.2.tgz | tar zxv -C .
    mkdir -p harbor/{data,common/config,log/harbor}
    sudo chown -R 10000:10000 harbor
    sudo chmod -R 755 harbor
    ```

2. Copy the updated `harbor.yml` configuration file to the `harbor` directory.

3. Run the Harbor prepare script which will verify that everything was setup correctly prior to performing Harbor installation.

    ``` bash
    cd /volume1/docker/harbor
    sudo ./prepare --with-trivy
    ```
