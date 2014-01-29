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
DEFINES += _FILE_OFFSET_BITS=64
DEFINES += _LARGEFILE64_SOURCE=1

LIBS += -lmmrndclient -lscreen
LIBS += -lbbmultimedia
LIBS += -lbbdata
LIBS += -lbb
LIBS += -lcamapi -lscreen 
LIBS += -L../ffmpeg/lib
LIBS += -lavformat -lavcodec -lavutil -lswscale
LIBS += -lbz2
LIBS += -lpng
LIBS += -lbbdevice
LIBS += -lbbsystem
LIBS += -lbbplatformbbm -lbbsystem
LIBS += -lstrm
LIBS += -lbbsystem
LIBS += -lbbcascadespickers

INCLUDEPATH += ../src ../src/libmaia
INCLUDEPATH += ../ffmpeg/include

SOURCES += ../src/*.cpp ../src/libmaia/*.cpp
HEADERS += ../src/*.hpp ../src/*.h ../src/libmaia/*.h

QT += network xml
 
TRANSLATIONS += \
    $${TARGET}_en_GB.ts \
    $${TARGET}_fr.ts \
    $${TARGET}_it.ts \
    $${TARGET}_de.ts \
    $${TARGET}_es.ts
