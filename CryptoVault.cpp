#include "CryptoVault.h"
#include <QFile>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QThread>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <cstring>

#ifdef Q_OS_WIN
    #include <windows.h>
    #include <wincred.h>
#elif defined(Q_OS_MAC)
    #include <Security/Security.h> // Apple Keychain API
    #include <CoreFoundation/CoreFoundation.h>
#elif defined(Q_OS_LINUX) 
#undef signals
    #include <libsecret/secret.h>  // Linux Secret Service API
#endif

CryptoVault::CryptoVault(QObject *parent) : QObject(parent) {
    // Пока оставляем пустым
}

void CryptoVault::analyzeProfiles(const QStringList &profiles) {
    initializeDeviceKey(); //получаем 32 байта ключа для расшифровки алгоритма AES-256-GCM, который хранится в защищенном хранилище ОС
    QStringList corruptedProfiles;
    QStringList validProfiles;
    QString latestUsedUuid;
    int64_t maxLastUsedDate = -1;
    QString lastUsedName = "0";
    QString lastUsedPath = "pathDoesNotExist";
    void* criticalDataAddress = nullptr;
    for (const QString &uuid : profiles) {
        QString profilePath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/profiles/" + uuid + "/profile.vault";
        QFile vaultFile(profilePath);
        qint64 fileSize = vaultFile.size();
        if (fileSize < (sizeof(AccountPrimaryHeader) + 28) || fileSize > (1024 * 1024)) {
            corruptedProfiles.append(uuid);
            continue;
        } //защита от слишком больших файлов которые могут содержать иньекции или мусор
        if (!vaultFile.open(QIODevice::ReadOnly)) {
            corruptedProfiles.append(uuid);
            continue;
        }
        //здесь мы читаем файлы
        AccountPrimaryHeader header; // обьявляем структуру для хранения данных
        quint64 bytesRead = 0;
        int attempts = 3; 
        uint8_t iv[12], authTag[16];
        
        while (attempts > 0) {  //несколько безопасных попыток чтения чтоб избежать ошибок из- за различных блокировок файловой системы
            qint64 ivRead = vaultFile.read(reinterpret_cast<char*>(iv), 12); //читаем 12 байт соли
            qint64 headerRead = vaultFile.read(reinterpret_cast<char*>(&header), sizeof(AccountPrimaryHeader)); //читаем 128 байт самого файла используя добытый ключ 
            qint64 tagRead = vaultFile.read(reinterpret_cast<char*>(authTag), 16); //читаем 16 байт тега аутентификации
            bytesRead = ivRead + headerRead + tagRead;
            if (bytesRead == (12 + sizeof(AccountPrimaryHeader) + 16)) { break; }
            vaultFile.seek(0);
            QThread::msleep(5);
            attempts--;            
        }
        
        if (bytesRead != sizeof(AccountPrimaryHeader) + 28) {
            corruptedProfiles.append(uuid);
            vaultFile.close();
            continue;
        }
        vaultFile.close();
        
        bool isDecrypted = decryptHardwareGCM(reinterpret_cast<uint8_t*>(&header), sizeof(AccountPrimaryHeader), iv, authTag, m_deviceKey);
        // расшифровываем данные профиля используя ключ из защищенного хранилища ОС
        if (isDecrypted) {
            validProfiles.append(uuid);
            m_activeProfilesHash.insert(uuid, header);
            if (header.lastUsedDate > maxLastUsedDate) {
                maxLastUsedDate = header.lastUsedDate;
                latestUsedUuid = uuid;
                int nameLen = qstrnlen(header.username, 32);
                lastUsedName = QString::fromUtf8(header.username, nameLen);
                if (lastUsedName.isEmpty()) {
                    lastUsedName = "0"; 
                }
                lastUsedPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/profiles/" + uuid;
            }
        } else {
            corruptedProfiles.append(uuid);
        }
    }
    if (validProfiles.isEmpty()) {
        emit authFailed();
        return;
    }
    criticalDataAddress = reinterpret_cast<void*>(&m_activeProfilesHash[latestUsedUuid]);
    emit profilesAnalysisCompleted(validProfiles, corruptedProfiles, lastUsedName, lastUsedPath, criticalDataAddress);
}

