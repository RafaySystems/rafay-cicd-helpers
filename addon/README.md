## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed. The script will automatically download and install if it is not detected.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- Credentials with permissions to provision clusters, create addons, blueprints in Rafay Platform
---
### Addon creation

Sample declarative specs for creating addon are available [here](../addon/examples)

### Parameters that needs to be specified in the spec file

- name - Name of the addon that will be created in Rafay Platform
- type - Type of the manifest that addon is packaged. It has to be either "NativeYaml" or "Helm"
- namespace - Name of the namespace where addon has to be published
- payload - location to the file
- version - optional version of the addon
- project - Name of the project in Rafay platform where addon needs to be created

### Addon creation

```scripts/rafay_addon.sh -u jonh.doe@example.com -p P@ssword -f examples/cert-manager-spec.yaml```

### Jenkins Pipeline Groovy script

An example jenkins pipeline groovy script can be found [here](../addon/Jenkins)