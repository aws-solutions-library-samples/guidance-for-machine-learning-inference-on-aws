#!/bin/bash

echo ""
echo "Deleting node groups, IAM service account and EKS cluster eksctl-eks-inference-workshop ..."
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-nodegroup-inf --region us-west-2
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-nodegroup-inf --region us-west-2
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-nodegroup-cpu --region us-west-2
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-nodegroup-cpu --region us-west-2
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-nodegroup-graviton --region us-west-2
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-nodegroup-graviton --region us-west-2
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-addon-iamserviceaccount-kube-system-aws-node --region us-west-2
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-addon-iamserviceaccount-kube-system-aws-node --region us-west-2
aws cloudformation delete-stack --stack-name eksctl-eks-inference-workshop-cluster --region us-west-2
aws cloudformation wait stack-delete-complete --stack-name eksctl-eks-inference-workshop-cluster --region us-west-2

echo ""
echo "Finished deletion of eksctl-eks-inference-workshop CF stack in us-west-2 region. Now deleting  EC2 Management Instance stack in your default region ..."
aws cloudformation delete-stack --stack-name ManagementInstance
aws cloudformation wait stack-delete-complete --stack-name ManagementInstance

echo ""
echo "Cleanup of all ML Inference Guidance AWS Resources complete" 
echo ""

