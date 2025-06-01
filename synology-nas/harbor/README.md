# README

- [README](#readme)
  - [Provide the Certificates to Docker](#provide-the-certificates-to-docker)
  - [How to setup Harbor on Synology NAS](#how-to-setup-harbor-on-synology-nas)

## Provide the Certificates to Docker

1. Copy the server certificate and key files into the Docker certificates folder.

    ``` bash
    # You must create the appropriate folders first.
    mkdir -p /etc/docker/certs.d/yourdomain.com:port

    # Copy the server certificate.
    cp yourdomain.com.cert /etc/docker/certs.d/yourdomain.com:port/
    cp yourdomain.com.key /etc/docker/certs.d/yourdomain.com:port/
    ```

2. Restart Docker Engine.

    ``` bash
    systemctl restart docker
    ```

## How to setup Harbor on Synology NAS

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

4. Rename the auto-generated `docker-compose.yml` file and copy the generated TLS certificate file to the certs directory.

    ``` bash
    sudo mv docker-compose.yml docker-compose.yml.default

    sudo cp /volume1/docker/certs/* /volume1/docker/harbor/common/config/shared/trust-certificates/
    ```

5. Install Harbor via [Container Manager](https://kb.synology.com/en-global/DSM/help/ContainerManager/docker_desc).
