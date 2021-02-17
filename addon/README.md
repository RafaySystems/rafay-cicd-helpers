## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- Ensure you have downloaded Rafay CLI (RCTL)
- Credentials with permissions to provision clusters, create addons, blueprints in Rafay Platform
---
### Addon creation

Sample declarative specs for creating addon are available [here](../addon/examples)

### Parameters that needs to be specified in the spec file

- kind - It has to be AddonVersion
- metadata.name - Version Name of the addon that will be created in Rafay Platform
- metadata.project - Name of the project in Rafay platform where addon needs to be created
- spec.addon - Name of the addon that will be created in Rafay Platform
- spec.template.type - Type of the manifest that addon is packaged. It has to be either "yaml" or "helm3"
- spec.template.yamlFile - location to the yaml file
- spec.template.chartFile - location to the helm chart if it's a helm3 type addon
- spec.template.valuesFile - location to the values file if it's a helm3 type addon

### Addon creation

```
ADDON_TYPE=`cat addon/examples/cert-manager-spec.yaml |python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq .spec.template.type | tr \" " " | awk '{print $1}' | tr -d "\n"`
ADDON_NAME=`cat addon/examples/cert-manager-spec.yaml |python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq .spec.addon | tr \" " " | awk '{print $1}' | tr -d "\n"`
rctl create addon $ADDON_TYPE $ADDON_NAME --namespace $CERT_MANAGER_NAMESPACE
rctl create addon version -f addon/examples/cert-manager-spec.yaml
```

### Jenkins Pipeline Groovy script

An example jenkins pipeline groovy script can be found [here](../addon/Jenkins)