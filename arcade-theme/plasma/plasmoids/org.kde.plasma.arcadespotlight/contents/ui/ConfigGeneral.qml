import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configRoot

    property alias cfg_aiProvider: providerCombo.currentValue
    property alias cfg_aiApiKey: apiKeyField.text
    property alias cfg_aiGroqModel: groqModelField.text
    property alias cfg_aiOpenaiModel: openaiModelField.text
    property alias cfg_aiGeminiModel: geminiModelField.text
    property alias cfg_aiOpenrouterModel: openrouterModelField.text

    Kirigami.FormLayout {
        id: formLayout
        anchors.fill: parent

        ComboBox {
            id: providerCombo
            Kirigami.FormData.label: "Provider:"
            Layout.fillWidth: true
            textRole: "label"
            valueRole: "id"
            model: ListModel {
                ListElement { id: "groq";        label: "Groq  —  Free & blazing fast (Llama)" }
                ListElement { id: "openai";      label: "OpenAI  (GPT-4o, GPT-4o-mini…)" }
                ListElement { id: "gemini";      label: "Google Gemini" }
                ListElement { id: "openrouter";  label: "OpenRouter  (100+ models)" }
            }
            Component.onCompleted: {
                for (var i = 0; i < model.count; i++) {
                    if (model.get(i).id === plasmoid.configuration.aiProvider) { currentIndex = i; break; }
                }
            }
            onActivated: cfg_aiProvider = currentValue
        }

        RowLayout {
            Kirigami.FormData.label: "API Key:"
            Layout.fillWidth: true
            spacing: 6
            TextField {
                id: apiKeyField
                Layout.fillWidth: true
                text: plasmoid.configuration.aiApiKey
                placeholderText: "Paste your API key here…"
                echoMode: showBtn.checked ? TextInput.Normal : TextInput.Password
            }
            Button {
                id: showBtn
                checkable: true
                icon.name: checked ? "view-hidden" : "view-visible"
                flat: true
                ToolTip.text: checked ? "Hide" : "Show"
                ToolTip.visible: hovered
            }
        }

        Item {
            Kirigami.FormData.label: "Model:"
            Layout.fillWidth: true
            implicitHeight: groqModelField.implicitHeight

            TextField {
                id: groqModelField
                anchors.fill: parent
                visible: providerCombo.currentValue === "groq"
                text: plasmoid.configuration.aiGroqModel
                placeholderText: "llama-3.3-70b-versatile"
            }
            TextField {
                id: openaiModelField
                anchors.fill: parent
                visible: providerCombo.currentValue === "openai"
                text: plasmoid.configuration.aiOpenaiModel
                placeholderText: "gpt-4o-mini"
            }
            TextField {
                id: geminiModelField
                anchors.fill: parent
                visible: providerCombo.currentValue === "gemini"
                text: plasmoid.configuration.aiGeminiModel
                placeholderText: "gemini-2.0-flash"
            }
            TextField {
                id: openrouterModelField
                anchors.fill: parent
                visible: providerCombo.currentValue === "openrouter"
                text: plasmoid.configuration.aiOpenrouterModel
                placeholderText: "openai/gpt-4o-mini"
            }
        }

        Label {
            Layout.fillWidth: true
            opacity: 0.6
            font.pixelSize: 11
            text: {
                var p = providerCombo.currentValue;
                if (p === "groq")       return "🔗 Get free API key at: console.groq.com";
                if (p === "openai")     return "🔗 Get API key at: platform.openai.com";
                if (p === "gemini")     return "🔗 Get API key at: aistudio.google.com";
                if (p === "openrouter") return "🔗 Get API key at: openrouter.ai";
                return "";
            }
        }
    }
}
