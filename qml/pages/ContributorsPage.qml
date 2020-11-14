import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + 2*Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Contributors") }

            SectionHeader { text: qsTr("Development") }

            DetailList {
                label: qsTr("Programming")
                values: ["Mirian Margiani", "karip", "Joona Petrell",
                    "Michael Faro-Tusino", "Alin Marin Elena", "jklingen",
                    "Benna", "Malte Veerman", "Marcin Mielniczuk"
                ]
            }

            DetailList {
                label: qsTr("Icon Design")
                values: ["Sailfish (Jolla)", "karip", "Mirian Margiani"]
            }

            SectionHeader { text: qsTr("Translations") }

            DetailList {
                label: qsTr("English")
                values: ["karip", "Mirian Margiani"]
            }
            DetailList {
                label: qsTr("German")
                values: ["jklingen", "karip", "Mirian Margiani"]
            }
            DetailList {
                label: qsTr("Finnish")
                values: ["karip", "Tathhu"]
            }
            DetailList {
                label: qsTr("Chinese")
                values: ["Tyler Temp", "dashinfantry"]
            }
            DetailList {
                label: qsTr("Russian")
                values: ["Petr Tsymbarovich"]
            }
            DetailList {
                label: qsTr("Swedish")
                values: ["Åke Engelbrektson"]
            }
            DetailList {
                label: qsTr("Italian")
                values: ["Tichy"]
            }
            DetailList {
                label: qsTr("Spanish")
                values: ["Carmen F. B."]
            }
            DetailList {
                label: qsTr("French")
                values: ["Quent-in (Quentí)", "karip"]
            }
            DetailList {
                label: qsTr("Dutch")
                values: ["Nathan Follens"]
            }
            DetailList {
                label: qsTr("Greek")
                values: ["Dimitrios Glentadakis"]
            }
        }
    }
}
