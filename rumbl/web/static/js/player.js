let Player = {
    player: null,

    init(domId, plyerId, onReadby) {
        window.onYouTubeIframeAPIReady = () => {
            this.onIframeReady(domId, playerId, onReadby);
        };
        let youtubeScriptTag = document.createElement("script");
        // APIの読み込み APIが読み込まれるとonYouTubeIframeAPIReady関数が自動で呼ばれる
        youtubeScriptTag.src = "//www.youtube.com/iframe_api";
        document.head.appendChild(youtubeScriptTag);
    },

    onIframeReady(domId, playerId, onReady) {
        this.player = new YT.Player(domId, {
            height: "360",
            width: "420",
            videoId: playerId,
            events: {
                "onReady": (event => onReady(event)),
                "onStateChange": (event => this.onPlayerStateChange(event))
            }
        });
    },

    onPlayerStateChange(event) {},
    getCurrentTime() { return Math.floor(this.player.getCurrentTime() * 1000); },
    seekTo(millsec) { return this.player.seekTo(millsec / 1000); }
};
export default Player;