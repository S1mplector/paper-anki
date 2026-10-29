import QtQuick
import "file:///home/root/anki-desktop/qml/PaperAnki" as Bridge

Rectangle {
    id: root
    signal close()
    function unloading() { desktop.closeDesktop(); }
    Component.onCompleted: desktop.startDesktop()
    color: "white"
    property bool keyboard: false
    property bool caps: false
    Bridge.Desktop {
        id: desktop
        anchors.top: parent.top
        width: parent.width
        height: parent.height - toolbar.height
    }
    Rectangle {
        anchors.fill: desktop
        visible: desktop.status.length > 0
        color: "white"
        Text { anchors.centerIn: parent; text: desktop.status; font.pixelSize: 28; width: parent.width-80; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter }
    }
    Rectangle {
        anchors.bottom: toolbar.top
        width: parent.width
        height: keyboard ? 320 : 0
        visible: keyboard
        color: "white"
        border.color: "black"
        Column {
            anchors.fill: parent
            Repeater {
                model: ["qwertyuiop", "asdfghjkl", "zxcvbnm", "1234567890"]
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    height: 64
                    Repeater {
                        model: modelData.split("")
                        Rectangle {
                            width: root.width/11; height: 60; radius: 8; color: "#f1f1f1"
                            Text { anchors.centerIn: parent; text: caps ? modelData.toUpperCase() : modelData; font.pixelSize: 28 }
                            MouseArea { anchors.fill: parent; onClicked: desktop.text(caps ? modelData.toUpperCase() : modelData) }
                        }
                    }
                }
            }
            Row {
                spacing: 4
                Repeater {
                    model: ["Shift", "@", ".", "-", "Space", "Delete", "Enter"]
                    Rectangle {
                        width: (root.width-24)/7; height: 60; radius: 8; color: "#f1f1f1"
                        Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 25 }
                        MouseArea { anchors.fill: parent; onClicked: {
                            if(modelData==="Shift") caps=!caps;
                            else if(modelData==="Space") desktop.key(32);
                            else if(modelData==="Delete") desktop.key(0xff08);
                            else if(modelData==="Enter") desktop.key(0xff0d);
                            else desktop.text(modelData);
                        } }
                    }
                }
            }
        }
    }
    Rectangle {
        id: toolbar
        anchors.bottom: parent.bottom
        width: parent.width
        height: 96
        color: "white"
        Row {
            anchors.centerIn: parent
            spacing: 14
            Repeater {
                model: [
                    {icon:"exit", label:"Return to notes"},
                    {icon:"keyboard", label:"Show or hide keyboard"},
                    {icon:"up", label:"Scroll up"},
                    {icon:"down", label:"Scroll down"},
                    {icon:"reveal", label:"Reveal answer or study"},
                    {icon:"refresh", label:"Refresh or reopen Anki"}
                ]
                Rectangle {
                    width: 80; height: 68; radius: 20
                    color: utilityMouse.pressed || (modelData.icon==="keyboard" && keyboard) ? "#dedede" : "#f5f5f5"
                    property string accessibleLabel: modelData.label
                    Image {
                        anchors.centerIn: parent
                        width: 34; height: 34
                        source: "icons/" + modelData.icon + ".svg"
                        sourceSize.width: 68; sourceSize.height: 68
                        fillMode: Image.PreserveAspectFit
                    }
                    MouseArea {
                        id: utilityMouse
                        anchors.fill: parent
                        onClicked: {
                            if(modelData.icon==="exit") { desktop.closeDesktop(); root.close(); }
                            else if(modelData.icon==="keyboard") keyboard=!keyboard;
                            else if(modelData.icon==="refresh") desktop.refresh();
                            else if(modelData.icon==="up") desktop.scroll(1);
                            else if(modelData.icon==="down") desktop.scroll(-1);
                            else desktop.key(32);
                        }
                    }
                }
            }
        }
    }
}
