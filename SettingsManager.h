#pragma once
#include <QObject>
#include <QVariantMap>
#include <QString>
#include <QStringList>

class SettingsManager : public QObject
{
  Q_OBJECT
  public:
  explicit SettingsManager(QObject *parent = nullptr);
  Q_INVOKABLE void verifyBackupPath(const QString &path);
  ~SettingsManager() override;
  //static - потому что мы хотим вызывать эти методы без создания экземпляра класса SettingsManager. Они будут использоваться для проверки наличия сохраненных профилей и настроек, а также для исправления настроек при необходимости.
  // Эти методы не зависят от состояния конкретного объекта SettingsManager, поэтому их можно вызывать напрямую через имя класса.
  // Например, мы можем вызвать SettingsManager::getSavedProfiles() без создания объекта SettingsManager.
  // мы не создаем экземпляр класса SettingsManager, чтобы проверить наличие сохраненных профилей или настроек, а просто вызываем эти методы напрямую через имя класса.
  //это делается для удобства и эффективности, чтобы избежать лишнего создания объектов, когда нам нужно просто проверить состояние или выполнить проверку.
  public slots:
  void onProfilesAnalysisCompleted(const QStringList& validProfiles, const QStringList& corruptedProfiles, const QString& lastUsedName, const QString& lastUsedPath, void* criticalDataAddress);
  void initForProfile(const QString &profileUuid);
  void loadSettings();
  signals:
  void backupPathValid();
  void backupPathInvalid(const QString &reason);
  void fallbackRequested();// если профилей нет 
  void authStateResolved(const QString &username, const QString &profilePath, const QStringList &validProfiles, const QStringList &corruptedProfiles, bool hasPin, bool isNode);
  void requestProfileAnalysis(const QStringList &profiles);//сигнал для запроса анализа профилей
  void recoveryRequested(const QStringList &corruptedProfiles);//сигнал при наличии ТОЛЬКО битых файловпрофилей
  private:
  QString m_pendingBackupPath;
  void secureWipeString(QString &str);
  QString m_configFilePath;
  QString m_settingsDir;
  void* m_criticalDataAddress = nullptr;
};