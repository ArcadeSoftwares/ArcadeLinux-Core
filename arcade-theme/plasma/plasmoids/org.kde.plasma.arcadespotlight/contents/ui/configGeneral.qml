import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: configRoot

    property string cfg_aiProvider: plasmoid.configuration.aiProvider
    property string cfg_aiApiKey: plasmoid.configuration.aiApiKey
    property string cfg_aiGroqModel: plasmoid.configuration.aiGroqModel
    property string cfg_aiOpenaiModel: plasmoid.configuration.aiOpenaiModel
    property string cfg_aiGeminiModel: plasmoid.configuration.aiGeminiModel
    property string cfg_aiOpenrouterModel: plasmoid.configuration.aiOpenrouterModel

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

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
                    if (model.get(i).id === configRoot.cfg_aiProvider) { currentIndex = i; break; }
                }
            }
            onActivated: configRoot.cfg_aiProvider = currentValue
        }

        RowLayout {
            Kirigami.FormData.label: "API Key:"
            Layout.fillWidth: true
            spacing: 6
            TextField {
                id: apiKeyField
                Layout.fillWidth: true
                text: configRoot.cfg_aiApiKey
                onTextChanged: configRoot.cfg_aiApiKey = text
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
                text: configRoot.cfg_aiGroqModel
                onTextChanged: configRoot.cfg_aiGroqModel = text
                placeholderText: "llama-3.3-70b-versatile"
            }
            TextField {
                id: openaiModelField
                anchors.fill: parent
                visible: providerCombo.currentValue === "openai"
                text: configRoot.cfg_aiOpenaiModel
                onTextChanged: configRoot.cfg_aiOpenaiModel = text
                placeholderText: "gpt-4o-mini"
            }
            TextField {
                id: geminiModelField
                anchors.fill: parent
                visible: providerCombo.currentValue === "gemini"
                text: configRoot.cfg_aiGeminiModel
                onTextChanged: configRoot.cfg_aiGeminiModel = text
                placeholderText: "gemini-2.0-flash"
            }
            TextField {
                id: openrouterModelField
                anchors.fill: parent
                visible: providerCombo.currentValue === "openrouter"
                text: configRoot.cfg_aiOpenrouterModel
                onTextChanged: configRoot.cfg_aiOpenrouterModel = text
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
