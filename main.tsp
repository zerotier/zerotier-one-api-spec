import "@typespec/http";
import "@typespec/openapi";
import "@typespec/json-schema";
import "./variables.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;
using TypeSpec.JsonSchema;

@service({
  title: "ZeroTierOne Service",
  version: Version,
})
@info({
  license: {
    name: "Apache 2.0",
    url: "http://www.apache.org/licenses/LICENSE-2.0.html",
  },
})
@useAuth(ApiKeyAuth<ApiKeyLocation.header, "X-ZT1-AUTH">)
@server(" http://localhost:9993", "Service API")
@doc("""
<p>This API controls the ZeroTier service that runs in the background on your computer. This is how zerotier-cli, and the macOS and Windows apps control the service. </p>
<p>API requests must be authenticated via an authentication token. ZeroTier One saves this token in the authtoken.secret file in its working directory. This token may be supplied via the X-ZT1-Auth HTTP request header. </p>
<p>For example: <code>curl -H "X-ZT1-Auth: $TOKEN" http://localhost:9993/status</code> </p>
<p>The token can be found in: <ul> <li>Mac :: ~/Library/Application Support/ZeroTier/authtoken.secret</li> <li>Windows :: \\ProgramData\\ZeroTier\\One</li> <li>Linux :: /var/lib/zerotier-one</li> </ul> </p>
<p>Learn more about the spec at <a href="https://github.com/zerotier/zerotier-one-api-spec">github</a></p>
""")
namespace Root {
  @tag("Node Status")
  @route("/status")
  namespace node_status {
    @get
    @summary("Node Status")
    op readStatus(): NodeStatus | AuthError;
  }

  @tag("Joined Networks")
  @route("/network")
  namespace network_membership {
    @doc("All the networks that this node is joined to")
    @summary("List Joined Networks")
    @get
    op readNetworks(): JoinedNetwork[] | AuthError;

    @route("/{network_id}")
    @doc("Joined Network by ID")
    @summary("Get Joined Network by ID")
    @get
    op getNetwork(
      @path network_id: ZTNetworkID,
    ): JoinedNetwork | AuthError | NotFoundError;

    @summary("Join or Update Network Settings")
    @post
    op setNetwork(
      @path network_id: ZTNetworkID,
      @body settings: JoinedNetworkRequest,
    ): JoinedNetwork | AuthError | NotFoundError;

    @summary("Leave Network")
    @delete
    op delNetwork(
      @path network_id: ZTNetworkID,
    ): LeaveResult | AuthError | NotFoundError;
  }

  @tag("Peers")
  @route("/peer")
  namespace node_peer {
    @doc("All the nodes your node knows about")
    @summary("List Peers")
    @get
    op readNetworks(): Peer[] | AuthError;

    @route("/{network_id}")
    @doc("Get Peer by ID")
    @summary("Get Joined Network by ID")
    @get
    op getNetwork(
      @path network_id: ZTNetworkID,
    ): Peer | AuthError | NotFoundError;
  }

  @tag("Controller")
  @route("/controller")
  namespace controller {
    @doc("Controller healthcheck")
    @summary("Controller Status")
    @get
    op readControllerStatus(): ControllerStatus | AuthError;

    @route("/network")
    namespace network {
      @doc("List IDs of all networks hosted by this controller")
      @summary("List Network IDs")
      @get
      op readNetworks(): ControllerNetworkIDList | AuthError;

      @route("/{network_id}")
      namespace network {
        @doc("Get details for a network by its ID.")
        @summary("Get Network by ID")
        @get
        op readNetwork(
          @path network_id: ZTNetworkID,
        ): ControllerNetwork | AuthError | NotFoundError;

        @summary("Create or Update Network")
        @post
        op postNetwork(
          @path network_id: ZTNetworkID,
          @body network: ControllerNetworkRequest,
        ): ControllerNetwork | AuthError | NotFoundError;

        @summary("Delete Network")
        @delete
        op deleteNetwork(
          @path network_id: ZTNetworkID,
        ): ControllerNetwork | AuthError | NotFoundError;

        @route("/member")
        namespace networkMembers {
          @doc("Object containing all member IDs as keys and their memberRevisionCounter values as values")
          @summary("List Network Member IDs ")
          @get
          op listNetworkMembers(
            @doc("Network ID of the Network")
            @path
            network_id: ZTNetworkID,
          ): ControllerNetworkMemberList | AuthError | NotFoundError;

          @route("/{node_id}")
          namespace networkMember {
            @summary("Get Network Member by ID")
            @get
            op getNetworkMember(
              @doc("Node ID of the Network Member")
              @path
              node_id: ZTAddress,

              @doc("Network ID of the Network")
              @path
              network_id: ZTNetworkID,
            ): ControllerNetworkMember | AuthError | NotFoundError;

