pragma Singleton

import Quickshell
import Quickshell.Services.Pam
import QtQuick

Singleton {
    id: root

    property bool locked: false
    property string currentText: ""
    property bool unlockInProgress: false
    property bool showFailure: false
    property string failMessage: ""

    // Set true briefly before clearing text on failure, so UI can animate dots red
    property bool failureFlash: false

    property string _savedPassword: ""
    property string _errorMessage: ""

    signal unlockAccepted()

    PamContext {
        id: pam
        config: "hyprlock"

        onPamMessage: {
            if (pam.responseRequired)
                pam.respond(root._savedPassword);
        }

        onError: error => {
            root._errorMessage = PamError.toString(error);
        }

        onCompleted: result => {
            root.unlockInProgress = false;
            if (result === PamResult.Success) {
                root.showFailure = false;
                root.unlockAccepted();
            } else {
                root.failureFlash = true;
                root.showFailure = true;
                if (result === PamResult.Error)
                    root.failMessage = root._errorMessage || "Authentication error";
                else if (result === PamResult.MaxTries)
                    root.failMessage = "Too many attempts";
                else
                    root.failMessage = "Incorrect password";
                root._errorMessage = "";
                clearTextTimer.restart();
                failTimer.restart();
            }
        }
    }

    // Delay text clear so dots can flash red
    Timer {
        id: clearTextTimer
        interval: 250
        onTriggered: {
            root.currentText = "";
            root.failureFlash = false;
        }
    }

    Timer {
        id: failTimer
        interval: 2000
        onTriggered: root.showFailure = false
    }

    function lock(): void {
        currentText = "";
        unlockInProgress = false;
        showFailure = false;
        failureFlash = false;
        failMessage = "";
        locked = true;
    }

    function tryUnlock(): void {
        if (unlockInProgress) return;
        _savedPassword = currentText;
        currentText = "";
        unlockInProgress = true;
        showFailure = false;
        pam.start();
    }

    function clear(): void {
        currentText = "";
    }

    function finishUnlock(): void {
        locked = false;
        currentText = "";
    }
}
