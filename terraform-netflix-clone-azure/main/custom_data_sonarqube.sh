#!/bin/bash
/usr/sbin/useradd -s /bin/bash -m ritesh;
mkdir /home/ritesh/.ssh;
chmod -R 700 /home/ritesh;
echo "ssh-rsa XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ritesh@DESKTOP-0XXXXXX" >> /home/ritesh/.ssh/authorized_keys;
chmod 600 /home/ritesh/.ssh/authorized_keys;
chown ritesh:ritesh /home/ritesh/.ssh -R;
echo "ritesh  ALL=(ALL)  NOPASSWD:ALL" > /etc/sudoers.d/ritesh;
chmod 440 /etc/sudoers.d/ritesh;
####################################################################
mkdir /mederma;
mkfs.xfs /dev/sdc;
echo "/dev/sdc  /mederma  xfs  defaults 0 0" >> /etc/fstab;
mount -a;
############################################################### Installation of SonarQube ##############################################################
yum install -y zip unzip vim wget
useradd -s /bin/bash -m sonar;
echo "Password@#795" | passwd sonar --stdin;
echo "sonar  ALL=(ALL)  NOPASSWD:ALL" >> /etc/sudoers
ulimit -n 65536
echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
sysctl -p
yum install -y java-17* git
cd /opt/ && wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.5.90363.zip
unzip sonarqube-9.9.5.90363.zip
mv /opt/sonarqube-9.9.5.90363 /opt/sonarqube
chown -R sonar:sonar /opt/sonarqube

#################################### Installing Node Exporter #####################################

useradd --system --no-create-home --shell /bin/false node_exporter
cd /opt/ && wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter*

cat > /etc/systemd/system/node_exporter.service <<END_FOR_SCRIPT
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
END_FOR_SCRIPT

systemctl enable node_exporter
systemctl start node_exporter
