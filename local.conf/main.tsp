import "@typespec/json-schema";

using TypeSpec.JsonSchema;

@jsonSchema
model LocalConf {
  settings?: OptionalProperties<Settings>;
  physical?: OptionalProperties<Physical>;
  virtual?: OptionalProperties<Virtual>;
}

model Physical is Record<PhysicalMap>;

@extension("additionalProperties", Json<false>)
model PhysicalMap {
  blacklist: boolean;
  trustedPathId: uint16;
  // mtu: uint16; not implemented
}

model Virtual is Record<VirtualMap>;

@extension("additionalProperties", Json<false>)
model VirtualMap {
  try: Array<IPSlashPort>;
  blacklist: Array<NetworkSlashBits>;
}

model Settings {
  @summary("Override default port of 9993 and any command line port. It's preferred to override secondaryPort instead.")
  primaryPort: Port;

  @summary("Override default randomly selected secondary port.")
  secondaryPort: Port;

  tertiaryPort: Port;
  portMappingEnabled: boolean;
  interfacePrefixBlacklist: Array<InterfacePrefix>;
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
