import QtQuick          2.11
import QtQuick.Layouts  1.0
import QtQuick.Controls 2.4
import QtWebEngine      1.1
import QtWebChannel     1.0
import Beam.Wallet      1.0
import "controls"

ColumnLayout {
    id: control
    Layout.fillWidth: true

    property var     appsList: undefined
    property bool    hasApps:  !!appsList && appsList.length > 0
    property string  errorMessage: ""
    property var     activeApp: undefined

    ApplicationsViewModel {
        id: viewModel
    }

    //
    // Page Header (Title + Status Bar)
    //
    Title {
        //% "Applications"
        text: qsTrId("apps-title")
    }

    StatusBar {
        id: statusBar
        model: statusbarModel
    }

    //
    // C++ object published to web control & web control itself
    //
    WebAPIBeam {
        id: webapiBEAM
        WebChannel.id: "BEAM"
        property var style: Style
    }

    WebChannel {
        id: apiChannel
        registeredObjects: [webapiBEAM]
    }

    WebEngineView {
        id: webView

        Layout.fillWidth:    true
        Layout.fillHeight:   true
        Layout.bottomMargin: 10
        Layout.topMargin:    34

        webChannel: apiChannel
        visible: false

        // TODO:check why cache doesn't respect headers and always load cached page
        profile.httpCacheType: WebEngineProfile.NoCache

        onLoadingChanged: {
            if (control.activeApp && !this.loading) {
                this.visible = true
            }
        }
    }

    function launchApp(app) {
        control.activeApp = app
        webView.url = app.url
       // webView.visible = true
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth:  true
        visible: !webView.visible && !appsView.visible

        SFText {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - this.height / 2 - 40
            color: control.errorMessage.length ? Style.validator_error : Style.content_main

            font {
                pixelSize: 20
            }

            text: {
                if (control.activeApp) {
                    //% "Loading '%1'..."
                    return qsTrId("apps-loading-app").arg(control.activeApp.name)
                }

                if (control.errorMessage.length) {
                    return control.errorMessage
                }

                if (control.appsList && control.appsList.length == 0) {
                    //% "There are no applications at the moment"
                    return qsTrId("apps-nothing")
                }

                //% "Loading..."
                return qsTrId("apps-loading")
            }
        }
    }

    // Actuall apps list
    ScrollView {
        id: appsView
        Layout.topMargin:  50
        Layout.fillHeight: true
        Layout.fillWidth:  true
        Layout.bottomMargin: 10
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        clip: true
        visible: control.hasApps && !control.activeApp

        ColumnLayout
        {
            width: parent.width
            spacing: 15

            Repeater {
                model: control.appsList
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100

                    Rectangle {
                        anchors.fill: parent
                        radius:       10
                        color:        Style.active
                        opacity:      hoverArea.containsMouse ? 0.15 : 0.1
                    }

                    RowLayout {
                        anchors.fill: parent

                        Rectangle {
                            Layout.leftMargin: 30
                            width:  60
                            height: 60
                            radius: 30
                            color:  Style.background_main

                            SvgImage {
                                source: "qrc:/assets/icon-applications-active.svg"
                                sourceSize: Qt.size(28, 28)
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Column {
                            Layout.leftMargin: 20
                            spacing: 10

                            SFText {
                                text: modelData.name
                                font {
                                    styleName:  "Bold"
                                    weight:     Font.Bold
                                    pixelSize:  18
                                }
                                color: Style.content_main
                            }
                            SFText {
                                text: modelData.description
                                font {
                                    pixelSize:  14
                                }
                                color: Style.content_main
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        CustomButton {
                            Layout.rightMargin: 20
                            height: 40
                            palette.button: Style.background_second
                            palette.buttonText : Style.content_main
                            icon.source: "qrc:/assets/icon-run.svg"
                            icon.height: 16
                            //% "launch"
                            text: qsTrId("apps-run")

                            MouseArea {
                                anchors.fill:     parent
                                acceptedButtons:  Qt.LeftButton
                                hoverEnabled:     true
                                propagateComposedEvents: true
                                preventStealing:  true
                                onClicked:        launchApp(modelData)
                            }
                        }
                    }

                    MouseArea {
                        id:               hoverArea
                        anchors.fill:     parent
                       // acceptedButtons:  Qt.LeftButton
                        hoverEnabled:     true
                        propagateComposedEvents: true
                        preventStealing: true
                    }
                }
            }
        }
    }

    function appendDevApp (arr) {
        if (viewModel.devAppName) {
            arr = arr || []
            arr.unshift({
                "name": viewModel.devAppName,
                //% "This is your dev application"
                "description": qsTrId("apps-devapp"),
                "url": viewModel.devAppURL
            })
            return arr
        }
        return arr
    }

    Component.onCompleted: {
        viewModel.onCompleted(webView)

        if (Style.appsUrl.length) {
            var xhr = new XMLHttpRequest();
            xhr.onreadystatechange = function()
            {
                //% "Failed to load applications list, %1"
                var errTemplate = qsTrId("apps-load-error")

                if(xhr.readyState === XMLHttpRequest.DONE)
                {
                    if (xhr.status === 200)
                    {
                        var list = JSON.parse(xhr.responseText)
                        control.appsList = appendDevApp(list)
                    }
                    else
                    {
                        var errMsg = errTemplate.arg(["code", xhr.status].join(" "))
                        control.errorMessage = errMsg
                    }
                }
            }
            xhr.open('GET', Style.appsUrl, true)
            xhr.send('')
        }

        control.appsList = appendDevApp(undefined)
    }
}
