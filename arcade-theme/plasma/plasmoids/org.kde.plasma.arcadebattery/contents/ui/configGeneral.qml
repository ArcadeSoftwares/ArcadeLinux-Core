import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root
    
    property alias cfg_textColor: textColorField.text
    property alias cfg_chargingTextColor: chargingTextColorField.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        TextField {
            id: textColorField
            Kirigami.FormData.label: "Standard Text Color:"
            placeholderText: "#000000"
        }

        TextField {
            id: chargingTextColorField
            Kirigami.FormData.label: "Charging Text Color:"
            placeholderText: "#000000"
        }
    }
}
