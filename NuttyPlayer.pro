APP_NAME = NuttyPlayer

CONFIG += qt warn_on cascades10

device {
	ARCH = armle-v7
	CONFIG(release, debug|release) {
		DESTDIR = o.le-v7
	}
	CONFIG(debug, debug|release) {
		DESTDIR = o.le-v7-g
	}
}

simulator {
	ARCH = x86
	LIBS += -lsocket -lz -lbz2
	CONFIG(release, debug|release) {
		DESTDIR = o
	}
	CONFIG(debug, debug|release) {
		DESTDIR = o-g
	}
}

LIBS += -lmmrndclient -lscreen
LIBS += -lbbmultimedia
LIBS += -lbbdata
LIBS += -lbb
LIBS += -lcamapi -lscreen -L../ffmpeg/lib/lgpl/$${ARCH} -lavformat -lavcodec -lavutil -lswscale
LIBS += -lpng

INCLUDEPATH += ../src
INCLUDEPATH += ../ffmpeg/include

SOURCES += ../src/*.cpp
HEADERS += ../src/*.hpp ../src/*.h
 
TRANSLATIONS += \
    $${TARGET}_en_GB.ts \
    $${TARGET}_fr.ts \
    $${TARGET}_it.ts \
    $${TARGET}_de.ts \
    $${TARGET}_es.ts
