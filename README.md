# ZeroTierOne API Spec
OpenAPI and JSON-schema for the [ZeroTierOne](https://github.com/zerotier/ZeroTierOne) service API. 

This is the API that lets you leave and join networks on your local machine, or configure a self-hosted network controller.

The specs are generated from a [typespec](https://typespec.io/) spec.

## dev

``` sh
npm install 
npm start
```

Open http://localhost:8080

## test
The integration test requires docker to be running. 

``` sh
npm test
```


## missing features
Features not implemented by typespec yet

- [ openapi examples ](https://github.com/microsoft/typespec/issues/2700)
- [ tag descriptions ](https://github.com/microsoft/typespec/issues/2220)


## publishing
How to create a github [release](https://github.com/zerotier/zerotier-one-api-spec/releases/).

Releases contain the openapi and json-schema files.
 
Try to use [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/#summary) messages if you want. They will appear in the changelog.

- Go to the Actions Tab
- Click Release on the left
- Click Run Workflow on the right
- Type in the appropriate version (patch)
- Click run


The url to the latest release of the openapi spec is: `https://github.com/zerotier/zerotier-one-api-spec/releases/latest/download/openapi.yaml` 

