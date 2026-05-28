#pragma once
#include <QObject>
#include <QVariantMap>

class SettingsManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap customization READ customization NOTIFY customizationChanged)
    public:
        explicit SettingsManager(QObject *parent = nullptr);
        QVariantMap customization() const;
        Q_INVOKABLE void updateSettings(const QString &key, const QVariant &value);
    signals:
        void customizationChanged();
    private:
        QString m_settingsDir;
        QString m_configFilePath;
        QString m_hashtablePath;
        QVariantMap m_customization;
        void ensureDirectoriesExist();
        void restoreDefaultSettings();
        void loadSettings();
        void saveSettings();
};