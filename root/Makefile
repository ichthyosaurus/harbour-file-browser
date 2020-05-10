.PHONY: default clean

SPEC=harbour-file-browser-root-beta.spec
SOURCES=icons harbour-file-browser-root-beta.desktop start-root-helper.c

default: $(SOURCES) $(SPEC)
	rm -rf build
	mkdir build
	cp -r $(SOURCES) build
	cd build && rpmbuild --define "debug_package %{nil}" --define "_rpmdir ../RPMS" --target "$(BUILDARCH)" -bb --build-in-place "../$(SPEC)"

clean:
	rm -rf build
