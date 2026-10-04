//точка входа в приложение, здесь выделяется память и управление потоками
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QThread>
#include <QMetaObject>
#include "SettingsManager.h"
#include "CryptoVault.h"

int main(int argc, char *argv[])
{
QGuiApplication app(argc, argv);
QQmlApplicationEngine engine;
SettingsManager* settingsManager = new SettingsManager();
CryptoVault* cryptoVault = new CryptoVault();
QThread* ioThread = new QThread(nullptr);
cryptoVault->moveToThread(ioThread);// Перемещаем объекты settingsManager и cryptoVault в отдельный поток
//сам поток, указательно его метод finished, будет удалять объект SettingsManager и сам поток после завершения работы затирая всю память, выделенную под них
QObject::connect(ioThread, &QThread::finished, ioThread, &QObject::deleteLater);// Подключаем сигнал завершения потока к удалению самого потока
QObject::connect(ioThread, &QThread::finished, cryptoVault, &QObject::deleteLater);// Подключаем сигнал завершения потока к удалению объекта CryptoVault
QObject::connect(cryptoVault, &CryptoVault::profilesAnalysisCompleted, settingsManager, &SettingsManager::onProfilesAnalysisCompleted);//Подключаем сигнал передачи профиля от криптоядра
QObject::connect(settingsManager, &SettingsManager::requestProfileAnalysis, cryptoVault, &CryptoVault::analyzeProfiles);// Подключаем сигнал запроса анализа профилей от SettingsManager к слоту analyzeProfiles в CryptoVault

ioThread->start();
engine.rootContext()->setContextProperty("settingsManager", settingsManager);// Передаем объект SettingsManager в QML
QMetaObject::invokeMethod(settingsManager, "loadSettings", Qt::QueuedConnection);// Вызываем метод loadSettings() в отдельном потоке
engine.loadFromModule("first", "Main");// Загружаем QML-файл
int exitCode = app.exec();// Запускаем главный цикл приложения app - это блокирующая функция, которая будет выполняться до тех пор, пока приложение не завершится 
// exec() возвращает код завершения приложения, который мы сохраняем в переменной exitCode
ioThread->quit(); // Завершаем поток после завершения работы приложения
ioThread->wait(); // Ждем завершения потока, чтобы убедиться, что все ресурсы освобождены перед выходом из main()
return exitCode;// Возвращаем код завершения приложения
}