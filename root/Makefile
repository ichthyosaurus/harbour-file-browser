.PHONY: default clean

SPEC=harbour-file-browser-root-beta.spec
SOURCES=icons harbour-file-browser-root-beta.desktop start-root-helper.c

default: $(SOURCES) $(SPEC)
	rm -rf build
	mkdir build
	cp -r $(SOURCES) build
	cd build && rpmbuild --define "debug_package %{nil}" -bb --build-in-place "../$(SPEC)" --define "_rpmdir ../RPMS"

clean:
	rm -rf build
