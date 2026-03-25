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
    property string status: "locked"  // "locked" | "typing" | "unlocking" | "failed"

    // Set true briefly before clearing text on failure, so UI can animate dots red
    property bool failureFlash: false

    property string _savedPassword: ""
    property string _errorMessage: ""

    signal unlockAccepted()
    signal clearInput()

    onCurrentTextChanged: {
        if (status !== "unlocking" && status !== "failed") {
            status = currentText.length > 0 ? "typing" : "locked";
        }
    }

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
                root.status = "failed";
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
            root.clearInput();
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
        clearInput();
        unlockInProgress = false;
        showFailure = false;
        failureFlash = false;
        failMessage = "";
        status = "locked";
        locked = true;
    }

    function tryUnlock(password: string): void {
        if (unlockInProgress) return;
        _savedPassword = password || currentText;
        currentText = "";
        clearInput();
        unlockInProgress = true;
        showFailure = false;
        status = "unlocking";
        pam.start();
    }

    function clear(): void {
        currentText = "";
        clearInput();
    }

    function finishUnlock(): void {
        locked = false;
        currentText = "";
        clearInput();
        status = "locked";
    }
}
