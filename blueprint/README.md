## Requirements
- Linux OS
- Ensure you have [JQ (CLI based JSON Processor)](https://stedolan.github.io/jq/) installed. The script will automatically download and install if it is not detected.
- Ensure you have [cURL](https://curl.haxx.se/) installed.
- Ensure you have [PyYaml](https://pypi.org/project/PyYAML/) installed
- Credentials with permissions to provision clusters, create addons, blueprints in Rafay Platform
---
### Blueprint creation

Sample declarative specs for creating blueprint are available [here](../blueprint/examples)

### Parameters that needs to be specified in the spec file

- name - Name of the addon that will be created in Rafay Platform
- addons - List of addons that has to be included in this blueprint
- rafay_ingress - Whether to deploy Rafay manged ingress or not
- version - optional version of the blueprint
- project - Name of the project in Rafay platform where blueprint needs to be created

### Blueprint creation

```scripts/rafay_blueprint.sh -u jonh.doe@example.com -p P@ssword -f examples/blueprint-spec.yaml```
