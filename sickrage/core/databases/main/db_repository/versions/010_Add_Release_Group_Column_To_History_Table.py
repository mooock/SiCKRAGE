# ##############################################################################
#  Author: echel0n <echel0n@sickrage.ca>
#  URL: https://sickrage.ca/
#  Git: https://git.sickrage.ca/SiCKRAGE/sickrage.git
#  -
#  This file is part of SiCKRAGE.
#  -
#  SiCKRAGE is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  -
#  SiCKRAGE is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  -
#  You should have received a copy of the GNU General Public License
#  along with SiCKRAGE.  If not, see <http://www.gnu.org/licenses/>.
# ##############################################################################

from sqlalchemy import *


def upgrade(migrate_engine):
    meta = MetaData(bind=migrate_engine)
    history = Table('history', meta, autoload=True)
    if not hasattr(history.c, 'release_group'):
        release_group = Column('release_group', Text, default='')
        release_group.create(history)


def downgrade(migrate_engine):
    meta = MetaData(bind=migrate_engine)
    history = Table('history', meta, autoload=True)
    if hasattr(history.c, 'release_group'):
        history.c.release_group.drop()
