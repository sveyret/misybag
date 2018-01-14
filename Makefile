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

# Application id
APP_PACKNAME=MisybaG
APP_VERSION=2.0
APP_AUTHOR=Stéphane Veyret

# Sources and targets
EXEC=misybag
MO_SRC=$(wildcard po/*.po)
MO=$(MO_SRC:.po=.mo)
PREFIX=

all: $(EXEC) $(MO)

misybag: misybag.sh
	sed -e 's#^\:\ \$${MISYBAG_CONFIG_DIR:="#&$(PREFIX)#' $^ >$@

po/$(APP_PACKNAME).pot:
	xgettext --package-name="$(APP_PACKNAME)" --package-version="$(APP_VERSION)" --copyright-holder="$(APP_AUTHOR)" -o "$@" -F -L shell --from-code UTF-8 misybag

%.po: po/$(APP_PACKNAME).pot
	[[ ! -f "$@" ]] || msgmerge -U "$@" "$<"
	[[ -f "$@" ]] || msginit -o "$@" -i "$<" -l "$(notdir $*)" --no-translator

%.mo: %.po
	msgfmt -o $@ $<

install:
	install -D -m755 misybag "$(DESTDIR)$(PREFIX)/usr/bin/misybag"
	install -d -m755 "$(DESTDIR)$(PREFIX)/usr/share/MisybaG"
	cp -dPR --preserve=mode -- data/* "$(DESTDIR)$(PREFIX)/usr/share/MisybaG"
	for lang in po/*.mo; do \
		if [[ -f $${lang} ]]; then \
			install -D -m644 $${lang} "$(DESTDIR)$(PREFIX)/usr/share/locale/$$(basename $${lang} .mo)/LC_MESSAGES/MisybaG.mo"; \
		fi \
	done
	for dir in $$(find "$(DESTDIR)$(PREFIX)/usr/share/MisybaG" -type d); do \
		if [[ -r "$${dir}/.keep" ]]; then \
			rm -f "$${dir}/.keep"; \
		fi \
	done

clean:

mrproper: clean
	rm -f misybag
	rm -f po/*.mo

.PHONY: all install clean mrproper
