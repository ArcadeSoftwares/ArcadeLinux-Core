import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import Qt.labs.settings 1.0

Kirigami.ScrollablePage {
    id: configPage

    Settings {
        id: aiSettings
        category: "ArcadeSpotlightAI"
        property string provider: "groq"
        property string apiKey: ""
        property string model: "gpt-4o-mini"
        property string geminiModel: "gemini-2.0-flash"
        property string openrouterModel: "openai/gpt-4o-mini"
        property string groqModel: "llama-3.3-70b-versatile"
    }

    Kirigami.FormLayout {
        id: formLayout

        Item { Kirigami.FormData.isSection: true }

        Kirigami.Heading {
            text: "🤖 AI Assistant"
            level: 2
            Kirigami.FormData.label: ""
        }

        Label {
            text: "Type /ai <question> in Spotlight then press Enter to get an AI-powered answer inline."
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 480
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        // ---- Provider ----
        ComboBox {
            id: providerCombo
            Kirigami.FormData.label: "AI Provider"
            model: ["Groq (Free & Fast)", "OpenAI (GPT)", "Google Gemini", "OpenRouter"]

            property var providerIds: ["groq", "openai", "gemini", "openrouter"]

            currentIndex: {
                var idx = providerIds.indexOf(aiSettings.provider);
                return idx >= 0 ? idx : 0;
            }

            onCurrentIndexChanged: {
                aiSettings.provider = providerIds[currentIndex];
            }
        }

        // ---- API Key ----
        TextField {
            id: apiKeyField
            Kirigami.FormData.label: "API Key"
            placeholderText: "Paste your API key here…"
            echoMode: TextInput.PasswordEchoOnEdit
            text: aiSettings.apiKey
            Layout.minimumWidth: 360
            onEditingFinished: aiSettings.apiKey = text
        }

        // ---- Groq Model ----
        TextField {
            id: groqModelField
            Kirigami.FormData.label: "Groq Model"
            visible: providerCombo.currentIndex === 0
            text: aiSettings.groqModel
            Layout.minimumWidth: 260
            onEditingFinished: aiSettings.groqModel = text
        }

        // ---- OpenAI Model ----
        TextField {
            id: openaiModelField
            Kirigami.FormData.label: "OpenAI Model"
            visible: providerCombo.currentIndex === 1
            text: aiSettings.model
            Layout.minimumWidth: 260
            onEditingFinished: aiSettings.model = text
        }

        // ---- Gemini Model ----
        TextField {
            id: geminiModelField
            Kirigami.FormData.label: "Gemini Model"
            visible: providerCombo.currentIndex === 2
            text: aiSettings.geminiModel
            Layout.minimumWidth: 260
            onEditingFinished: aiSettings.geminiModel = text
        }

        // ---- OpenRouter Model ----
        TextField {
            id: openrouterModelField
            Kirigami.FormData.label: "OpenRouter Model"
            visible: providerCombo.currentIndex === 3
            text: aiSettings.openrouterModel
            Layout.minimumWidth: 260
            onEditingFinished: aiSettings.openrouterModel = text
        }

        // ---- API key hints ----
        Label {
            visible: providerCombo.currentIndex === 0
            text: "Get a free key at: console.groq.com  •  Suggested models: llama-3.3-70b-versatile, mixtral-8x7b-32768"
            opacity: 0.5
            font.pointSize: 9
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 480
        }
        Label {
            visible: providerCombo.currentIndex === 1
            text: "Get your key at: platform.openai.com"
            opacity: 0.5
            font.pointSize: 9
        }
        Label {
            visible: providerCombo.currentIndex === 2
            text: "Get your key at: aistudio.google.com"
            opacity: 0.5
            font.pointSize: 9
        }
        Label {
            visible: providerCombo.currentIndex === 3
            text: "Get your key at: openrouter.ai  •  Supports 100+ models"
            opacity: 0.5
            font.pointSize: 9
        }

        Item { Kirigami.FormData.isSection: true }

        // ---- Save ----
        Button {
            text: "Save"
            icon.name: "document-save"
            onClicked: {
                aiSettings.apiKey = apiKeyField.text;
                aiSettings.groqModel = groqModelField.text;
                aiSettings.model = openaiModelField.text;
                aiSettings.geminiModel = geminiModelField.text;
                aiSettings.openrouterModel = openrouterModelField.text;
                saveConfirmation.visible = true;
                saveTimer.restart();
            }
        }

        Label {
            id: saveConfirmation
            text: "✓ Settings saved"
            color: "#30d158"
            visible: false
            Timer {
                id: saveTimer
                interval: 2000
                onTriggered: saveConfirmation.visible = false
            }
        }
    }
}
