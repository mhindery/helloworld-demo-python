TAG=${GITHUB_REF_NAME}
echo "RELEASE FOR TAG: " $TAG
echo "-------------"
cd server_config/helm
sed "s/{IMAGE_TAG}/$TAG/g" helloworld-demo-python/values.tmpl.yaml > helloworld-demo-python/values.yaml
mkdir rendered
mkdir rendered/$TAG
cp -r helloworld-demo-python/. rendered/$TAG/
rm rendered/$TAG/values.tmpl.yaml
rm helloworld-demo-python/values.yaml

ls rendered/$TAG
