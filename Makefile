#This file is part of The PA GApps script of @mfonville.
#
#    The PA GApps scripts are free software: you can redistribute it and/or modify
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
BUILD_GAPPS := $(BUILD_SYSTEM)/pa_gapps.sh
API_LEVELS := 19 21 22
PLATFORMS := arm arm64 x86
LOWESTAPI_arm := 19
LOWESTAPI_arm64 := 21
LOWESTAPI_x86 := 19
BUILDDIR := $(TOPDIR)/build
OUTDIR := $(TOPDIR)/out
LOG_BUILD := /tmp/gapps_log

define make-gapps
#We first define 'all' so that this is the primary make target
all:: $1

#With this you can always call e.g. 'make arm-22' just to make only the arm packages for 5.1
#It will execute the build script with the platform and api as parameter,
#meanwhile ensuring the minimum api for the platform that is selected
$1:		
	$(platform = $(firstword $(subst -, ,$1)))
	$(api = $(word 2, $(subst -, ,$1)))
	@if [ "$(api)" -ge "$(LOWESTAPI_$(platform))" ] ; then\
		echo "Generating PA GApps package for $(platform) with API level $(api)...";\
		$(BUILD_GAPPS) $(platform) $(api) 2>&1 | tee $(LOG_BUILD);\
		echo "--------------------------------------------------------------------";\
	fi
endef

$(foreach platform,$(PLATFORMS),$(foreach api,$(API_LEVELS),$(eval $(call make-gapps,$(platform)-$(api)))))

distclean:
	@rm -fr $(BUILDDIR)
	@echo "$(tput setaf 2)Build directory removed! Ready for a clean build$(tput sgr 0)"

