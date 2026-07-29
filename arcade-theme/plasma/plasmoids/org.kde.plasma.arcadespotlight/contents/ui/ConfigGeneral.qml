import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configPage

    property alias cfg_aiProvider: providerCombo.currentValue
    property alias cfg_aiApiKey: apiKeyField.text
    property alias cfg_aiGroqModel: groqModelField.text
    property alias cfg_aiOpenaiModel: openaiModelField.text
    property alias cfg_aiGeminiModel: geminiModelField.text
    property alias cfg_aiOpenrouterModel: openrouterModelField.text

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0

        // ---- Header ----
        RowLayout {
            spacing: 12
            Layout.bottomMargin: 8

            Text {
                text: "✦"
                color: "#4d9cff"
                font.pixelSize: 22
            }
            ColumnLayout {
                spacing: 2
                Label {
                    text: "AI Assistant"
                    font.pixelSize: 17
                    font.weight: Font.SemiBold
                }
                Label {
                    text: "Type /ai <question> in Spotlight then press Enter"
                    opacity: 0.55
                    font.pixelSize: 12
                }
            }
        }

        // ---- Divider ----
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1,1,1,0.08)
            Layout.topMargin: 8
            Layout.bottomMargin: 20
        }

        // ---- Provider ----
        GridLayout {
            columns: 2
            columnSpacing: 16
            rowSpacing: 14
            Layout.fillWidth: true

            Label { text: "Provider"; font.weight: Font.Medium; opacity: 0.8 }

            ComboBox {
                id: providerCombo
                Layout.minimumWidth: 280
                textRole: "label"
                valueRole: "id"
                model: [
                    { id: "groq",        label: "Groq  —  Free & blazing fast" },
                    { id: "openai",      label: "OpenAI  (GPT-4o, etc.)" },
                    { id: "gemini",      label: "Google Gemini" },
                    { id: "openrouter",  label: "OpenRouter  (100+ models)" }
                ]
                Component.onCompleted: {
                    for (var i = 0; i < model.length; i++) {
                        if (model[i].id === cfg_aiProvider) { currentIndex = i; break; }
                    }
                }
                onActivated: cfg_aiProvider = currentValue
            }

            // ---- API Key ----
            Label { text: "API Key"; font.weight: Font.Medium; opacity: 0.8 }

            RowLayout {
                spacing: 8
                TextField {
                    id: apiKeyField
                    Layout.minimumWidth: 280
                    placeholderText: "Paste your API key here…"
                    echoMode: showKeyBtn.checked ? TextInput.Normal : TextInput.Password
                }
                Button {
                    id: showKeyBtn
                    checkable: true
                    icon.name: checked ? "view-hidden" : "view-visible"
                    ToolTip.text: checked ? "Hide key" : "Show key"
                    ToolTip.visible: hovered
                }
            }

            // ---- Model (per-provider) ----
            Label {
                text: "Model"
                font.weight: Font.Medium
                opacity: 0.8
            }

            ColumnLayout {
                spacing: 4

                TextField {
                    id: groqModelField
                    visible: cfg_aiProvider === "groq"
                    Layout.minimumWidth: 280
                    placeholderText: "llama-3.3-70b-versatile"
                }
                TextField {
                    id: openaiModelField
                    visible: cfg_aiProvider === "openai"
                    Layout.minimumWidth: 280
                    placeholderText: "gpt-4o-mini"
                }
                TextField {
                    id: geminiModelField
                    visible: cfg_aiProvider === "gemini"
                    Layout.minimumWidth: 280
                    placeholderText: "gemini-2.0-flash"
                }
                TextField {
                    id: openrouterModelField
                    visible: cfg_aiProvider === "openrouter"
                    Layout.minimumWidth: 280
                    placeholderText: "openai/gpt-4o-mini"
                }
            }

            // ---- Hint ----
            Item {}
            Label {
                opacity: 0.5
                font.pixelSize: 11
                text: {
                    if (cfg_aiProvider === "groq")       return "Free key at: console.groq.com"
                    if (cfg_aiProvider === "openai")     return "Key at: platform.openai.com"
                    if (cfg_aiProvider === "gemini")     return "Key at: aistudio.google.com"
                    if (cfg_aiProvider === "openrouter") return "Key at: openrouter.ai"
                    return ""
                }
            }
        }
    }
}
