import QtQuick 2.4
import Ubuntu.Components 1.3
import "../"

Page {
    id: controls
    property string stPlay: "playing"
    property string stPause: "paused"
    property string stStop: "stopped"
    property bool isAudio: false
    property bool checkState: false
    property bool updateState: false
    property int currentId: playlist.currentId
    property var currentState: main.currentState
    property var category
    property var meta

//    TODO
//    tools: ToolbarItems
//    {
//        ToolbarButton {
//            action: Action {
//                text: i18n.tr("More")
//                iconSource: "/usr/share/icons/ubuntu-mobile/actions/scalable/add.svg"
//            }
//        }

//        ToolbarButton {
//            action: Action {
//                text: i18n.tr("Settings")
//                iconSource: "/usr/share/icons/ubuntu-mobile/actions/scalable/settings.svg"
//            }
//        }
//    }

    onCurrentIdChanged:
    {
        var currentItem = playlist.currentItem;

        if (currentItem) {
            setState(stPlay);
            timer.updateMaximumValue(currentItem.duration);
        } else {
            timer.updateMaximumValue();
        }
        timer.reset();
    }

    onCurrentStateChanged:
    {
        if (currentState && (!checkState || currentState.state === state))
        {
            updateState = true;
            setState(currentState.state);
            updateCategory();
            updateMetadata();
            updateAudioState();

            info.updateInfos(meta);
            art.updateCoverArt(meta);
            volume.updateVolume(currentState.volume);
            timer.updateValue(currentState.time);
            updateState = false;
            checkState = false;
        }
    }

    VolumeControl {
        id: volume
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(5)

        onValueChanged: {
            if (!updateState) {
                main.volume(convertToVLC(value));
            }
        }

    }

    Rectangle {
        id: content
        color: "#222"
        anchors.top: volume.bottom
        anchors.bottom: actions.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(2)

        Playlist {
            id: playlist
            view.expanded: expanded
            anchors.fill: parent
            property bool expanded: isStopped()

            // workaround to expand/collapse playlist
            onExpandedChanged: view.container.isExpanded = expanded;
        }

        // BUG - VLC 2.1.5 does not show cover art
        CoverArtControl {
            id: art
            visible: !isStopped()

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: playlist.view.height + units.gu(1)
            anchors.bottomMargin: units.gu(1)

            onClick: tooglePlay()

            onMoveUp: volume.forward(volJump)
            onMoveDown: volume.backward(volJump)
            onMoveLeft: timer.backward(timeJump)
            onMoveRight: timer.forward(timeJump)

            onSwipeUp: playlist.prev()
            onSwipeDown: playlist.next()
            onSwipeLeft: playlist.next()
            onSwipeRight: playlist.prev()
        }

        InfoControl {
            id: info
            visible: (!isStopped() && isAudio && art.height > height)
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: units.gu(2)
        }

    }

    ActionsControl {
        id: actions
        isPlaying: controls.isPlaying();
        anchors.bottom: timer.top
        anchors.horizontalCenter: parent.horizontalCenter

        onClickPlay: play();
        onClickPause: pause();
        onClickStop: stop();
        onClickNext: playlist.next();
        onClickPrev: playlist.prev();
    }

    TimerControl {
        id: timer
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: units.gu(2)

        onValueChanged: {
            if (!updateState) {
                main.seek(Math.floor(value));
            }
        }

        function reset() {
            updateState = true;
            value = 0;
            updateState = false;
        }
    }

    // workaround for updating play/pause buttons quicly
    function setState(stat)
    {
        state = stat;

        if (isPlaying()) {
            actions.isPlaying = true;
        } else {
            actions.isPlaying = false;
        }
    }

    function play() {
        checkState = true;
        setState(stPlay);
        main.pause(); // toggle play/pause
    }

    function pause() {
        checkState = true;
        setState(stPause);
        main.pause();
    }

    function stop() {
        checkState = true;
        timer.reset();
        setState(stStop);
        main.stop();
    }

    function tooglePlay()
    {
        if (isPlaying()) {
            pause();
        } else {
            play();
        }
    }

    function isPlaying() {
        return (state === stPlay);
    }
    function isPaused() {
        return (state === stPause);
    }
    function isStopped() {
        return (state === stStop);
    }

    function updateCategory()
    {
        if (currentState.information && currentState.information.category) {
            category = currentState.information.category;
        }
    }

    function updateMetadata()
    {
        if (category) {
            meta = category.meta;
        }
    }

    function updateAudioState()
    {
        if (category && category.Type)
        {
            var type = category['Stream 0'].Type;

            if (type && type === "Audio") {
                isAudio = true;
            } else {
                isAudio = false;
            }
        }
    }
}
