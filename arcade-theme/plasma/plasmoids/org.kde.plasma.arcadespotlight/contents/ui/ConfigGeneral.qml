import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Item {
    id: configRoot
    width: parent ? parent.width : 600
    height: formColumn.implicitHeight + 40

    // These cfg_ properties are automatically two-way bound to plasmoid.configuration by Plasma
    property alias cfg_aiProvider: providerCombo.currentValue
    property alias cfg_aiApiKey: apiKeyField.text
    property alias cfg_aiGroqModel: groqModelField.text
    property alias cfg_aiOpenaiModel: openaiModelField.text
    property alias cfg_aiGeminiModel: geminiModelField.text
    property alias cfg_aiOpenrouterModel: openrouterModelField.text

    ColumnLayout {
        id: formColumn
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
        spacing: 16

        // Header
        RowLayout {
            spacing: 10
            Layout.bottomMargin: 4
            Rectangle {
                width: 32; height: 32; radius: 8
                color: Qt.rgba(0.3, 0.6, 1.0, 0.18)
                border.color: Qt.rgba(0.3, 0.6, 1.0, 0.4)
                border.width: 1
                Label { anchors.centerIn: parent; text: "✦"; color: "#4d9cff"; font.pixelSize: 16 }
            }
            ColumnLayout {
                spacing: 1
                Label { text: "AI Assistant"; font.pixelSize: 15; font.weight: Font.SemiBold }
                Label { text: "Type  /ai <question>  then press Enter"; opacity: 0.55; font.pixelSize: 11 }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(0.5, 0.5, 0.5, 0.25) }

        // Provider
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { text: "Provider"; font.weight: Font.Medium; Layout.minimumWidth: 110 }
            ComboBox {
                id: providerCombo
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
                        if (model.get(i).id === cfg_aiProvider) { currentIndex = i; break; }
                    }
                }
                onActivated: cfg_aiProvider = currentValue
            }
        }

        // API Key
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { text: "API Key"; font.weight: Font.Medium; Layout.minimumWidth: 110 }
            TextField {
                id: apiKeyField
                Layout.fillWidth: true
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

        // Model field
        RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { text: "Model"; font.weight: Font.Medium; Layout.minimumWidth: 110 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                TextField {
                    id: groqModelField
                    Layout.fillWidth: true
                    visible: cfg_aiProvider === "groq"
                    placeholderText: "llama-3.3-70b-versatile"
                }
                TextField {
                    id: openaiModelField
                    Layout.fillWidth: true
                    visible: cfg_aiProvider === "openai"
                    placeholderText: "gpt-4o-mini"
                }
                TextField {
                    id: geminiModelField
                    Layout.fillWidth: true
                    visible: cfg_aiProvider === "gemini"
                    placeholderText: "gemini-2.0-flash"
                }
                TextField {
                    id: openrouterModelField
                    Layout.fillWidth: true
                    visible: cfg_aiProvider === "openrouter"
                    placeholderText: "openai/gpt-4o-mini"
                }
            }
        }

        // Hint
        Label {
            Layout.leftMargin: 110
            opacity: 0.5
            font.pixelSize: 11
            text: {
                if (cfg_aiProvider === "groq")       return "🔗 Get free API key at: console.groq.com"
                if (cfg_aiProvider === "openai")     return "🔗 Get API key at: platform.openai.com"
                if (cfg_aiProvider === "gemini")     return "🔗 Get API key at: aistudio.google.com"
                if (cfg_aiProvider === "openrouter") return "🔗 Get API key at: openrouter.ai"
                return ""
            }
        }
    }
}