            @summary("Create or Update Network Member")
            @post
            op postNetworkMember(
              @doc("Node ID of the Network Member")
              @path
              node_id: ZTAddress,

              @doc("Network ID of the Network")
              @path
              network_id: ZTNetworkID,

              @body network: ControllerNetworkMemberRequest,
            ): ControllerNetworkMember | AuthError | NotFoundError;

            @summary("Delete Network Member")
            @delete
            op delNetworkMember(
              @doc("Node ID of the Network Member")
              @path
              node_id: ZTAddress,

              @doc("Network ID of the Network")
              @path
              network_id: ZTNetworkID,
            ): ControllerNetworkMember | AuthError | NotFoundError;
          }
        }
      }
      @route("/")
      namespace randomNetwork {
        @doc("Create a new network with a random ID.")
        @summary("Generate Random Network ID")
        @post
        op randomNetwork(
          @doc("Node ID of the controller")
          @body
          network: ControllerNetworkRequest,
        ): ControllerNetwork | AuthError | NotFoundError;
      }
    }
  }
  @tag("Unstable")
  @route("/unstable")
  namespace unstable {
    @route("/controller")
    namespace controller {
      @route("/network")
      namespace network {
        @doc("List all networks")
        @summary("List all networks")
        @get
        op readNetworks2(): ControllerNetworks | AuthError;
        @route("/{network_id}")
        namespace network_id {
          @route("/member")
          namespace member {
            @doc("List all Network Members")
            @summary("List all Network Members")
            @get
            op listNetworkMembers2(
              @doc("Network ID of the Network")
              @path
              network_id: ZTNetworkID,
            ): ControllerNetworkMemberListFull | AuthError | NotFoundError;
          }
        }
      }
    }
  }
}

@jsonSchema
model LeaveResult {
  result: true;
}

@jsonSchema
model NodeStatus {
  address: ZTAddress;
  clock: uSafeint;
  config: {
    settings: {
      allowManagementFrom?: IP[];
      allowTcpFallbackRelay: boolean;
      forceTcpRelay: boolean;
      listeningOn: IPSlashPort[];
      portMappingEnabled: boolean;
      primaryPort: Port;
      secondaryPort: Port;
      softwareUpdate: string;
      softwareUpdateChannel: string;
      surfaceAddresses: IPSlashPort[];
      tertiaryPort: Port;
    };
  };
  online: boolean;
  planetWorldId: uSafeint;
  planetWorldTimestamp: uSafeint;
  publicIdentity: string;
  tcpFallbackActive: boolean;
  version: string;
  versionBuild: VersionDigit | -1;
  versionMajor: VersionDigit | -1;
  versionMinor: VersionDigit | -1;
  versionRev: VersionDigit | -1;
}

@jsonSchema
model JoinedNetwork extends Record<unknown> {
  ...JoinedNetworkProps;
  assignedAddresses: string[];
  bridge: boolean;
  broadcastEnabled: boolean;
  dns: NetworkDNS | EmptyArray;
  @key id: ZTNetworkID;
  mac: string;
  mtu: MTU;
  multicastSubscriptions: Array<{
    adi: uSafeint;
    mac: string;
  }>;

  @format("uri")
  authenticationURL?: string;

  authenticationExpiryTime?: uSafeint;
  name: string;
  netconfRevision: uint16;
  portDeviceName: string;
  portError: int32;
  routes: {
    flags: uint16;
    metric: uint16;
    target: IPSlashPort;
    via?: IP | null;
  }[];
  status: NetworkStatus;
  type: "PUBLIC" | "PRIVATE";
}

@jsonSchema
model JoinedNetworks is JoinedNetwork[];

@jsonSchema
model JoinedNetworkRequest {
  ...OptionalProperties<JoinedNetworkProps>;
}

model JoinedNetworkProps {
  allowDNS: boolean;
  allowDefault: boolean;
  allowManaged: boolean;
  allowGlobal: boolean;
}

@jsonSchema
model Peer {
  @key address: ZTAddress;
  isBonded: boolean;
  latency: uSafeint | -1;
  paths: {
    active: boolean;
    address: IPSlashPort;
    expired: boolean;
    lastReceive: uSafeint;
    lastSend: uSafeint;
    localSocket: uSafeint;
    preferred: boolean;
    trustedPathId: uSafeint;
  }[];
  role: "LEAF" | "PLANET" | "MOON";
  version: string;
  versionMajor: VersionDigit | -1;
  versionMinor: VersionDigit | -1;
  versionRev: VersionDigit | -1;
  tunneled: boolean;
}

@jsonSchema
model Peers is Peer[];

