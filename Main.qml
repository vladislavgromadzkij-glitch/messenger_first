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

    //custom frameless window header
    Rectangle {
        id: customHeader
        width: parent.width
        height: 32 
        color: "transparent" 
        z: 10

        //handles window drag events
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

    StackView { //this object navigates between pages
        id: windowStack 
        anchors.fill: parent 

        Rectangle { //basic background
            anchors.fill: parent
            color: coreVisual.bgMain
            z: -1 //we make it always behind other elements
        }
    }

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
                    if(Qt.platform.os === "windows"){
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
                    enabled: !isChecking && pathField.text !== ""
                    
                    onClicked: {
                        root.isChecking = true // ui block
                        root.errorMsg = ""     //delete old errors
                        settingsManager.verifyBackupPath(pathField.text) //send info to settings manager
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

    Component {
        id: registrationFormScreen
        Rectangle { 
            anchors.fill: parent
            color: "transparent"
            Text {
                anchors.centerIn: parent
                text: "SUCCESSFUL: Переход к анкете"
                color: coreVisual.messageOur
                font.family: coreTypography.fontFamilyMain
                font.pixelSize: 32
                font.bold: true
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
    }
}