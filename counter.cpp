#include "counter.h"
#include <QDebug>

Counter::Counter(QObject *parent) : QObject(parent) {
    checkSavedSession();
}

bool Counter::isLoggedIn() const {
    return m_isLoggedIn;
} 
void Counter::checkSavedSession() {}

void Counter::login(const QString &username, const QString &password) {}