#include <QDir>
#include <QDebug>
#include <iostream>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "counter.h"
#include "SettingsManager.h"
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    SettingsManager settingsManager;    
    engine.rootContext()->setContextProperty("settingsManager", &settingsManager);
    const QUrl url(QStringLiteral("qrc:/qt/qml/first/Main.qml"));
    engine.load(url);
    if (engine.rootObjects().isEmpty()) {return -1;}
    return app.exec();
}
