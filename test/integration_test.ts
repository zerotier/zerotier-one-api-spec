import { readFileSync } from "node:fs";
import { describe, it } from "node:test";
import assert from "node:assert";

import createClient from "openapi-fetch";
import { PathsWithMethod } from "openapi-typescript-helpers";
import type { paths } from "/tmp/schema.ts"; // generated by openapi-typescript

import Ajv, { DefinedError } from "ajv/dist/2020";
import addFormats from "ajv-formats";
import betterAjvErrors from "better-ajv-errors";

if (!process.env.AUTH_TOKEN) {
  console.error("No AUTH_TOKEN env var set. Exiting.");
  process.exit(1);
}

function createCreateClient() {
  // AUTH_TOKEN=`cat ~/Library/Application\ Support/ZeroTier/One/authtoken.secret ` npm t
  const authToken = process.env.AUTH_TOKEN;
  const client = createClient<paths>({
    baseUrl: "http://localhost:9993/",
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

function assertValid({ validate, schema }, data: object | undefined) {
  const valid = validate(data);
  if (!valid) {
    const output = betterAjvErrors(
      schema,
      data,
      validate.errors as DefinedError[],
    );
    console.error(JSON.stringify(validate.errors, null, 4));
    console.error(JSON.stringify(data, null, 4));
    assert.fail(output);
  }
}

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

      const client = createCreateClient();

      const { data } = await client.GET(path, {});
      assert.ok(data);

      assertValid(validator, data);
    });
  }
});

describe("API exercise", async function () {
  const client = createCreateClient();
  let network_id: string;
  const node_id = "1122334455";

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

  it("Creates a  controller network member", async () => {
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

  it("Deletes the network by ID", async () => {
    const { data: networkData3 } = await client.DELETE(
      "/controller/network/{network_id}",
      { params: { path: { network_id } } },
    );
    const networkDelValidator = createValidator("ControllerNetwork");
    assertValid(networkDelValidator, networkData3);
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
  /// unstable
  it("Lists full networks", async () => {
    const { data, response } = await client.GET("/unstable/controller/network");
    if (response.status !== 404) {
      assert(data);

      const networksValidator = createValidator("ControllerNetworks");

      assertValid(networksValidator, data);
    }
  });

  it("Lists full network members", async () => {
    const { data, response } = await client.GET(
      "/unstable/controller/network/{network_id}/member",
    );
    if (response.status !== 404) {
      assert(data);

      const networksValidator = createValidator(
        "ControllerNetworkMemberListFull",
      );

      assertValid(networksValidator, data);
    }
  });
});
