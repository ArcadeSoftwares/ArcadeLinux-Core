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
        property string provider: "openai"
        property string apiKey: ""
        property string model: "gpt-4o-mini"
        property string geminiModel: "gemini-2.0-flash"
        property string openrouterModel: "openai/gpt-4o-mini"
    }

    Kirigami.FormLayout {
        id: formLayout

        // ---- Header ----
        Item { Kirigami.FormData.isSection: true }

        Kirigami.Heading {
            text: "🤖 AI Assistant"
            level: 2
            Kirigami.FormData.label: ""
        }

        Label {
            text: "Type /ai followed by your question in Spotlight to get an AI-powered answer inline."
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 480
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        // ---- Provider selection ----
        ComboBox {
            id: providerCombo
            Kirigami.FormData.label: "AI Provider"
            model: ["OpenAI (GPT)", "Google Gemini", "OpenRouter"]
            currentIndex: aiSettings.provider === "gemini" ? 1 : (aiSettings.provider === "openrouter" ? 2 : 0)
            onCurrentIndexChanged: {
                if (currentIndex === 0) aiSettings.provider = "openai"
                else if (currentIndex === 1) aiSettings.provider = "gemini"
                else aiSettings.provider = "openrouter"
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

        // ---- Model (conditional) ----
        TextField {
            id: modelField
            Kirigami.FormData.label: "Model"
            visible: providerCombo.currentIndex !== 1  // hidden for Gemini (uses its own)
            text: providerCombo.currentIndex === 2 ? aiSettings.openrouterModel : aiSettings.model
            Layout.minimumWidth: 260
            onEditingFinished: {
                if (providerCombo.currentIndex === 2) aiSettings.openrouterModel = text
                else aiSettings.model = text
            }
        }

        TextField {
            id: geminiModelField
            Kirigami.FormData.label: "Gemini Model"
            visible: providerCombo.currentIndex === 1
            text: aiSettings.geminiModel
            Layout.minimumWidth: 260
            onEditingFinished: aiSettings.geminiModel = text
        }

        // ---- Hints ----
        Label {
            visible: providerCombo.currentIndex === 0
            text: "Get your key at: platform.openai.com"
            opacity: 0.5
            font.pointSize: 9
        }
        Label {
            visible: providerCombo.currentIndex === 1
            text: "Get your key at: aistudio.google.com"
            opacity: 0.5
            font.pointSize: 9
        }
        Label {
            visible: providerCombo.currentIndex === 2
            text: "Get your key at: openrouter.ai"
            opacity: 0.5
            font.pointSize: 9
        }

        Item { Kirigami.FormData.isSection: true }

        // ---- Save button ----
        Button {
            text: "Save"
            icon.name: "document-save"
            onClicked: {
                aiSettings.apiKey = apiKeyField.text
                if (providerCombo.currentIndex === 2) aiSettings.openrouterModel = modelField.text
                else if (providerCombo.currentIndex === 0) aiSettings.model = modelField.text
                else aiSettings.geminiModel = geminiModelField.text
                saveConfirmation.visible = true
                saveTimer.restart()
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
