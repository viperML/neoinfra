import logging
import os
from pathlib import Path

import oci

logging.basicConfig(level=logging.INFO)

STEPPATH = os.getenv("STEPPATH")
if not STEPPATH:
    logging.warn("STEPPATH not found as env variable!")
    exit(1)
else:
    STEPPATH = Path(STEPPATH)


logging.info(f"{STEPPATH=}")


signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
identity_client = oci.identity.IdentityClient(config={}, signer=signer)

storage = oci.object_storage.ObjectStorageClient(config={}, signer=signer)

ns = storage.get_namespace().data
bn = "step"

for parent in {"certs", "secrets"}:
    p = STEPPATH / parent
    p.mkdir(parents=True, exist_ok=True)

filenames = {
    "certs/intermediate_ca.crt",
    "certs/root_ca.crt",
    "certs/ssh_host_ca_key.pub",
    "certs/ssh_user_ca_key.pub",
    #
    "secrets/intermediate_ca_key",
    "secrets/root_ca_key",
    "secrets/ssh_host_ca_key",
    "secrets/ssh_user_ca_key",
    #
    "secrets/password_intermediate"
}

for filename in filenames:
    logging.info(f"Querying {filename}")
    object = storage.get_object(ns, bn, filename).data
    with open(STEPPATH / filename, "wb") as file:
        file.write(object.content)
