package main

//go:generate go run github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen --config=config.yaml https://github.com/zerotier/zerotier-one-api-spec/releases/latest/download/openapi.yaml

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/docker/docker/api/types/container"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/wait"

	"github.com/zerotier/zerotier-one-api-spec/examples/go/client"
)

const SECRET = "asdf"

type authtokenTransport struct {
	token string
}

func (t *authtokenTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Add("X-ZT1-Auth", t.token)
	return http.DefaultTransport.RoundTrip(req)
}

func main() {
	ctx := context.Background()

	oneContainer, _ := startZeroTierContainer(ctx)
	mappedPort, err := oneContainer.MappedPort(ctx, "9993")

	hc := http.Client{Transport: &authtokenTransport{token: SECRET}}
	oneClient, err := client.NewClient("http://localhost:"+string(mappedPort.Port()), client.WithHTTPClient(&hc))
	if err != nil {
		fmt.Println(err.Error())
	}

	response, err := oneClient.NodeStatusReadStatus(ctx)
	if err != nil {
		fmt.Println(err.Error())
	}

	if response == nil {
		panic("nil http response?")
	}
	defer response.Body.Close()

	var status client.NodeStatus
	json.NewDecoder(response.Body).Decode(&status)

	// fmt.Printf("status\n")
	// fmt.Printf("%+v\n", status)

	b, err := json.Marshal(status)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(string(b))

	dur := time.Duration(10) * time.Second
	oneContainer.Stop(ctx, &dur)
}

func startZeroTierContainer(ctx context.Context) (testcontainers.Container, error) {
	absPath, err := filepath.Abs(filepath.Join(".", "local.conf"))
	if err != nil {
		panic(err)
	}
	r, err := os.Open(absPath)
	if err != nil {
		panic(err)
	}

	req := testcontainers.ContainerRequest{
		Image:        "zerotier/zerotier:1.14.0",
		ExposedPorts: []string{"9993"},
		Privileged:   true,
		WaitingFor:   wait.ForLog("Sleeping").WithStartupTimeout(10 * time.Second),
		HostConfigModifier: func(hostConfig *container.HostConfig) {
			hostConfig.CapAdd = append(hostConfig.CapAdd, "NET_ADMIN")
		},
		Env: map[string]string{"ZEROTIER_API_SECRET": SECRET},
		Files: []testcontainers.ContainerFile{
			{
				Reader:            r,
				HostFilePath:      absPath, // will be discarded internally
				ContainerFilePath: "/var/lib/zerotier-one/local.conf",
				FileMode:          0o700,
			},
		},
	}
	container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
		ContainerRequest: req,
		Started:          true,
	})
	if err != nil {
		panic(err)
	}
	container.Start(ctx)
	time.Sleep(1 * time.Second)

	return container, err
}
