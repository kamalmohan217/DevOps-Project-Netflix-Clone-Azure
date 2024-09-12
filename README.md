# DevOps-Project-Netflix-Clone-Azure
![image](https://github.com/user-attachments/assets/3e904fc5-571e-4256-ba06-ac62a9b1cdd6)

For Prometheus do the configuration in the file **/etc/prometheus/prometheus.yml** as shown below.
![image](https://github.com/user-attachments/assets/1dc49c87-8bf7-488f-b971-5620087ae0d5)


```
The netflix-clone-auth secrets for kubernetes can be created using the command below

kubectl create secret netflix-clone-auth --docker-server=https://netflixcontainer24registry.azurecr.io --docker-username=netflixcontainer24registry --docker-password=XXXXXXXXXXXXXXXXXXXXXXXXXXXOJ7eXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXMtTc -n netflix
```
