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
This integration test requires zerotier-one to be running. It may change configuration of your node! It runs in github actions too.

``` sh
AUTH_TOKEN=$(cat /path/to/authtoken.secret) npm test
```

If you have a pre-release version of zerotier-one try:

``` sh
ENABLE_UNSTABLE=1 npm t
```


## missing features
Features not implemented by typespec yet

- [ openapi examples ](https://github.com/microsoft/typespec/issues/2700)
- [ tag descriptions ](https://github.com/microsoft/typespec/issues/2220)


## publishing
How to create a github [release](https://github.com/zerotier/zerotier-one-api-spec/releases/).

Releases contain the openapi and json-schema files.
 
Try to use [conventional commit](https://www.conventionalcommits.org/en/v1.0.0/#summary) messages if you want. They will appear in the changelog.

This is a multistep process now due to branch protection. 

### Locally, create version: 
When main is in a state you'd like to create a new release for:

- create a feature branch off `main`
- `npm version major|minor|patch`
    This bumps the version and updates the changelog
- commit && push 
- create PR
- when the action finishes, you can check the output artifacts index.html
- get merged to `main`

### On Github, create release: 
- Go into the repo's Github Actions
- Click "tag and release"
- Click Run Workflow
- Run it off `main`


The url to the latest release of the openapi spec is: `https://github.com/zerotier/zerotier-one-api-spec/releases/latest/download/openapi.yaml` 

