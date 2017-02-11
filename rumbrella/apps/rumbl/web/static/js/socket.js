import { Socket } from "phoenix"

let socket = new Socket("/socket", {
    params: { token: window.userToken },
    // バッククオートで囲んだものがテンプレートリテラルとして値を文字に埋め込める
    logger: (kind, msg, data) => { console.log(`${kind}: ${msg}`, data); }
});

export default socket