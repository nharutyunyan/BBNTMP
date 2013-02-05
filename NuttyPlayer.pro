APP_NAME = NuttyPlayer

CONFIG += qt warn_on cascades10

LIBS += -lmmrndclient -lscreen
LIBS += -lbbmultimedia
LIBS += -lbbdata
LIBS += -lbb

INCLUDEPATH += ../src
SOURCES += ../src/*.cpp

HEADERS += ../src/*.hpp ../src/*.h

TRANSLATIONS += \
    $${TARGET}_en_GB.ts \
    $${TARGET}_fr.ts \
    $${TARGET}_it.ts \    
    $${TARGET}_de.ts \
    $${TARGET}_es.ts