bool CryptoVault::decryptHardwareGCM(uint8_t* cipherData, int dataSize, uint8_t* iv, uint8_t* tag, uint8_t* key){
    EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new(); // создаем новый контекст шифрования
    if(!ctx){return false;}
    int outlen = 0;
    // 1. Выбираем движок
    if(EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), nullptr, nullptr, nullptr) != 1){
        EVP_CIPHER_CTX_free(ctx);
        return false;
    }
    // 2. Настраиваем движок (длина IV = 12)
    if(EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, 12, nullptr) != 1){
        EVP_CIPHER_CTX_free(ctx);
        return false;
    }
    // 3. Заряжаем секреты (Key и IV)
    if (EVP_DecryptInit_ex(ctx, nullptr, nullptr, key, iv) != 1) {
        EVP_CIPHER_CTX_free(ctx);
        return false;
    }
    // 4. Расшифровка
    if(EVP_DecryptUpdate(ctx, cipherData, &outlen, cipherData, dataSize) != 1){
        EVP_CIPHER_CTX_free(ctx);
        return false;
    }
    // 5.передача эталонного тега
    if(EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, tag) != 1){
        EVP_CIPHER_CTX_free(ctx);
        return false;
    }
    int finalLen = 0;
    bool success = (EVP_DecryptFinal_ex(ctx, cipherData + outlen, &finalLen) > 0);
    EVP_CIPHER_CTX_free(ctx);
    return success;

}
void CryptoVault::initializeDeviceKey(){
    #ifdef Q_OS_WIN
    LPCWSTR targetName = L"CryptoVault_DeviceKey";
    PCREDENTIALW credential = nullptr; // адресс ключа
    bool hasKey = CredReadW(targetName, CRED_TYPE_GENERIC, 0, &credential);
    if(hasKey && credential != nullptr){
        memcpy(m_deviceKey, credential->CredentialBlob, 32);
        CredFree(credential);
    } else {
        RAND_bytes(m_deviceKey, 32);
        CREDENTIALW newCred = {0};
        newCred.Type = CRED_TYPE_GENERIC;
        newCred.TargetName = const_cast<LPWSTR>(targetName);
        newCred.CredentialBlobSize = 32;
        newCred.CredentialBlob = m_deviceKey;
        newCred.Persist = CRED_PERSIST_LOCAL_MACHINE;
        CredWriteW(&newCred, 0);

    }
    #elif defined(Q_OS_MAC)
    CFStringRef accountName = CFSTR("CryptoVault_DeviceKey");
    CFTypeRef dataTypeRef = NULL;
    CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
     // создание таблицы в которой все хранится
    CFDictionaryAddValue(query, kSecClass, kSecClassGenericPassword);// мы ищем пароль
    CFDictionaryAddValue(query, kSecAttrAccount, accountName);// сужаем поиск в бинарнике до конкретного ключа с нашим названием
    CFStringRef serviceName = CFSTR("CryptoVaultMesh");
    CFDictionaryAddValue(query, kSecAttrService, serviceName);
    CFDictionaryAddValue(query, kSecReturnData, kCFBooleanTrue);
    OSStatus status = SecItemCopyMatching(query, &dataTypeRef);
    CFRelease(query);
    if(status == errSecSuccess && dataTypeRef != NULL){
        CFDataRef keyData = (CFDataRef)dataTypeRef;
        if(CFDataGetLength(keyData) == 32){
            memcpy(m_deviceKey, CFDataGetBytePtr(keyData), 32);
        }
        CFRelease(dataTypeRef);
    } else {
        RAND_bytes(m_deviceKey, 32);
        CFDataRef keyData = CFDataCreate(NULL, m_deviceKey, 32);
        CFMutableDictionaryRef addQuery = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionaryAddValue(addQuery, kSecClass, kSecClassGenericPassword);
        CFDictionaryAddValue(addQuery, kSecAttrAccount, accountName);
        CFDictionaryAddValue(addQuery, kSecAttrService, serviceName);
        CFDictionaryAddValue(addQuery, kSecValueData, keyData);
        SecItemAdd(addQuery, NULL);
        CFRelease(addQuery);
        CFRelease(keyData);
    }
    #elif defined(Q_OS_LINUX)
    GError* error = nullptr;
    gchar* storedKey = secret_password_lookup_sync(SECRET_SCHEMA_COMPAT_NETWORK, nullptr, &error, "user", "CryptoVault_DeviceKey", nullptr);
    if (error != nullptr) {
        g_error_free(error);
        qFatal("Критический сбой шины D-Bus!");
    }
    if(storedKey != nullptr){
        memcpy(m_deviceKey, storedKey, 32);
        secret_password_free(storedKey);
    } else {
        RAND_bytes(m_deviceKey, 32);
        gboolean result = secret_password_store_sync(SECRET_SCHEMA_COMPAT_NETWORK, SECRET_COLLECTION_DEFAULT, "CryptoVault Master Key", reinterpret_cast<const gchar*>(m_deviceKey), nullptr, &error, "user", "CryptoVault_DeviceKey", nullptr);
        if (error != nullptr) {
            g_error_free(error);
            qFatal("Критический сбой шины D-Bus при записи!");
    }
    }
    //мы теперь имеем ключ в переменной m_deviceKey
    #endif
}

CryptoVault::~CryptoVault() {
    // DSE-устойчивое затирание памяти ключа
    OPENSSL_cleanse(m_deviceKey, sizeof(m_deviceKey));
    
    // Затираем все расшифрованные профили в ОЗУ
    for (auto it = m_activeProfilesHash.begin(); it != m_activeProfilesHash.end(); ++it) {
        OPENSSL_cleanse(&(it.value()), sizeof(AccountPrimaryHeader));
    }
    m_activeProfilesHash.clear();
}