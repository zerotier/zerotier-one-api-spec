import { readFileSync } from "node:fs";
import { describe, it, before } from "node:test";
import assert from "node:assert";
import semver from "semver";

import { GenericContainer } from "testcontainers";
import createClient from "openapi-fetch";
import { PathsWithMethod } from "openapi-typescript-helpers";
import type { paths } from "/tmp/schema.ts"; // generated by openapi-typescript

import _Ajv from "ajv/dist/2020.js";
import _addFormats from "ajv-formats";
import { AnyValidateFunction } from "ajv/dist/core.js";

const Ajv = _Ajv.default;
const addFormats = _addFormats.default;

const ZT_VERSION = process.env.ZT_VERSION || "1.14.0";

function createCreateClient(token: string, port: number) {
  const authToken = token;
  const client = createClient<paths>({
    baseUrl: `http://localhost:${port}/`,
    headers: { "X-ZT1-AUTH": authToken },
  });

  return client;
}

function createValidator(schemaId: string) {
  const specJson = readFileSync(
    "./tsp-output/@typespec/json-schema/json-schema.json",
    { encoding: "utf8" },
  );
  const schema = JSON.parse(specJson);

  const ajv = new Ajv({ allErrors: false });
  addFormats(ajv);
  ajv.addSchema(schema);

  const validate = ajv.getSchema(schemaId);
  assert(validate);

  return { validate, schema };
}

function assertValid(
  { validate }: { validate: AnyValidateFunction },
  data: object | undefined,
) {
  const valid = validate(data);
  if (!valid) {
    console.error(JSON.stringify(data, null, 4));
    assert.fail(JSON.stringify(validate.errors, null, 4));
  }
}

const ZEROTIER_API_SECRET = "asdf";

