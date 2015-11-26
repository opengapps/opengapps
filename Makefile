#This file is part of The Open GApps script of @mfonville.
#
#    The Open GApps scripts are free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    These scripts are distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
TOPDIR := .
BUILD_SYSTEM := $(TOPDIR)/scripts
BUILD_GAPPS := $(BUILD_SYSTEM)/build_gapps.sh
APIS := 19 21 22 23
PLATFORMS := arm arm64 x86 x86_64
LOWEST_API_arm := 19
LOWEST_API_arm64 := 21
LOWEST_API_x86 := 19
LOWEST_API_x86_64 := 21
VARIANTS := super stock full mini micro nano pico aroma
BUILDDIR := $(TOPDIR)/build
CACHEDIR := $(TOPDIR)/cache
OUTDIR := $(TOPDIR)/out
LOG_BUILD := /tmp/gapps_log

define make-gapps
#We first define 'all' so that this is the primary make target
all:: $1

#With this you can always call e.g. 'make arm-22' or 'make arm-22-stock'
#to make the arm (stock) package for 5.1
#It will execute the build script with the platform, api (and variant) as parameter,
#meanwhile ensuring the minimum api for the platform that is selected
$1:
	$(platform = $(firstword $(subst -, ,$1)))
	$(api = $(word 2, $(subst -, ,$1)))
	$(variant = $(word 3, $(subst -, ,$1)))
	@if [ "$(api)" -ge "$(LOWEST_API_$(platform))" ] && [ -n "$(variant)" ] ; then\
		echo "Generating Open GApps $(variant) package for $(platform) with API level $(api)...";\
		$(BUILD_GAPPS) $(platform) $(api) $(variant) 2>&1 | tee $(LOG_BUILD);\
	elif [ "$(api)" -ge "$(LOWEST_API_$(platform))" ] && [ -z "$(variant)" ] ; then\
		for variant in $(VARIANTS);do\
			$(BUILD_GAPPS) $(platform) $(api) $$$$variant 2>&1 | tee $(LOG_BUILD);\
		done;\
	else\
		echo "Illegal combination of Platform and API";exit 1;\
	fi
	@echo "--------------------------------------------------------------------";
endef

$(foreach platform,$(PLATFORMS),\
$(foreach api,$(APIS),\
$(foreach variant,$(VARIANTS),\
$(eval $(call make-gapps,$(platform)-$(api)-$(variant)))\
)))

$(foreach platform,$(PLATFORMS),\
$(foreach api,$(APIS),\
$(eval $(call make-gapps,$(platform)-$(api)))\
))

tidycache:
	@find "$(CACHEDIR)/"* -atime +7 -exec rm {} \;
	@echo "$(tput setaf 2)Cache cleaned, archives not used for 7 days removed!$(tput sgr 0)"

clean:
	@rm -fr "$(BUILDDIR)"
	@echo "$(tput setaf 2)Build directory removed!$(tput sgr 0)"

distclean: clean
	@rm -fr "$(CACHEDIR)"
	@echo "$(tput setaf 2)Cache directory removed!$(tput sgr 0)"
