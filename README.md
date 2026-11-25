# ZeroTierOne API Spec
OpenAPI and JSON-schema for the [ZeroTierOne](https://github.com/zerotier/ZeroTierOne) service API. 

This is the API that lets you leave and join networks on your local machine, or configure a self-hosted network controller.

The specs are generated from a [typespec](https://typespec.io/) spec.

## dev

``` sh
npm install 
npm start
```

Open `dist/index.html`. It is rebuilt after each change to `main.tsp`.

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

1. On a new branch, set the new version (`patch`, `minor` or `major`):
   ``` sh
   npm version minor --no-git-tag-version
   ```
2. Update the changelog:
   ``` sh
   npx auto-changelog -p
   ```
3. Commit `package.json`, `package-lock.json` and `CHANGELOG.md`, and open a pull request.
4. After the merge, go to the Actions Tab.
5. Click Release on the left.
6. Click Run Workflow on the right, then click Run Workflow.

The workflow tags the head of `main` with the version in `package.json`. Then it makes the release. It does not push to `main`.


The url to the latest release of the openapi spec is: `https://github.com/zerotier/zerotier-one-api-spec/releases/latest/download/openapi.yaml` 

