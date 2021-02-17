## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- Ensure you have downloaded Rafay CLI (RCTL)
- Credentials with permissions to provision clusters, create addons, blueprints in Rafay Platform
---
### Blueprint creation

Sample declarative specs for creating blueprint are available [here](../blueprint/examples)

### Parameters that needs to be specified in the spec file

- kind - It has to be BlueprintVersion
- metadata.name - Version Name of the Blueprint that will be created in Rafay Platform
- metadata.project - Name of the project in Rafay platform where blueprint needs to be created
- spec.blueprint - Name of the Blueprint that will be created in Rafay Platform
- spec.addons.name - Name of the addon that you want to include in the blueprint
- spec.addons.version - Name of the addon version that you want to include in the blueprint
- spec.psps - Name of the psp that you want to include in the blueprint
- spec.pspScope - Scope of the PSP (either cluster-scoped or namespace-scoped)
- spec.rafayIngress - Whether to deploy Rafay manged ingress or not (true or false)

### Blueprint creation

```
BLUEPRINT_NAME=`cat blueprint/examples/blueprint-spec.yaml |python -c 'import sys, yaml, json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))' | jq .spec.blueprint | tr \" " " | awk '{print $1}' | tr -d "\n"`
rctl create blueprint $BLUEPRINT_NAME
rctl create blueprint version -f examples/blueprint-spec.yaml
```

### Jenkins Pipeline Groovy script

An example jenkins pipeline groovy script can be found [here](../blueprint/Jenkins)