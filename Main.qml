import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import first

Window {
    id: rootWindow
    width: 1600
    height: 900
    visible: true
    title: "first"
    property real uiScale: ((width / 800) + (height / 450)) / 2
    color: "transparent"    
    flags: Qt.Window | Qt.FramelessWindowHint

    FontLoader { id: fontPTSans; source: "fonts/PTSans-Regular.ttf" }
    FontLoader { id: fontRoboto; source: "fonts/Roboto-Regular.ttf" }
    FontLoader { id: fontCyber; source: "fonts/JetBrainsMono-Regular.ttf" }

    Rectangle {
        id: mainBackground
        anchors.fill: parent 
        color: settingsManager.customization.currentBgMain
        radius: 7
        clip: true 

      states: [
        State {
            name: "telegram_dark"
            PropertyChanges {
                target: rootWindow
                currentBgMain: "#182533"
                currentBgElement: "#243141"
                currentBgElementHover: "#2b394a"
                currentBgElementActive: "#202b39"
                currentBorderColor: "#5288c1"
                currentAccentColor: "#64b5f6"
                currentTextColorMain: "#ffffff"
                currentTextColorSecond: "#7da4c4"
                currentFontFamily: "Inter"
            }
        },
        State {
            name: "telegram_light"
            PropertyChanges {
                target: rootWindow
                currentBgMain: "#ffffff"
                currentBgElement: "#f1f5f9"
                currentBgElementHover: "#e2e8f0"
                currentBgElementActive: "#cbd5e1"
                currentBorderColor: "#3390ec"
                currentAccentColor: "#3390ec"
                currentTextColorMain: "#000000"
                currentTextColorSecond: "#707579"
                currentFontFamily: "Inter"
            }
        },
        State {
            name: "discord_dark"
            PropertyChanges {
                target: rootWindow
                currentBgMain: "#313338"
                currentBgElement: "#2b2d31"
                currentBgElementHover: "#35373c"
                currentBgElementActive: "#1e1f22"
                currentBorderColor: "#5865f2"
                currentAccentColor: "#5865f2"
                currentTextColorMain: "#f2f3f5"
                currentTextColorSecond: "#949ba4"
                currentFontFamily: "Roboto"
            }
        },
        State {
            name: "whatsapp_dark"
            PropertyChanges {
                target: rootWindow
                currentBgMain: "#0b141a"
                currentBgElement: "#111b21"
                currentBgElementHover: "#202c33"
                currentBgElementActive: "#101a20"
                currentBorderColor: "#00a884"
                currentAccentColor: "#00a884"
                currentTextColorMain: "#e9edef"
                currentTextColorSecond: "#8696a0"
                currentFontFamily: "Roboto"
            }
        },
        State {
            name: "mint_pastel"
            PropertyChanges {
                target: rootWindow
                currentBgMain: "#e8f5e9"
                currentBgElement: "#ffffff"
                currentBgElementHover: "#f5f5f5"
                currentBgElementActive: "#e0e0e0"
                currentBorderColor: "#a5d6a7"
                currentAccentColor: "#2e7d32"
                currentTextColorMain: "#1b5e20"
                currentTextColorSecond: "#4caf50"
                currentFontFamily: "Inter"
            }
        },
        State {
            name: "cyberpunk"
            PropertyChanges {
                target: rootWindow
                currentBgMain: "#0f0f1a"
                currentBgElement: "#1a1a2e"
                currentBgElementHover: "#ff007f"
                currentBgElementActive: "#9d00ff"
                currentBorderColor: "#00f0ff"
                currentAccentColor: "#00f0ff"
                currentTextColorMain: "#00f0ff"
                currentTextColorSecond: "#ffe600"
                currentFontFamily: "JetBrains Mono"
            }
        },

        State {
            name: "size_small" // Маленький, но читаемый компактный режим
            PropertyChanges {
                target: rootWindow
                currentFontSizeBase: 11
                currentFontSizeTitle: 15
            }
        },
        State {
            name: "size_medium" // Стандартный средний размер (базовый)
            PropertyChanges {
                target: rootWindow
                currentFontSizeBase: 14
                currentFontSizeTitle: 20
            }
        },
        State {
            name: "size_large" // Режим для слабовидящих
            PropertyChanges {
                target: rootWindow
                currentFontSizeBase: 24
                currentFontSizeTitle: 34
                currentFontBold: true // Включаем принудительную жирность
            }
        }
    ]
    StackView {
            id: stackView
            anchors.fill: parent
        }
    }
    Rectangle {
    id: titleBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 20
    color: settingsManager.customization.currentBgElement
    radius: 7
    clip: true
    MouseArea {
        anchors.fill: parent
        onPressed: rootWindow.startSystemMove()
    }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 0
        Rectangle {
            id: sizeWin
            width: 40
            height: parent.height
            color: minMouse.containsMouse ? "#F5B041" : "transparent"
            MouseArea {
                id: minMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: rootWindow.showMinimized()
            }
            Rectangle {
                width: 10
                height: 1.5
                color: "white"
                anchors.centerIn: parent
            }
        }
        Rectangle {
            width: 40
            height: parent.height
            color: maxMouse.containsMouse ? "#48C9B0" : "transparent"
            MouseArea {
                id: maxMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (rootWindow.visibility === Window.Maximized) {
                        rootWindow.showNormal()
                    } else {
                        rootWindow.showMaximized()
                    }
                }
            }
            Rectangle {
                width: 8
                height: 8
                color: "transparent"
                border.width: 1.5
                border.color: "white"
                anchors.centerIn: parent
                visible: rootWindow.visibility !== Window.FullScreen
            }
            Item {
                width: 10
                height: 10
                anchors.centerIn: parent
                visible: rootWindow.visibility === Window.FullScreen
                Rectangle {
                    x: 2
                    y: 0
                    width: 6
                    height: 6
                    color: "transparent"
                    border.width: 1.2
                    border.color: "white"
                }
                Rectangle {
                    x: 0
                    y: 2
                    width: 6
                    height: 6
                    color: "transparent"
                    border.width: 1.2
                    border.color: "white"
                }
            }
        }
        Rectangle {
            id: closeWin
            width: 40
            height: parent.height
            color: closeMouse.containsMouse ? "#CD6155" : "transparent"
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: rootWindow.close()
            }
            Item {
                width: 10
                height: 10
                anchors.centerIn: parent
                Rectangle {
                    width: 11
                    height: 1.5
                    color: "white"
                    rotation: 45
                    anchors.centerIn: parent
                }
                Rectangle {
                    width: 11
                    height: 1.5
                    color: "white"
                    rotation: -45
                    anchors.centerIn: parent
                }
            }
        }
    }
}
}
    