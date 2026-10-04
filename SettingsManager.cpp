//Читает JSON, выжигает ключи нулями при уничтожении.
#include "SettingsManager.h"
#include <QFile>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QDebug>
#include <QFileInfo>

SettingsManager::SettingsManager(QObject *parent) : QObject(parent){

}
void SettingsManager::loadSettings(){
QDir profilesDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/profiles";
if(!profilesDir.exists()){
    profilesDir.mkpath(".");//создаем папку профилей
    emit fallbackRequested();//сообщаем потоку 1 что у нас нет профилей и надо открыть окно регистрации с возможностью перехода в окно входа
    return;
}
QStringList profiles = profilesDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot); // NoDotAndDotDot исключает "." - текущая дерриктория и ".." - родительская директория
// а значит мы имеем папки с профилями и их информацией и их мы отправим в криптоядро для анализа
if(profiles.isEmpty()){
    emit fallbackRequested();
    return;
}
emit requestProfileAnalysis(profiles);//отправляем список профилей в крипоядро;
}
void SettingsManager::onProfilesAnalysisCompleted(const QStringList& validProfiles, const QStringList& corruptedProfiles, const QString& lastUsedName, const QString& lastUsedPath, void* criticalDataAddress){
    m_criticalDataAddress = criticalDataAddress;
    if(validProfiles.isEmpty()){
        if(!corruptedProfiles.isEmpty()){
            emit recoveryRequested(corruptedProfiles);
            return;
        }
        emit fallbackRequested();
        return;
    }
    bool hasPin = false;
    bool isNode = false;
    const uint8_t* baseAddr = reinterpret_cast<const uint8_t*>(m_criticalDataAddress); // получаем адресс критических данных
    hasPin = *reinterpret_cast<const bool*>(baseAddr + 157); //получаем есть ли у нас  пинкoд
    isNode = *reinterpret_cast<const bool*>(baseAddr + 158); //получаем есть ли у нас прапва на нoду
    emit authStateResolved(lastUsedName, lastUsedPath, validProfiles, corruptedProfiles, hasPin, isNode);
}
void SettingsManager::secureWipeString(QString &str) {
    if (!str.isEmpty()) {
        str.fill('\0'); // Аппаратно забиваем сектора ОЗУ нулевыми байтами
        str.clear();    // Сбрасываем длину строки
    }
}
void SettingsManager::initForProfile(const QString &profileUuid) {
    
}
SettingsManager::~SettingsManager(){
    
}
void SettingsManager::verifyBackupPath(const QString &path) {
    QDir dir(path);
    if (!dir.exists()) {
        emit backupPathInvalid("Директория не существует");
        return;
    }
    if (!dir.isAbsolute()) {
        emit backupPathInvalid("Путь должен быть абсолютным");
        return;
    }
    QFileInfo info(path);
    if (!info.isWritable()) {
        emit backupPathInvalid("ОС отказала в праве на запись");
        return;
    }
    m_pendingBackupPath = path;
    emit backupPathValid();
}