describe("API exercise", async function () {
  let network_id: string;
  const node_id = "1122334455";
  let container;
  let client: ReturnType<typeof createCreateClient>;
  let apiPort: number;

  before(async () => {
    container = await new GenericContainer(`zerotier/zerotier:${ZT_VERSION}`)
      .withExposedPorts(9993)
      .withPrivilegedMode()
      .withAddedCapabilities("NET_ADMIN")
      .withEnvironment({ ZEROTIER_API_SECRET })
      .withCopyContentToContainer([
        {
          content: `{ "settings": { "allowManagementFrom": ["0.0.0.0/0"] } }`,
          target: "/var/lib/zerotier-one/local.conf",
        },
      ])
      .start();
    apiPort = container.getMappedPort(9993);
    client = createCreateClient(ZEROTIER_API_SECRET, apiPort);
  });

  describe("GET endpoints", async function () {
    const map: { path: PathsWithMethod<paths, "get">; id: string }[] = [
      { path: "/status", id: "NodeStatus" },
      { path: "/controller", id: "ControllerStatus" },
      { path: "/network", id: "JoinedNetworks" },
      { path: "/peer", id: "Peers" },
    ];

    for (const { path, id } of map) {
      it(id, async () => {
        const validator = createValidator(id);

        const { data } = await client.GET(path, {});
        assert.ok(data);

        assertValid(validator, data);
      });
    }
  });

  it("Creates a valid controller network", async () => {
    const { data: networkData } = await client.POST("/controller/network", {
      body: {},
    });
    assert(networkData);

    const cnValidator = createValidator("ControllerNetwork");

    assertValid(cnValidator, networkData);

    network_id = networkData.id;
  });

  it("Gets the controller network by ID", async () => {
    const { data } = await client.GET("/controller/network/{network_id}", {
      params: { path: { network_id } },
    });
    assert(data);

    const networkValidator = createValidator("ControllerNetwork");

    assertValid(networkValidator, data);
  });

  it("Lists controller networks ", async () => {
    const { data } = await client.GET("/controller/network");
    assert(data);

    const networkValidator = createValidator("ControllerNetworkIDList");

    assertValid(networkValidator, data);
    assert.ok(data.includes(network_id));
  });

  it("Creates a controller network member", async () => {
    const { data } = await client.POST(
      "/controller/network/{network_id}/member/{node_id}",
      {
        params: { path: { network_id, node_id } },
        body: { authorized: true },
      },
    );
    assert(data);

    const validator = createValidator("ControllerNetworkMember");

    assertValid(validator, data);

    assert.equal(data.id, "1122334455");
  });

  it("Lists controller network members", async () => {
    const { data } = await client.GET(
      "/controller/network/{network_id}/member",
      { params: { path: { network_id } } },
    );
    assert(data);

    const validator = createValidator("ControllerNetworkMemberList");

    assertValid(validator, data);

    assert.ok(Object.keys(data).includes("1122334455"));
  });

  it("Deletes a controller network member", async () => {
    const { data } = await client.DELETE(
      "/controller/network/{network_id}/member/{node_id}",
      {
        params: { path: { network_id, node_id } },
      },
    );
    assert(data);

    const validator = createValidator("ControllerNetworkMember");

    assertValid(validator, data);
  });

  describe("Joining networks", async () => {
    const network_id = "ff00160016000000";

    it("Joins a network", async () => {
      const { data } = await client.POST("/network/{network_id}", {
        body: {},
        params: { path: { network_id } },
      });
      assert(data);
      const validator = createValidator("JoinedNetwork");
      assertValid(validator, data);
    });

    it("Gets the joined networks", async () => {
      const { data } = await client.GET("/network");
      assert(data);

      const validator = createValidator("JoinedNetworks");
      assertValid(validator, data);

      const ids = data.map((network) => network.id);
      assert.ok(ids.includes(network_id));
    });

    it("Gets the joined network by ID", async () => {
      const { data } = await client.GET("/network/{network_id}", {
        params: { path: { network_id } },
      });
      assert(data);

      const validator = createValidator("JoinedNetwork");
      assertValid(validator, data);

      assert.equal(network_id, data.id);
    });

    it("Leaves the joined network by ID", async () => {
      const { data } = await client.DELETE("/network/{network_id}", {
        params: { path: { network_id } },
      });
      assert(data);

      const validator = createValidator("LeaveResult");
      assertValid(validator, data);
    });
  });

  describe(
    "Unstable APIs",
    { skip: semver.lte(ZT_VERSION, "1.12.2") },
    async () => {
      it("Sets the member name", async () => {
        const { data } = await client.POST(
          "/controller/network/{network_id}/member/{node_id}",
          {
            params: { path: { network_id, node_id } },
            body: { authorized: true, name: "bob" },
          },
        );
        assert(data);

        const validator = createValidator("ControllerNetworkMember");
        assertValid(validator, data);
      });

      it("Lists full networks", async () => {
        const { data } = await client.GET("/unstable/controller/network");
        assert(data);

        const networksValidator = createValidator("ControllerNetworks");

        assertValid(networksValidator, data);
      });

      it("Lists full network members", async () => {
        const { data } = await client.GET(
          "/unstable/controller/network/{network_id}/member",
          { params: { path: { network_id } } },
        );
        assert(data);

        const networksValidator = createValidator(
          "ControllerNetworkMemberListFull",
        );

        assertValid(networksValidator, data);
      });

      it("Gets the member name", async () => {
        const { data } = await client.GET(
          "/controller/network/{network_id}/member/{node_id}",
          {
            params: { path: { network_id, node_id } },
          },
        );
        assert(data);
        assert.equal("bob", data.name);

        const validator = createValidator("ControllerNetworkMember");
        assertValid(validator, data);
      });
    },
  );

  it("Deletes the network by ID", async () => {
    const { data } = await client.DELETE("/controller/network/{network_id}", {
      params: { path: { network_id } },
    });
    const networkDelValidator = createValidator("ControllerNetwork");
    assertValid(networkDelValidator, data);
  });
});
