# golang client example

``` sh
go generate
go run main.go
```

This example uses https://github.com/oapi-codegen/oapi-codegen to generate a golang client from the spec. 
There may be other generators out there that you prefer to use. 

The example starts an instance of zerotier-one in a docker container and then queries it with the generated client. 

