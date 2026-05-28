#pragma once
#include <QObject>
#include <QtQml>
#include <QString>

class Counter : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loginStatusChanged)
public:
    explicit Counter(QObject *parent = nullptr);
    bool isLoggedIn() const;
    Q_INVOKABLE void checkSavedSession();
    Q_INVOKABLE void login(const QString &identityHash, const QString &masterKeyHash);
signals:
    void loginStatusChanged();
private:
    QString m_localSessionKey;
    QString m_p2pAddress;
    bool m_isLoggedIn = false;

}; 