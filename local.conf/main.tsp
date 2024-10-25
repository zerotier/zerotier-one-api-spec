import "@typespec/json-schema";

using TypeSpec.JsonSchema;

@jsonSchema
model LocalConf {
  settings?: Settings;
  physical?: Physical;
  virtual?: Virtual;
}

model Physical is Record<OptionalProperties<_Physical>>;

@extension("additionalProperties", Json<false>)
model _Physical{
  blacklist: boolean = false;
  trustedPathId: uint16;
  // mtu: uint16; not implemented
}

model Virtual is Record<OptionalProperties<_Virtual>>;

@extension("additionalProperties", Json<false>)
model _Virtual {
  @summary("Hints on where to reach this peer if no upstreams/roots are online")
  try: Array<IPSlashPort>;

  @summary("Blacklist a physical path for only this peer. ")
  blacklist: Array<NetworkSlashBits>;
}

model Settings is OptionalProperties<_Settings>;
model _Settings {
  @summary("Override default port of 9993 and any command line port. It's preferred to override secondaryPort instead.")
  primaryPort: Port;

  @summary("Override default randomly selected secondary port.")
  secondaryPort: Port;

  @summary("Override third randomly selected port. This port is used for mapping")
  tertiaryPort: Port;

  @summary("Enable UPnP and NAT-PMP. Default: True")
  portMappingEnabled: boolean = true;

  @summary("Array of interface name prefixes (e.g. eth for eth#) to blacklist for ZT traffic")
  interfacePrefixBlacklist: Array<InterfacePrefix>;

  @summary("If non-NULL, allow JSON/HTTP management from this IP network. Default is 127.0.0.1 only.")
  allowManagementFrom: Array<NetworkSlashBits>;

  @summary("bind to these IPs instead of to each interface")
  bind: Array<IP>;
}

scalar IPSlashPort extends string;
scalar NetworkSlashBits extends string;

@format("ipv4")
scalar IPv4 extends string;

@format("ipv6")
scalar IPv6 extends string;

alias IP = IPv4 | IPv6;

scalar Port extends uint16;

//@pattern("[a-z]+")
scalar InterfacePrefix extends string;
