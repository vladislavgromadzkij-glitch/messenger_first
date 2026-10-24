#pragma once
#include <QObject>
#include <QString>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>

class AiWorker : public QObject
{
    Q_OBJECT
public:
    explicit AiWorker(QObject *parent = nullptr);
    ~AiWorker() override;

public slots:
    void processUserRequest(
        const QString &baseUrl,
        const QString &apiKey,
        const QString &modelName,
        const QString &userMessage
    );

signals:
    void responseReady(const QString &finalText);

private:
    QNetworkAccessManager *m_netManager = nullptr;

    static const QString s_systemPrompt;
    static const QString s_toolUnavailableMsg;
    static const QString s_unknownStepMsg;
    static const QString s_techErrorMsg;

    QJsonArray buildMessages(const QString &userMessage) const;
    QJsonArray buildMessagesSec(const QString &userMessage, const QString &exactTime) const;
    bool parseDecision(const QString &rawContent, QString &outNextStep, QString &outMessage) const;
    QByteArray sendHttpRequest(const QString &baseUrl, const QString &apiKey, const QString &modelName, const QJsonArray &messages, bool &outIsClaude);
    QString fetchNtpExactTime() const;
};
