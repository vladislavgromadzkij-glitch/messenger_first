#pragma once
#include <QObject>
#include <QStringList>
#include <QString>
#include <QVariantMap>
#include <cstdint>
#include <QHash>

#pragma pack(push, 1)
struct AccountPrimaryHeader {
int64_t lastUsedDate;// 8 байт
int64_t nextCheckDate;// 8 байт
int64_t nodeExpireDate;// 8 байт
uint32_t decryptedDataSize;//4 байта
uint8_t pinHash[32];//32 байта
uint8_t passwordHash[32];// 32 байта
uint8_t pinSalt[16];// 16 байт
uint8_t privateKey[16];// 16 байт
uint8_t publicKey[16];// 16 байт
uint8_t passwordSalt[16];// 16 байт
bool wasLastUsed;// 1 байт
bool hasPin;// 1 байт
bool isNode;// 1 байт
char email[64];// 64 байта
char username[32];// 32 байта
char phone[20];// 20 байт
uint8_t trashedData[13]; //процессору будет проще читать данные, и 86 и 64 и 32 битные смогут легко чтитать
};
#pragma pack(pop)
class CryptoVault : public QObject
{
    Q_OBJECT
    public:
    explicit CryptoVault(QObject *parent = nullptr);
    ~CryptoVault() override;
    public slots:
    void analyzeProfiles(const QStringList &profiles);
    signals:
    void primaryDataDecrypted(const QString &userName, const QString &avatarPath, const QVariantMap &uiSettings, bool isNode);
    void chatDecryptionStarted();
    void authFailed();
    void profilesAnalysisCompleted(const QStringList& validProfiles, const QStringList& corruptedProfiles, const QString& lastUsedName, const QString& lastUsedPath, void* criticalDataAddress);
    private:
    uint8_t m_deviceKey[32];
    void initializeDeviceKey();
    bool validateAndDecryptProfile(const QString &profileUuid);
    QHash <QString, AccountPrimaryHeader> m_activeProfilesHash;//хэш активных профилей, ключ - uuid профиля, значение - структура с данными профиля
    bool decryptHardwareGCM(uint8_t* cipherData, int dataSize, uint8_t* iv, uint8_t* tag, uint8_t* key);

};
