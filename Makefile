# Signifies our desired python version
# Makefile macros (or variables) are defined a little bit differently than traditional bash, keep in mind that in the Makefile there's top-level Makefile-only syntax, and everything else is bash script syntax.

# .PHONY defines parts of the makefile that are not dependant on any specific file
# This is most often used to store functions
.PHONY = help setup format build install uninstall checks unittest integration-test clean

folders := scripts tests
files := $(shell find . -name "*.sh")

# Uncomment to store cache installation in the environment
# package_dir := $(shell python -c 'import site; print(site.getsitepackages()[0])')
package_dir := .make_cache
package_name=$(shell grep 'name:' snap/snapcraft.yaml | tail -n1 | awk '{print $$2}')

SHFMT_EXISTS := $(shell command -v shfmt 2> /dev/null)
SNAP_EXISTS := $(shell snap list | grep $(package_name) 2> /dev/null)

$(shell mkdir -p $(package_dir))

pre_deps_tag := $(package_dir)/.pre_deps
checks_tag := $(package_dir)/.check_tag
build_tag := $(package_dir)/.build_tag
install_tag := $(package_dir)/.install_tag
setup_tag := $(package_dir)/.setup_tag

# ======================
# Rules and Dependencies
# ======================

help:
	@echo "---------------HELP-----------------"
	@echo "Package Name: $(package_name)"
	@echo " "
	@echo "Type 'make' followed by one of these keywords:"
	@echo " "
	@echo "  - setup for installing base requirements"
	@echo "  - format for reformatting files to adhere to PEP8 standards"
	@echo "  - build for creating the SNAP file"
	@echo "  - install for installing the package"
	@echo "  - uninstall for uninstalling the environment"
	@echo "  - checks for running format, mypy, lint and tests altogether"
	@echo "  - unittest for running unittests"
	@echo "  - integration-test for running integration tests"
	@echo "  - clean for removing cache file"
	@echo "------------------------------------"


$(pre_deps_tag):
ifndef SHFMT_EXISTS
	@echo "Installing shftm"
	sudo snap install shfmt
	touch $(pre_deps_tag)
else
	@echo "shftm already installed"
	shfmt --version
	touch $(pre_deps_tag)
endif

$(setup_tag): $(pre_deps_tag)
	@echo "==Setting up environment=="
	sudo sysctl -w vm.swappiness=0
	sudo sysctl -w vm.max_map_count=262144
	sudo sysctl -w net.ipv4.tcp_retries2=5
	touch $(setup_tag)

setup: $(setup_tag)

format: setup $(files)
	@echo "==Formatting files==="
	shfmt -w scripts

unittest: setup $(files)
	@echo "==Unittests==="

checks: unittest format
	touch $(checks_tag)

$(checks_tag): format unittest
	@echo "===Checks DONE==="
	touch $(checks_tag)

$(build_tag): $(checks_tag) snap/snapcraft.yaml
	@echo "==Building SNAP=="
	snapcraft
	ls -rt  *.snap | tail -1 > $(build_tag)

build: $(build_tag)

$(install_tag): $(build_tag)
	@echo "==Installing SNAP $(package_name)=="
	sudo snap install $(shell cat $(build_tag)) --dangerous
	touch $(install_tag)

install: $(install_tag)

uninstall:
	@echo "==Uninstall SNAP $(package_name)=="
	sudo snap remove $(package_name)
	rm -f $(install_tag)

integration-tests:
ifndef SNAP_EXISTS
	@echo "Installing snap first"
	make install
	./tests/integration/ie-tests.sh
else
	@echo "snap already installed"
	./tests/integration/ie-tests.sh
endif

clean:
	@echo "==Cleaning environment=="
	rm -rf *.snap
	rm -rf $(package_dir)
