"""
Connector base class.

Every collection source implements this contract. Registration is how a new
lane or source gets added — nothing else in the pipeline needs to change.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from enum import Enum


class OSINTDomain(str, Enum):
    ATTACK_SURFACE = "attack_surface"
    IMPERSONATION = "impersonation"


@dataclass
class Provenance:
    source_tool: str
    method: str
    captured_at: datetime
    authorization_ref: str  # hash of the signed authorization record


@dataclass
class Artifact:
    entity_type: str
    value: str
    provenance: Provenance


@dataclass
class AuthorizedTarget:
    domain: str
    authorization_id: str
    dcv_verified: bool


class Connector(ABC):
    name: str
    domain: OSINTDomain

    @abstractmethod
    async def collect(self, target: AuthorizedTarget) -> list[Artifact]:
        """Return raw artifacts, each carrying a Provenance record.

        Must refuse any target that is not dcv_verified.
        """
        raise NotImplementedError

    def health(self) -> dict:
        return {"name": self.name, "status": "not_implemented"}
