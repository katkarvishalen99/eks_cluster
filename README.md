# Steps to configure AWS CLI/KUBECTL

1)	**create user with AdministratorAccess permission and create access key**
   ---------------------------------------------------------------------------------
   access key:
   
   secret: 
   
         export AWS_ACCESS_KEY_ID=”access key”
         export AWS_SECRET_ACCESS_KEY=”secret”

2)	**install aws cli/docker/kubectl/helm**
   
         sudo apt update
         sudo snap install aws-cli --classic
         sudo snap install docker --classic
         sudo snap install kubectl –classic
         sudo snap install helm --classic

3) ** aws configure**

         aws configure
   
ubuntu@ip-172-31-3-93:~/terraform/eks$ aws configure

AWS Access Key ID [None]: 

AWS Secret Access Key [None]: 

Default region name [None]: ap-south-1

Default output format [None]: json

4) **update kubeconfig with cluster name:**
   
         aws eks update-kubeconfig  --region ap-south-1 -name eks-cluster
  
5) **Bash completion and kubectl alias**
   
         sudo apt install bash-completion
         source /etc/bash_completion
         source <(kubectl completion bash)
         echo "source <(kubectl completion bash)" >> ~/.bashrc
         source ~/.bashrc
         alias k=kubectl
         complete -F __start_kubectl k
