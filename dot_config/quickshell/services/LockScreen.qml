pragma Singleton

import Quickshell
import Quickshell.Io
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

    // Caps-lock state for the password-entry hint. Qt doesn't expose lock-key
    // state on Wayland, so the surface toggles this on the key event (feedback
    // can't lag typing) and we confirm against the kernel LED shortly after.
    // The LED read also supplies the initial state at lock time — caps may
    // already be on before the session locks.
    property bool capsLock: false

    function capsLockKeyPressed(): void {
        capsLock = !capsLock;
        capsVerifyTimer.restart();
    }

    Process {
        id: capsLedCheck
        // running at init: covers quickshell starting (or live-reloading,
        // which resets capsLock) while caps is already on.
        running: true
        command: ["sh", "-c", "grep -q 1 /sys/class/leds/*capslock*/brightness 2>/dev/null && echo 1 || echo 0"]

        stdout: SplitParser {
            onRead: data => root.capsLock = data.trim() === "1"
        }
    }

    Timer {
        id: capsVerifyTimer
        interval: 150
        onTriggered: capsLedCheck.running = true
    }

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
        capsLedCheck.running = true;
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
