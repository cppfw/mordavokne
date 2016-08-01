include prorab.mk

$(eval $(prorab-build-subdirs))


$(prorab-clear-this-vars)


this_soname_dependency := $(prorab_this_dir)src/soname.txt
this_soname := $(shell cat $(this_soname_dependency))

$(eval $(prorab-build-deb))


define this_rules
install::
#resource files
	$(prorab_echo)for i in $(patsubst $(prorab_this_dir)morda_res/%,/%,$(shell find $(prorab_this_dir)morda_res -type f -name "*")); do \
		install -d $(DESTDIR)$(PREFIX)/share/morda/res$(this_soname)$$$${i%/*}; \
		install $(prorab_this_dir)morda_res$$$$i $(DESTDIR)$(PREFIX)/share/morda/res$(this_soname)$$$$i; \
	done
endef
$(eval $(this_rules))

