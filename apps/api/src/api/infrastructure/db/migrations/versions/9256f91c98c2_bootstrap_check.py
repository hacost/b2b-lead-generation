"""bootstrap_check

Migración cero: prueba que la tubería de Alembic funciona (aplicar y
revertir) antes de la primera entidad de negocio real. No agrega ningún
modelo de dominio.

Revision ID: 9256f91c98c2
Revises:
Create Date: 2026-09-26 08:37:48.590456

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "9256f91c98c2"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "_bootstrap_check",
        sa.Column("id", sa.Integer, primary_key=True),
    )


def downgrade() -> None:
    op.drop_table("_bootstrap_check")
