{lib, ...}: let
  inherit (lib) tfRef;
in {
  data."oci_core_images"."base-aarch64" = {
    compartment_id = tfRef "var.compartment_id";
    operating_system = "Oracle Linux";
    operating_system_version = "9";
    shape = "VM.Standard.A1.Flex";
  };

  # output "base-aarch64" {
  #   value = data.oci_core_images.base-aarch64.images[0].id
  # }

  data."oci_core_images"."always-free" = {
    compartment_id = tfRef "var.compartment_id";
    operating_system = "Oracle Linux";
    operating_system_version = "9";
    shape = "VM.Standard.E2.1.Micro";
  };

  # output "always-free" {
  #   value = data.oci_core_images.always-free.images[0].id
  # }
}
