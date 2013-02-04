APP_NAME = NuttyPlayer

CONFIG += qt warn_on cascades10

LIBS += -lmmrndclient -lscreen
LIBS += -lbbmultimedia
LIBS += -lbbdata

TRANSLATIONS += \
    $${TARGET}_en_GB.ts \
    $${TARGET}_fr.ts \
    $${TARGET}_it.ts \    
    $${TARGET}_de.ts \
    $${TARGET}_es.ts
        
include(config.pri)
