###############################################################################
# Copyright © 2016 Stéphane Veyret stephane_DOT_veyret_AT_neptura_DOT_org
#
# This file is part of MisybaG.
#
# MisybaG is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# MisybaG is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# MisybaG.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

SRC= $(wildcard po/*.po)
MO= $(SRC:.po=.mo)

all: $(MO)

# Building po files:
# xgettext -o lang.po -F -j -L shell --from-code UTF-8 misybag
%.mo: %.po
	msgfmt -o $@ $<

install:
	install -D -m755 misybag "$(DESTDIR)/usr/bin/misybag"
	install -d -m755 "$(DESTDIR)/usr/share/MisybaG"
	cp -dPR --preserve=mode -- data/* "$(DESTDIR)/usr/share/MisybaG"
	for lang in po/*.mo; do \
		if [[ -f $${lang} ]]; then \
			install -D -m644 $${lang} "$(DESTDIR)/usr/share/locale/$$(basename $${lang} .mo)/LC_MESSAGES/MisybaG.mo"; \
		fi \
	done
	for dir in $$(find "${DESTDIR}/usr/share/MisybaG" -type d); do \
		if [[ -r "$${dir}/.keep" ]]; then \
			rm -f "$${dir}/.keep"; \
		fi \
	done

clean:
	rm -f po/*.mo

mrproper: clean

.PHONY: install clean mrproper
