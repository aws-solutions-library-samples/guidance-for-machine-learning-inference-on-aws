#!/bin/bash

echo ""
echo "Deleting node groups, IAM service account and EKS cluster eksctl-eks-inference-workshop ..."
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-nodegroup-inf
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-nodegroup-inf
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-nodegroup-cpu
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-nodegroup-cpu
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-nodegroup-graviton
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-nodegroup-graviton
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-addon-iamserviceaccount-kube-system-aws-node
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-addon-iamserviceaccount-kube-system-aws-node
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-cluster
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-cluster

echo ""
echo "Finished deletion of eksctl-eks-inference-workshop CF stack!Now will delete  EC2 Management Instance stack ..."
aws cloudformation delete-stack --stack-name ManagementInstance
aws cloudformation wait stack-delete-complete --stack-name ManagementInstance

echo ""
echo "Cleanup of all ML Inference Guidance AWS Resources complete" 
echo ""

