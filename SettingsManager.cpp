#include "SettingsManager.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QDebug>

SettingsManager::SettingsManager(QObject *parent) : QObject(parent){
    m_settingsDir = QCoreApplication::applicationDirPath() + "/usrsdata/settings";
    QDir dir(m_settingsDir);
    m_configFilePath = dir.filePath("config.json");
    m_hashtablePath = QCoreApplication::applicationDirPath() + "/usrsdata/hashtables";
    SettingsManager::ensureDirectoriesExist();
    SettingsManager::loadSettings();
}

QVariantMap SettingsManager::customization() const {
    return m_customization;
}

void SettingsManager::ensureDirectoriesExist(){
    QDir dir(m_settingsDir);
    if(!dir.exists()){
        dir.mkpath(".");
    }
    QDir profilesDir(QCoreApplication::applicationDirPath() + "/usrsdata/profiles");
    if(!profilesDir.exists()){
        profilesDir.mkpath(".");
    }
    QDir hashtableDir(m_hashtablePath);
    if(!hashtableDir.exists()){
        hashtableDir.mkpath(".");
    }
}
void SettingsManager::restoreDefaultSettings(){
    QJsonObject defaultSettings;
    // Цвета
    defaultSettings["currentBgMain"]            = "#1a2a32"; // Глубокий темно-сине-зеленый
    defaultSettings["currentBgElement"]         = "#233742"; // Цвет элементов
    defaultSettings["currentBgElementHover"]    = "#2d4554"; // Ховер элементов
    defaultSettings["currentBgElementActive"]   = "#16232b"; // Клик на элемент
    defaultSettings["currentBorderColor"]       = "#3d7e7a"; // Спокойный мятно-зеленый
    defaultSettings["currentAccentColor"]       = "#4edbca"; // Яркая сочная мята
    defaultSettings["currentTextColorMain"]     = "#ffffff"; // Белый текст
    defaultSettings["currentTextColorSecond"]   = "#8bb3ad"; // Блеклый мятно-серый текст
    // Шрифты
    defaultSettings["currentFontFamily"]        = "sans-serif";
    defaultSettings["currentFontSizeBase"]      = 14;
    defaultSettings["currentFontSizeTitle"]     = 20;
    defaultSettings["currentFontBold"]          = false;
    // Геометрия и Эффекты
    defaultSettings["currentRadiusButton"]      = 8;
    defaultSettings["currentBorderWidth"]       = 1;
    defaultSettings["animationsEnabled"]        = true;
    defaultSettings["currentAnimDuration"]      = 200;
    QJsonDocument doc(defaultSettings);
    QFile file(m_configFilePath);
    if(file.open(QIODevice::WriteOnly)){
        file.write(doc.toJson());
        file.close();
    }
    m_customization = defaultSettings.toVariantMap();
    emit customizationChanged();
} 
void SettingsManager::loadSettings(){
    QFile file(m_configFilePath);
    if(!file.exists()){restoreDefaultSettings(); return;}
    if(!file.open(QIODevice::ReadOnly)){restoreDefaultSettings(); return;}
    QByteArray rawData = file.readAll();
    file.close();
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(rawData, &err);
    if(err.error != QJsonParseError::NoError || doc.isNull() || !doc.isObject()){restoreDefaultSettings(); return;}
    m_customization = doc.object().toVariantMap();
    emit customizationChanged();
}
void SettingsManager::saveSettings(){
    QJsonObject obj = QJsonObject::fromVariantMap(m_customization);
    QJsonDocument doc(obj);
    QFile file(m_configFilePath);
    if(file.open(QIODevice::WriteOnly)){
        file.write(doc.toJson());
        file.close();
    }
}
void SettingsManager::updateSettings(const QString &key, const QVariant &value){
    m_customization[key] = value;
    saveSettings();
    emit customizationChanged();
}