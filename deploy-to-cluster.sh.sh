# PreReqs: kubectl installed with a valid KUBECONFIG for the target cluster.

# In operator.yaml, replace the REPLACE_IMAGE with <image-repo/image-name:tag> used while building the image
sed "s|REPLACE_IMAGE|quay.io/mvpcicdpipeline/mvp-helloworld-operator:1.0.0|g" deploy/operator.yaml > operator.yaml
sed "s/QUAY_SECRET/$QUAY_SECRET/g" deploy/pullsecret.yaml > pullsecret.yaml

# Create the mvp-demo namespace
kubectl create ns mvp-demo

# Create the pull secret
kubectl create -f pullsecret.yaml

# Deploy CRD: 
kubectl create -f deploy/crds/example_v1alpha1_busybox_crd.yaml

# Deploy service account
kubectl -n mvp-demo create -f deploy/service_account.yaml
kubectl -n mvp-demo create -f deploy/role.yaml
kubectl -n mvp-demo create -f deploy/role_binding.yaml
kubectl -n mvp-demo create -f operator.yaml

# Verify that operator deployment is in running state: 
kubectl -n mvp-demo get deployment | grep busybox-operator

# Deploy busybox CR
kubectl -n mvp-demo apply -f deploy/crds/example_v1alpha1_busybox_cr.yaml

rm -f operator.yaml pullsecret.yaml
