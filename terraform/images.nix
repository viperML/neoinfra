{ lib, ... }:
let
  inherit (lib) tfRef;
in
{
  data."oci_core_images"."always-free" = {
    compartment_id = tfRef "var.compartment_id";
    operating_system = "Oracle Linux";
    operating_system_version = "9";
    shape = "VM.Standard.E2.1.Micro";
  };
}
