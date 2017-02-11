import Player from "./player"

let Video = {
    init(socket, element) {
        if (!element) { return; }
        let playerId = element.getAttribute("data-player-id");
        let videoId = element.getAttribute("data-id");
        socket.connect()
        Player.init(element.id, playerId, () => {
            this.onReady(videoId, socket);
        });
    },

    onReady(videoId, socket) {
        let msgContainer = document.getElementById("msg-container");
        let msgInput = document.getElementById("msg-input");
        let postButton = document.getElementById("msg-submit");
        // トピックの識別
        let vidChannel = socket.channel("videos:" + videoId);

        postButton.addEventListener("click", e => {
            let payload = { body: msgInput.value, at: Player.getCurrentTime() };
            vidChannel.push("new_annotation", payload)
                .receive("error", e => console.log(e));
            msgInput.value = "";
        });

        // サーバーからのプッシュイベントを受け取るイベントハンドラを設定
        vidChannel.on("new_annotation", (resp) => {
            vidChannel.params.last_seen_id = resp.id;
            this.renderAnnotation(msgContainer, resp);
        });

        msgContainer.addEventListener("click", e => {
            e.preventDefault();
            let seconds = e.target.getAttribute("data-seek") ||
                e.target.parentNode.getAttribute("data-seek");

            if (!seconds) { return; }

            Player.seekTo(seconds);
        });

        // チャンネルへのjoin receiveで帰ってきたものを受け取る(OTPっぽい)
        vidChannel.join()
            .receive("ok", resp => {
                let ids = resp.annotations.map(ann => ann.id);
                if (ids.length > 0) {
                    // 再生したコメントの最後のものを取得
                    vidChannel.params.last_seen_id = Math.max(...ids);
                }
                console.log(vidChannel.params.last_seen_id);
                this.scheduleMessages(msgContainer, resp.annotations)
            })
            .receive("error", reason => console.log("join failed", reason));
    },

    esc(str) {
        let div = document.createElement("div");
        div.appendChild(document.createTextNode(str));
        return div.innerHTML;
    },

    renderAnnotation(msgContainer, { user, body, at }) {
        let template = document.createElement("div");

        template.innerHTML = `
        <a href="#" data-seek="${this.esc(at)}">
            [${this.formatTime(at)}]
            <b>${this.esc(user.username)}</b>: ${this.esc(body)}
        </a>
        `;

        msgContainer.appendChild(template);
        msgContainer.scrollTop = msgContainer.scrollHeight;
    },

    scheduleMessages(msgContainer, annotations) {
        setTimeout(() => {
            let ctime = Player.getCurrentTime();
            let remaining = this.renderAtTime(annotations, ctime, msgContainer);
            this.scheduleMessages(msgContainer, remaining);
        }, 1000);
    },

    renderAtTime(annotations, seconds, msgContainer) {
        return annotations.filter(ann => {
            if (ann.at > seconds) {
                // コメントした時間以降で無ければ表示しない
                return true;
            } else {
                // 表示してリストから除外する
                this.renderAnnotation(msgContainer, ann);
                return false;
            }
        });
    },

    formatTime(at) {
        let date = new Date(null);
        date.setSeconds(at / 1000);
        return date.toISOString().substr(14, 5);
    }
}

export default Video;