@jsonSchema
model ControllerStatus {
  controller: true;
  apiVersion: VersionDigit;
  clock: uSafeint;
  databaseReady: boolean;
}

@jsonSchema
model ControllerNetwork {
  ...ControllerNetworkProps;
  @key id: ZTNetworkID;
  nwid: ZTNetworkID;
  creationTime: uSafeint;
  objtype: "network";
  revision: uSafeint;
  capabilities: NetworkCaps;
  rules: NetworkRule[];
  tags: NetworkTags;
}

model ControllerNetworkMeta {
  ...ControllerNetwork;
  meta: {
    authorizedMemberCount: uSafeint;
    totalMemberCount: uSafeint;
  };
}

@jsonSchema
model ControllerNetworks {
  data: ControllerNetworkMeta[];
  meta: {
    networkCount: uSafeint;
  };
}

@jsonSchema
model ControllerNetworkRequest {
  ...OptionalProperties<ControllerNetworkProps>;
}

model ControllerNetworkProps {
  name: string;
  enableBroadcast: boolean;
  mtu: MTU;
  dns: NetworkDNS | EmptyArray;
  private: boolean;
  ipAssignmentPools: {
    ipRangeStart: IP;
    ipRangeEnd: IP;
  }[];
  v4AssignMode: {
    zt?: boolean;
  };
  v6AssignMode: {
    `6plane`?: boolean;
    rfc4193?: boolean;
    zt?: boolean;
  };
  multicastLimit: uSafeint;
  routes: {
    target: IP;
    via?: IP | null;
  }[];
}

@jsonSchema
model ControllerNetworkMember {
  @key id: ZTAddress;
  ...ControllerNetworkMemberProps;
  address: ZTAddress;
  authenticationExpiryTime: uSafeint;
  capabilities: uSafeint[];
  creationTime: uSafeint;
  identity?: string;
  lastAuthorizedCredential: string | null;
  lastAuthorizedCredentialType: string;
  lastAuthorizedTime: uSafeint;
  lastDeauthorizedTime: uSafeint;
  nwid: ZTNetworkID;
  objtype: "member";
  remoteTraceLevel: uSafeint;
  remoteTraceTarget: string | null;
  revision: VersionDigit;
  tags: unknown; //TODO
  vMajor: VersionDigit | -1;
  vMinor: VersionDigit | -1;
  vProto: VersionDigit | -1;
  vRev: VersionDigit | -1;
}

@jsonSchema
model ControllerNetworkMemberRequest {
  ...OptionalProperties<ControllerNetworkMemberProps>;
}

model ControllerNetworkMemberProps {
  authorized: boolean;
  activeBridge: boolean;
  ipAssignments: IP[];
  noAutoAssignIps: boolean;
  ssoExempt: boolean;
}

@jsonSchema
model ControllerNetworkIDList is ZTNetworkID[];

@error
model AuthError {
  @statusCode statusCode: 401;
  @body error: {};
}

@error
model NotFoundError {
  @statusCode statusCode: 404;
  @body error: {};
}

@pattern("[a-f0-9]{10}")
scalar ZTAddress extends string;

@pattern("[a-f0-9]{16}")
scalar ZTNetworkID extends string;

@format("ipv4")
scalar IPv4 extends string;

@format("ipv6")
scalar IPv6 extends string;

alias IP = IPv4 | IPv6;

scalar IPSlashPort extends string;

@minValue(1280)
scalar MTU extends uint32;

@minValue(0)
scalar VersionDigit extends uint8;

@minValue(0)
scalar Clock extends safeint;

@minValue(0)
scalar uSafeint extends safeint;

@minItems(2)
@maxItems(2)
model NetworkCap is integer[];
model NetworkCaps is NetworkCap[];

@minItems(2)
@maxItems(2)
model NetworkTag is integer[];
model NetworkTags is NetworkTag[];

model NetworkRule extends Record<unknown> {
  not?: boolean;
  or?: boolean;
  type: string;
}

model NetworkDNS {
  domain: domain | "";
  servers: IP[];
}

@minItems(0)
@maxItems(0)
model EmptyArray is Array<unknown>;

@format("hostname")
scalar domain extends string;

@jsonSchema
model ControllerNetworkMemberList is Record<int32>;

@jsonSchema
model ControllerNetworkMemberListFull {
  data: ControllerNetworkMember[];
  meta: {
    totalCount: uSafeint;
    authorizedCount: uSafeint;
  };
}

@minValue(0)
scalar Port extends uint16;

alias NetworkStatus =
  | "REQUESTING_CONFIGURATION"
  | "OK"
  | "ACCESS_DENIED"
  | "NOT_FOUND"
  | "PORT_ERROR"
  | "CLIENT_TOO_OLD"
  | "AUTHENTICATION_REQUIRED";
