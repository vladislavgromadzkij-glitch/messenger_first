import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Window
import first

ApplicationWindow {
    id: root
    visible: true
    width: 1600
    height: 900
    flags: Qt.Window | Qt.FramelessWindowHint
    property bool isChecking: false
    property string errorMsg: ""

    QtObject {
        id: coreVisual
        property string presetId: "theme_orbital_green" 
        property color bgMain: "#0B0F19"
        property color bgHeader: "#111726"
        property color bgPanel: "#161D2B"
        property color messageOur: "#10B981"
        property color messageTheir: "#64748B"
        property color textMain: "#F8FAFC"
        property int baseRadius: 14
    }

    QtObject {
        id: coreTypography
        property string presetId: "builtin_inter_standard"
        property string fontFamilyMain: "Inter"
        property int fontSizeMain: 14
        property int fontSizeSmall: 12
        property bool isMainBold: false
        property bool isSecondaryBold: false
    }

    QtObject {
        id: advancedConfig
        property string presetId: "builtin_layout_pro"
        property bool isAdvancedMode: true
        property string chatListPosition: "left"
        property string chatInfoPosition: "right"
        property bool shadersEnabled: false
        property string activeShaderPath: ""
    }

    // Верхняя системная шапка окна (выделена цветом и нижней границей)
    Rectangle {
        id: customHeader
        width: parent.width
        height: 32 
        color: coreVisual.bgHeader
        z: 10

        // Аппаратная линия разделения шапки и рабочей области (1px)
        Rectangle {
            width: parent.width
            height: 1
            anchors.bottom: parent.bottom
            color: "#1E293B"
        }

        // Перехват перетаскивания окна средствами ОС
        DragHandler {
            onActiveChanged: if (active) root.startSystemMove()
        }

        Row {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Rectangle {
                width: 46; height: parent.height
                color: minMouse.containsMouse ? "#2634D399" : "transparent"
                
                Text { 
                    text: "—"
                    color: minMouse.containsMouse ? "#34D399" : coreVisual.messageTheir 
                    anchors.centerIn: parent
                    font.pixelSize: 14 
                }
                
                MouseArea { 
                    id: minMouse
                    anchors.fill: parent
                    hoverEnabled: true 
                    onClicked: root.showMinimized() 
                }
            }

            Rectangle {
                width: 46; height: parent.height
                color: maxMouse.containsMouse ? "#26FBBF24" : "transparent"
                
                Text { 
                    text: root.visibility === Window.Maximized ? "❐" : "☐" 
                    color: maxMouse.containsMouse ? "#FBBF24" : coreVisual.messageTheir 
                    anchors.centerIn: parent
                    font.pixelSize: 16 
                }
                
                MouseArea { 
                    id: maxMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
                }
            }

            Rectangle {
                width: 46; height: parent.height
                color: closeMouse.containsMouse ? "#26FB7185" : "transparent"
                
                Text { 
                    text: "✕"
                    color: closeMouse.containsMouse ? "#FB7185" : coreVisual.messageTheir 
                    anchors.centerIn: parent
                    font.pixelSize: 14 
                }
                
                MouseArea { 
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.close() 
                }
            }
        }
    }

    StackView {
        id: windowStack 
        anchors.fill: parent 

        Rectangle {
            anchors.fill: parent
            color: coreVisual.bgMain
            z: -1
        }
    }

    // ЭКРАН 1: Выбор директории резервного копирования
    Component {
        id: backupPathScreen
        Rectangle {          
            anchors.fill: parent
            color: "transparent"

            FolderDialog {
                id: backupFolderDialog
                title: "Choose a folder for your backup file"
                onAccepted: {
                    var rawPath = selectedFolder.toString()
                    if (Qt.platform.os === "windows") {
                        rawPath = rawPath.replace("file:///", "")
                    } else {
                        rawPath = rawPath.replace("file://", "")
                    }
                    pathField.text = rawPath
                }
            }
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 25
                width: 600 
                
                Text {
                    text: "Шаг 1: Изоляция резервного ключа"
                    color: coreVisual.messageOur
                    font.family: coreTypography.fontFamilyMain
                    font.pixelSize: 24
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Укажите абсолютный путь к директории. Этот путь нельзя будет изменить."
                    color: coreVisual.messageTheir
                    font.family: coreTypography.fontFamilyMain
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0 
                    
                    TextField {
                        id: pathField
                        Layout.fillWidth: true 
                        placeholderText: "/home/user/secure_drive"
                        color: coreVisual.textMain
                        
                        background: Rectangle {
                            color: coreVisual.bgPanel
                            radius: coreVisual.baseRadius
                            Rectangle { width: coreVisual.baseRadius; height: parent.height; anchors.right: parent.right; color: parent.color }
                        }
                    }
                    
                    Button {
                        text: "Обзор ОС"
                        Layout.preferredWidth: 120
                        Layout.fillHeight: true 
                        onClicked: backupFolderDialog.open()
                        
                        contentItem: Text {
                            text: parent.text
                            color: coreVisual.bgMain
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        background: Rectangle {
                            radius: coreVisual.baseRadius
                            Rectangle { width: coreVisual.baseRadius; height: parent.height; anchors.left: parent.left; color: parent.color }
                            color: parent.enabled ? coreVisual.messageOur : coreVisual.messageTheir
                        }
                    }
                }

                Button {
                    text: "Проверить директорию"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    Layout.topMargin: 15
                    enabled: !root.isChecking && pathField.text !== ""
                    
                    onClicked: {
                        root.isChecking = true
                        root.errorMsg = ""
                        settingsManager.verifyBackupPath(pathField.text)
                    }            
                    
                    contentItem: Text {
                        text: parent.text
                        color: coreVisual.bgMain
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: parent.enabled ? coreVisual.messageOur : coreVisual.messageTheir
                        radius: coreVisual.baseRadius
                    }
                }

                // Кнопка мгновенного перехода в окно чатов без регистрации
                Button {
                    text: "Пропустить (Перейти сразу в чаты)"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44

                    onClicked: {
                        windowStack.push(mainChatScreen)
                    }

                    contentItem: Text {
                        text: parent.text
                        color: coreVisual.textMain
                        font.family: coreTypography.fontFamilyMain
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        color: coreVisual.bgPanel
                        radius: coreVisual.baseRadius
                        border.color: coreVisual.messageTheir
                        border.width: 1
                    }
                }
                
                Text {
                    text: root.errorMsg
                    color: "#EF4444"
                    font.family: coreTypography.fontFamilyMain
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.errorMsg !== ""
                }
            }
        }
    }

    // ЭКРАН 2: Анкета регистрации профиля
    Component {
        id: registrationFormScreen
        Rectangle { 
            anchors.fill: parent
            color: "transparent"

            ScrollView {
                id: regScrollView
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                Item {
                    width: regScrollView.availableWidth
                    implicitHeight: formLayout.implicitHeight + 80

                    ColumnLayout {
                        id: formLayout
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(Math.max(root.width * 0.38, 420), 650)
                        spacing: 18

                        Item {
                            implicitHeight: 40 
                        }

                        Text {
                            text: "Введите данные для регистрации"
                            color: coreVisual.messageOur
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 22
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Учетные данные будут зашифрованы локальным мастер-ключом ОС"
                            color: coreVisual.messageTheir
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "Имя пользователя (Username) *"
                            color: coreVisual.messageOur
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 12
                            font.bold: true
                        }
                        
                        TextField {
                            id: usernameField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            placeholderText: "Ваш юзернейм здесь"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 14
                            maximumLength: 31

                            validator: RegularExpressionValidator {
                                regularExpression: /^[a-zA-Z0-9_]{3,31}$/
                            }

                            background: Rectangle {
                                color: coreVisual.bgPanel
                                radius: coreVisual.baseRadius
                                border.color: usernameField.activeFocus ? coreVisual.messageOur : "transparent"
                                border.width: 1
                            }
                        }

                        Text {
                            text: "Мастер-пароль *"
                            color: coreVisual.messageOur
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 12
                            font.bold: true
                            Layout.topMargin: 4
                        }

                        TextField {
                            id: passwordField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            placeholderText: "Минимум 8 символов"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 14
                            echoMode: TextInput.Password
                            passwordCharacter: "•"

                            background: Rectangle {
                                color: coreVisual.bgPanel
                                radius: coreVisual.baseRadius
                                border.color: passwordField.activeFocus ? coreVisual.messageOur : "transparent"
                                border.width: 1
                            }
                        }

                        Text {
                            text: "Подтверждение пароля *"
                            color: coreVisual.messageOur
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 12
                            font.bold: true
                            Layout.topMargin: 4
                        }

                        TextField {
                            id: confirmPasswordField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            placeholderText: "Повторите мастер-пароль"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 14
                            echoMode: TextInput.Password
                            passwordCharacter: "•"

                            background: Rectangle {
                                color: coreVisual.bgPanel
                                radius: coreVisual.baseRadius
                                border.color: {
                                    if (confirmPasswordField.activeFocus) {
                                        return (confirmPasswordField.text === passwordField.text && passwordField.text.length >= 8) 
                                               ? coreVisual.messageOur 
                                               : "#EF4444"
                                    }
                                    return "transparent"
                                }
                                border.width: 1
                            }
                        }

                        Text {
                            text: "Пароли не совпадают или длина меньше 8 символов"
                            color: "#EF4444"
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 11
                            visible: confirmPasswordField.text !== "" && 
                                     (confirmPasswordField.text !== passwordField.text || passwordField.text.length < 8)
                        }

                        Text {
                            text: "Электронная почта (Email) *"
                            color: coreVisual.messageOur
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 12
                            font.bold: true
                            Layout.topMargin: 4
                        }

                        TextField {
                            id: emailField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            placeholderText: "user@domain.org"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 14
                            maximumLength: 63

                            validator: RegularExpressionValidator {
                                regularExpression: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,63}$/
                            }

                            background: Rectangle {
                                color: coreVisual.bgPanel
                                radius: coreVisual.baseRadius
                                border.color: {
                                    if (!emailField.activeFocus) return "transparent"
                                    return emailField.acceptableInput ? coreVisual.messageOur : "#EF4444"
                                }
                                border.width: 1
                            }
                        }

                        Text {
                            text: "Номер телефона (По желанию)"
                            color: coreVisual.messageTheir
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 12
                            font.bold: true
                            Layout.topMargin: 4
                        }

                        TextField {
                            id: phoneField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            placeholderText: "+79001234567 (необязательно)"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 14
                            maximumLength: 19

                            validator: RegularExpressionValidator {
                                regularExpression: /^\+?[0-9]{7,19}$/
                            }

                            background: Rectangle {
                                color: coreVisual.bgPanel
                                radius: coreVisual.baseRadius
                                border.color: {
                                    if (!phoneField.activeFocus || phoneField.text === "") return "transparent"
                                    return phoneField.acceptableInput ? coreVisual.messageOur : "#EF4444"
                                }
                                border.width: 1
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            implicitHeight: nodeCardLayout.implicitHeight + 24
                            color: coreVisual.bgPanel
                            radius: coreVisual.baseRadius
                            border.color: nodeSwitch.checked ? coreVisual.messageOur : "transparent"
                            border.width: 1

                            ColumnLayout {
                                id: nodeCardLayout
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: "Стать опорной Нодой сети (P2P Relay)"
                                        color: coreVisual.textMain
                                        font.family: coreTypography.fontFamilyMain
                                        font.pixelSize: 14
                                        font.bold: true
                                        Layout.fillWidth: true
                                    }

                                    Switch {
                                        id: nodeSwitch
                                        checked: false
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    color: coreVisual.messageTheir
                                    font.family: coreTypography.fontFamilyMain
                                    font.pixelSize: 12
                                    text: "Условия: выделение до 512 МБ диска под зашифрованный транзитный буфер Kademlia DHT и фоновая маршрутизация пакетов (нагрузка на CPU ~0.0% через epoll/IOCP).\n" +
                                          "Польза: ваш узел получает высокий рейтинг в Web of Trust, приоритетный канал передачи файлов и освобождается от вычисления SHA-256 Proof-of-Work (нулевая задержка при отправке сообщений)."
                                }
                            }
                        }

                        Button {
                            id: registerButton
                            text: root.isChecking ? "Генерация ключей и шифрование..." : "Создать профиль"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 52
                            Layout.topMargin: 12

                            enabled: !root.isChecking &&
                                     usernameField.acceptableInput &&
                                     emailField.acceptableInput &&
                                     passwordField.text.length >= 8 &&
                                     passwordField.text === confirmPasswordField.text &&
                                     (phoneField.text === "" || phoneField.acceptableInput)

                            onClicked: {
                                windowStack.push(mainChatScreen)
                            }

                            contentItem: Text {
                                text: parent.text
                                color: coreVisual.bgMain
                                font.family: coreTypography.fontFamilyMain
                                font.pixelSize: 15
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: parent.enabled ? coreVisual.messageOur : coreVisual.messageTheir
                                radius: coreVisual.baseRadius
                            }
                        }
                    }
                }
            }
        }
    }

    // ЭКРАН 3: Рабочее пространство чатов и ИИ-агентов (Хранение в ОЗУ)
    Component {
        id: mainChatScreen

        Rectangle {
            id: chatScreenRoot
            anchors.fill: parent
            color: "transparent"

            // Индекс открытого для общения чата (-1 = не выбран)
            property int currentChatIndex: -1
            // Флаг отображения формы создания/редактирования агента
            property bool isCreatingAgent: true
            // Индекс редактируемого агента (-1 = создание нового, >= 0 = редактирование существующего)
            property int editingChatIndex: -1

            // Оперативная память списка чатов (живет в RAM)
            ListModel {
                id: agentsModel
            }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 32 // Отступ под высоту шапки окна customHeader
                spacing: 1

                // === ЛЕВАЯ КОЛОНКА: СПИСОК ЧАТОВ ===
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: Math.min(Math.max(root.width * 0.26, 260), 380)
                    color: coreVisual.bgPanel

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Верхняя панель с кнопкой "+ ИИ Агент"
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            color: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14

                                Text {
                                    text: "Чаты и ИИ"
                                    color: coreVisual.textMain
                                    font.family: coreTypography.fontFamilyMain
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Button {
                                    text: "+ ИИ Агент"
                                    Layout.preferredHeight: 32
                                    Layout.preferredWidth: 96

                                    onClicked: {
                                        chatScreenRoot.editingChatIndex = -1
                                        newAgentNameField.text = ""
                                        newBaseUrlField.text = "https://api.openai.com/v1"
                                        newApiKeyField.text = ""
                                        newModelField.text = "gpt-4o-mini"
                                        chatScreenRoot.isCreatingAgent = true
                                    }

                                    contentItem: Text {
                                        text: parent.text
                                        color: coreVisual.bgMain
                                        font.family: coreTypography.fontFamilyMain
                                        font.pixelSize: 12
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    background: Rectangle {
                                        color: coreVisual.messageOur
                                        radius: 8
                                    }
                                }
                            }
                        }

                        // Разделительная линия (1px)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: coreVisual.bgMain
                        }

                        // Виртуализированный список чатов в ОЗУ
                        ListView {
                            id: agentsListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: agentsModel

                            delegate: Rectangle {
                                width: agentsListView.width
                                height: 64
                                color: (chatScreenRoot.currentChatIndex === index && !chatScreenRoot.isCreatingAgent)
                                       ? "#1A10B981"
                                       : "transparent"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    Text {
                                        text: "🤖 " + model.agentName
                                        color: coreVisual.textMain
                                        font.family: coreTypography.fontFamilyMain
                                        font.pixelSize: 14
                                        font.bold: true
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: model.modelName + " • " + model.baseUrl
                                        color: coreVisual.messageTheir
                                        font.family: coreTypography.fontFamilyMain
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.LeftButton) {
                                            chatScreenRoot.currentChatIndex = index
                                            chatScreenRoot.editingChatIndex = -1
                                            chatScreenRoot.isCreatingAgent = false
                                        } else if (mouse.button === Qt.RightButton) {
                                            contextMenu.popup()
                                        }
                                    }
                                }

                                // Контекстное меню по нажатию ПКМ
                                Menu {
                                    id: contextMenu

                                    background: Rectangle {
                                        implicitWidth: 160
                                        color: coreVisual.bgMain
                                        radius: 8
                                        border.color: coreVisual.messageTheir
                                        border.width: 1
                                    }

                                    MenuItem {
                                        text: "Редактировать"
                                        contentItem: Text {
                                            text: parent.text
                                            color: coreVisual.textMain
                                            font.family: coreTypography.fontFamilyMain
                                            font.pixelSize: 13
                                        }
                                        background: Rectangle {
                                            color: parent.highlighted ? "#1A10B981" : "transparent"
                                            radius: 6
                                        }
                                        onTriggered: {
                                            chatScreenRoot.editingChatIndex = index
                                            newAgentNameField.text = model.agentName
                                            newBaseUrlField.text = model.baseUrl
                                            newApiKeyField.text = model.apiKey
                                            newModelField.text = model.modelName
                                            chatScreenRoot.isCreatingAgent = true
                                        }
                                    }

                                    MenuItem {
                                        text: "Удалить"
                                        contentItem: Text {
                                            text: parent.text
                                            color: "#FB7185"
                                            font.family: coreTypography.fontFamilyMain
                                            font.pixelSize: 13
                                        }
                                        background: Rectangle {
                                            color: parent.highlighted ? "#26FB7185" : "transparent"
                                            radius: 6
                                        }
                                        onTriggered: {
                                            if (chatScreenRoot.currentChatIndex === index) {
                                                chatScreenRoot.currentChatIndex = -1
                                                chatScreenRoot.isCreatingAgent = true
                                            } else if (chatScreenRoot.currentChatIndex > index) {
                                                chatScreenRoot.currentChatIndex -= 1
                                            }
                                            chatScreenRoot.editingChatIndex = -1
                                            agentsModel.remove(index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // === ПРАВАЯ КОЛОНКА: ФОРМА НАСТРОЙКИ АГЕНТА ИЛИ АКТИВНЫЙ ЧАТ ===
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: coreVisual.bgMain

                    // Блок 1: Форма добавления / редактирования ИИ-агента в ОЗУ
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(Math.max(parent.width * 0.5, 360), 540)
                        spacing: 14
                        visible: chatScreenRoot.isCreatingAgent

                        Text {
                            text: chatScreenRoot.editingChatIndex === -1 
                                  ? "Подключение ИИ-Агента (В ОЗУ)" 
                                  : "Редактирование ИИ-Агента"
                            color: coreVisual.messageOur
                            font.family: coreTypography.fontFamilyMain
                            font.pixelSize: 20
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        TextField {
                            id: newAgentNameField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            placeholderText: "Имя чата (например: MSHP_Assistant)"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            background: Rectangle { color: coreVisual.bgPanel; radius: coreVisual.baseRadius }
                        }

                        TextField {
                            id: newBaseUrlField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            text: "https://api.openai.com/v1"
                            placeholderText: "BASE_URL (например: https://api.openai.com/v1)"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            background: Rectangle { color: coreVisual.bgPanel; radius: coreVisual.baseRadius }
                        }

                        TextField {
                            id: newApiKeyField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            placeholderText: "API_KEY (токен доступа)"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            background: Rectangle { color: coreVisual.bgPanel; radius: coreVisual.baseRadius }
                        }

                        TextField {
                            id: newModelField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            text: "gpt-4o-mini"
                            placeholderText: "MODEL (например: gpt-4o-mini)"
                            placeholderTextColor: coreVisual.messageTheir
                            color: coreVisual.textMain
                            background: Rectangle { color: coreVisual.bgPanel; radius: coreVisual.baseRadius }
                        }

                        Button {
                            text: chatScreenRoot.editingChatIndex === -1 
                                  ? "Добавить агента в список" 
                                  : "Сохранить изменения"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            enabled: newAgentNameField.text !== "" && newBaseUrlField.text !== "" && newModelField.text !== ""

                            onClicked: {
                                var agentData = {
                                    "agentName": newAgentNameField.text,
                                    "baseUrl": newBaseUrlField.text,
                                    "apiKey": newApiKeyField.text,
                                    "modelName": newModelField.text
                                }

                                if (chatScreenRoot.editingChatIndex === -1) {
                                    agentsModel.append(agentData)
                                    chatScreenRoot.currentChatIndex = agentsModel.count - 1
                                } else {
                                    agentsModel.set(chatScreenRoot.editingChatIndex, agentData)
                                    chatScreenRoot.currentChatIndex = chatScreenRoot.editingChatIndex
                                }

                                chatScreenRoot.editingChatIndex = -1
                                chatScreenRoot.isCreatingAgent = false
                            }

                            contentItem: Text {
                                text: parent.text
                                color: coreVisual.bgMain
                                font.family: coreTypography.fontFamilyMain
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: parent.enabled ? coreVisual.messageOur : coreVisual.messageTheir
                                radius: coreVisual.baseRadius
                            }
                        }
                    }

                    /// Блок 2: Рабочая зона открытого чата
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12
                        visible: !chatScreenRoot.isCreatingAgent && chatScreenRoot.currentChatIndex >= 0

                        // Шапка открытого чата
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: chatScreenRoot.currentChatIndex >= 0 && agentsModel.count > chatScreenRoot.currentChatIndex
                                      ? "🤖 " + agentsModel.get(chatScreenRoot.currentChatIndex).agentName + 
                                        " [" + agentsModel.get(chatScreenRoot.currentChatIndex).modelName + "]"
                                      : ""
                                color: coreVisual.messageOur
                                font.family: coreTypography.fontFamilyMain
                                font.pixelSize: 16
                                font.bold: true
                                Layout.fillWidth: true
                            }
                        }

                        // Поле вывода истории переписки
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: chatHistoryArea
                                readOnly: true
                                wrapMode: TextArea.Wrap
                                color: coreVisual.textMain
                                font.family: coreTypography.fontFamilyMain
                                font.pixelSize: 14
                                text: chatScreenRoot.currentChatIndex >= 0 && agentsModel.count > chatScreenRoot.currentChatIndex
                                      ? (agentsModel.get(chatScreenRoot.currentChatIndex).chatHistory || "")
                                      : ""
                                background: Rectangle {
                                    color: coreVisual.bgPanel
                                    radius: coreVisual.baseRadius
                                }
                            }
                        }

                        // Нижняя панель: Поле ввода текста + Кнопка отправки
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            TextField {
                                id: messageInputField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                placeholderText: root.isChecking ? "Ожидание ответа нейросети..." : "Введите запрос агенту..."
                                placeholderTextColor: coreVisual.messageTheir
                                color: coreVisual.textMain
                                font.family: coreTypography.fontFamilyMain
                                font.pixelSize: 14
                                enabled: !root.isChecking

                                onAccepted: sendMessageBtn.clicked()

                                background: Rectangle {
                                    color: coreVisual.bgPanel
                                    radius: coreVisual.baseRadius
                                    border.color: messageInputField.activeFocus ? coreVisual.messageOur : "transparent"
                                    border.width: 1
                                }
                            }

                            Button {
                                id: sendMessageBtn
                                text: root.isChecking ? "..." : "Отправить"
                                Layout.preferredWidth: 120
                                Layout.preferredHeight: 46
                                enabled: !root.isChecking && messageInputField.text.trim() !== ""

                                onClicked: {
                                    var idx = chatScreenRoot.currentChatIndex
                                    var agent = agentsModel.get(idx)
                                    var userText = messageInputField.text.trim()
                                    messageInputField.text = ""

                                    // Дописываем вопрос пользователя в ОЗУ чата
                                    var currentLog = agent.chatHistory || ""
                                    agentsModel.setProperty(idx, "chatHistory", currentLog + "Вы: " + userText + "\n\n")

                                    root.isChecking = true
                                    settingsManager.sendMessageToAi(
                                        agent.baseUrl,
                                        agent.apiKey,
                                        agent.modelName,
                                        userText
                                    )
                                }

                                contentItem: Text {
                                    text: parent.text
                                    color: coreVisual.bgMain
                                    font.family: coreTypography.fontFamilyMain
                                    font.pixelSize: 14
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                background: Rectangle {
                                    color: parent.enabled ? coreVisual.messageOur : coreVisual.messageTheir
                                    radius: coreVisual.baseRadius
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: settingsManager 
        function onAuthStateResolved(username, profilePath, validProfiles, corruptedProfiles, hasPin, isNode){
            if(hasPin){
                //if user hasPin
            } else {
                //if user doesnt have pin
            }
        }
        
        function onFallbackRequested(){
            windowStack.push(backupPathScreen) 
        }
        
        function onRecoveryRequested(corruptedProfiles){
            //recovery requested
        }

        function onBackupPathValid(){
            root.isChecking = false
            windowStack.push(registrationFormScreen)
        }

        function onBackupPathInvalid(reason){
            root.isChecking = false
            root.errorMsg = reason 
        }
        
        function onAiResponseReceived(answerText) {
            root.isChecking = false
            // Находим активный экран и дописываем ответ ИИ в буфер чата
            if (windowStack.currentItem && windowStack.currentItem.currentChatIndex !== undefined) {
                var item = windowStack.currentItem
                var idx = item.currentChatIndex
                if (idx >= 0) {
                    var oldText = chatHistoryArea.text
                    chatHistoryArea.text = oldText + "Агент: " + answerText + "\n────────────────────\n"
                }
            }
        }
    }
}
