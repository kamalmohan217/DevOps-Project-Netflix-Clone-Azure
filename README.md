# DevOps-Project-Netflix-Clone-Azure
![image](https://github.com/user-attachments/assets/3e904fc5-571e-4256-ba06-ac62a9b1cdd6)

For Prometheus do the configuration in the file **/etc/prometheus/prometheus.yml** as shown below.
![image](https://github.com/user-attachments/assets/1dc49c87-8bf7-488f-b971-5620087ae0d5)

The dashboard of prometheus can be seen as below.
![image](https://github.com/user-attachments/assets/8e60a383-5e2b-478a-90f9-78c92e22d6bf)
![image](https://github.com/user-attachments/assets/c29974c3-0b32-4a00-a579-0325eef8c4e3)

For grafana the DataSource is Prometheus and to configure the same see the below screenshots.
![image](https://github.com/user-attachments/assets/72168b65-c15c-4d11-bb12-e42dfae5a52f)
![image](https://github.com/user-attachments/assets/5bfc7cff-33f5-4145-a3ac-d63c75a3fd3a)
![image](https://github.com/user-attachments/assets/9c6bc1fd-1201-4ebf-bfe8-18f8e15abbda)

The source code was present in Azure Repo as shown in the screenshot attached below.
![image](https://github.com/user-attachments/assets/21674ba0-090f-4eec-9f71-a3860433ba9c)

After running the Azure DevOps Pipeline the screenshot of SonarQube is as shown below.
![image](https://github.com/user-attachments/assets/5692ffda-eab7-4ca8-a73a-dbc68f7a67dc)
![image](https://github.com/user-attachments/assets/e9348242-6399-4bc1-a9fa-393a00434bfd)

I have created service connection for Azure Container Registry as shown in the screenshot below.
![image](https://github.com/user-attachments/assets/ca18e948-25e5-47b1-a11b-05b28eea7495)

For Build notification the Email ID will be configured as shown in the screenshot below.
![image](https://github.com/user-attachments/assets/b55f203c-f5dc-44d7-a321-b2bad40dcb9a)
![image](https://github.com/user-attachments/assets/42325b85-2843-4aa5-9b25-0c84f1985146)
![image](https://github.com/user-attachments/assets/5bb6732e-c26d-45d8-ac08-778d61fbb652)

After completion of Azure DevOps Pipeline Job the email will be triggered to the Email Id as shown in the screenshot below.
![image](https://github.com/user-attachments/assets/416c6ab8-fff5-40a3-8e76-d6ede3d5352c)

The TMDB API Key is taken as shown in the screenshot attached below.
![image](https://github.com/user-attachments/assets/ba6b484b-2a33-4eca-892a-2342e5971483)

The entry for DNS Zone is shown in the screenshot attached below.
![image](https://github.com/user-attachments/assets/3cad3027-6849-4377-9812-e815c69697b6)

Finally you can access the application as shown below.
![image](https://github.com/user-attachments/assets/e4ae89ac-9a71-40a7-b6b1-36724ee34b3f)


```
The netflix-clone-auth secrets for kubernetes can be created using the command below

kubectl create secret netflix-clone-auth --docker-server=https://netflixcontainer24registry.azurecr.io --docker-username=netflixcontainer24registry --docker-password=XXXXXXXXXXXXXXXXXXXXXXXXXXXOJ7eXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXMtTc -n netflix
```

<br><br/>
<br><br/>
<br><br/>
<br><br/>
<br><br/>
<br><br/>
```
For your reference the source code and helm chart is as given below.

source code:- https://github.com/kamalmohan217/DevSecOps-Project.git

Helm Chart:-  https://github.com/kamalmohan217/helm-repo-for-netflix-clone.git
```
<br><br/>
<br><br/>
<br><br/>
<br><br/>
<br><br/>
<br><br/>
```
Reference:-  https://muditmathur121.medium.com/devsecops-netflix-clone-ci-cd-with-monitoring-email-990fbd115102
```
