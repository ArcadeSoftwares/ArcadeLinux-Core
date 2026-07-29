import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root

    property alias cfg_aiProvider: providerCombo.currentValue
    property alias cfg_aiApiKey: apiKeyField.text
    property alias cfg_aiGroqModel: groqModelField.text
    property alias cfg_aiOpenaiModel: openaiModelField.text
    property alias cfg_aiGeminiModel: geminiModelField.text
    property alias cfg_aiOpenrouterModel: openrouterModelField.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        ComboBox {
            id: providerCombo
            Kirigami.FormData.label: "AI Provider:"
            Layout.fillWidth: true
            textRole: "label"
            valueRole: "id"
            model: ListModel {
                ListElement { id: "groq";        label: "Groq  —  Free & blazing fast (Llama)" }
                ListElement { id: "openai";      label: "OpenAI  (GPT-4o, GPT-4o-mini…)" }
                ListElement { id: "gemini";      label: "Google Gemini" }
                ListElement { id: "openrouter";  label: "OpenRouter  (100+ models)" }
            }
        }

        // API Key field — use TextField directly so Kirigami.FormData.label works reliably
        TextField {
            id: apiKeyField
            Kirigami.FormData.label: "API Key:"
            Layout.fillWidth: true
            placeholderText: "Paste your API key here…"
            echoMode: TextInput.Password
            rightPadding: showBtn.width + 4

            // Inline show/hide button overlaid on the right side of the field
            Button {
                id: showBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 2
                width: implicitHeight
                checkable: true
                icon.name: checked ? "view-hidden" : "view-visible"
                flat: true
                ToolTip.text: checked ? "Hide" : "Show"
                ToolTip.visible: hovered
                onCheckedChanged: {
                    apiKeyField.echoMode = checked ? TextInput.Normal : TextInput.Password
                }
            }
        }

        TextField {
            id: groqModelField
            Kirigami.FormData.label: "Groq Model:"
            Layout.fillWidth: true
            visible: providerCombo.currentIndex === 0
            placeholderText: "llama-3.3-70b-versatile"
        }

        TextField {
            id: openaiModelField
            Kirigami.FormData.label: "OpenAI Model:"
            Layout.fillWidth: true
            visible: providerCombo.currentIndex === 1
            placeholderText: "gpt-4o-mini"
        }

        TextField {
            id: geminiModelField
            Kirigami.FormData.label: "Gemini Model:"
            Layout.fillWidth: true
            visible: providerCombo.currentIndex === 2
            placeholderText: "gemini-2.0-flash"
        }

        TextField {
            id: openrouterModelField
            Kirigami.FormData.label: "OpenRouter Model:"
            Layout.fillWidth: true
            visible: providerCombo.currentIndex === 3
            placeholderText: "openai/gpt-4o-mini"
        }

        Label {
            Layout.fillWidth: true
            opacity: 0.6
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            text: {
                var idx = providerCombo.currentIndex;
                if (idx === 0) return "🔗 Get free API key at: console.groq.com";
                if (idx === 1) return "🔗 Get API key at: platform.openai.com";
                if (idx === 2) return "🔗 Get API key at: aistudio.google.com";
                if (idx === 3) return "🔗 Get API key at: openrouter.ai";
                return "";
            }
        }
    }
}
