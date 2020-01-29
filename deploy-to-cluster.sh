# PreReqs: oc installed with a valid KUBECONFIG for the target cluster.

# Inputs:
image=$1
oc=$2
path=$3

# In operator.yaml, replace the REPLACE_IMAGE with <image-repo/image-name:tag> used while building the image
sed "s|REPLACE_IMAGE|$image|g" $path/deploy/operator.yaml > $path/operator.yaml
sed "s/QUAY_SECRET/$QUAY_SECRET/g" $path/deploy/pullsecret.yaml > $path/pullsecret.yaml

# Create the mvp-demo namespace
$oc create ns mvp-demo

# Create the pull secret
$oc create -f $path/pullsecret.yaml

# Deploy CRD: 
$oc create -f $path/deploy/crds/example_v1alpha1_busybox_crd.yaml

# Deploy service account
$oc -n mvp-demo create -f $path/deploy/service_account.yaml
$oc -n mvp-demo create -f $path/deploy/role.yaml
$oc -n mvp-demo create -f $path/deploy/role_binding.yaml
$oc -n mvp-demo create -f $path/operator.yaml

# Verify that operator deployment is in running state: 
$oc -n mvp-demo get deployment | grep busybox-operator

# Deploy busybox CR
$oc -n mvp-demo apply -f $path/deploy/crds/example_v1alpha1_busybox_cr.yaml

rm -f $path/operator.yaml $path/pullsecret.yaml
