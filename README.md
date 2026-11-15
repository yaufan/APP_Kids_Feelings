# 心情小屋

給 **2～5 歲**的小朋友，在台灣，國語為主：認識心情、說出心情、讓自己冷靜下來。主角是一朵會變心情的雲「棉棉」（形狀、顏色、臉都跟心情變）。五個房間：認表情、小故事、冷靜小屋、怎麼辦、心情日記；每個故事後有給大人的「家長一起說」問題卡。目的是讓小朋友有「心情的詞」和「冷靜的辦法」，而且每一段都把小朋友帶回真人身邊。

- 設計：[docs/design.md](docs/design.md)，草圖在 `docs/mockups/`，圖和程式的約定在 [docs/art.md](docs/art.md)。
- 和「[畫畫小鎮](https://github.com/yaufan/APP_Kids_Paint)」「[字母寵物](https://github.com/yaufan/APP_Kids_Paint_for_learning_writing)」「[動物小餐廳](https://github.com/yaufan/APP_Kids_Cook)」「[小卡認天下](https://github.com/yaufan/APP_Kids_Card_Game)」「[想一想樂園](https://github.com/yaufan/APP_Kids_Brainstorming)」「[眼尖尖大挑戰](https://github.com/yaufan/APP_Kids_FalseCharge)」「[迷宮小冒險](https://github.com/yaufan/APP_Kids_maze)」「[小小生活家](https://github.com/yaufan/APP_Kids_live_circ)」是兄弟 APP：同一個作者、同一套技術、不同畫風。
- 不連網、不定位、沒有廣告、沒有帳號；心情日記只存在手機裡。

## 下載（Android）
- 最新版：[Releases](https://github.com/yaufan/APP_Kids_Feelings/releases/latest)，一般手機下載 `feelings-house-版本-arm64.apk`。
- 用手機掃描 [docs/download-qr.png](docs/download-qr.png)。

## 目前進度
- 0.1.0（測試版）：棉棉和十四種心情的參數臉（會慢慢變）、小屋、認表情、20 個小故事和怎麼辦、冷靜小屋六個方法、心情日記和這個星期、家長一起說的問題卡、休息時間、家長關卡和家長模式、音樂和音效、APP 圖示。棉花糖雲朵風。版本紀錄在 [CHANGELOG.md](CHANGELOG.md)。

## 程式和素材在哪裡
- `app/`：Flutter 程式。`lib/core/` 是心情（`feelings.dart`）、棉棉的臉的參數（`looks.dart`）、小故事和問題卡（`stories.dart`）、冷靜的方法（`calm.dart`）、存檔和出題規則（`game.dart`）、聲音、語音、搖手機；`lib/app/cloud.dart` 照參數畫棉棉；`lib/features/` 是小屋、認表情、小故事、怎麼辦、冷靜小屋、心情日記、家長一起說、休息、家長模式。
- `design/art/`：用 Python 畫的圖（棉花糖雲朵風）。`kit.py` 是畫法，`house.py`、`props.py`、`scenes.py`、`mianmian.py`（棉棉，讀 `looks.dart`）、`icon.py`；`python3 build.py all` 全部重畫，`fluttercheck` 用真的 flutter_svg 比對。
- `design/sounds/make_sounds.py`：合成全部的音樂和聲音。
- 測試：在 `app/` 裡 `flutter test`；完整流程 `flutter test test/flow_test.dart`，截圖在 `app/build/screenshots/`；示範影片 `flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true`，再 `python3 tools/demo_audio.py`。

## 授權
- 非商業使用授權：自己、家人使用，或學校、非營利團體的教學，都可以免費使用、修改、分享，要註明出處。
- 商業用途（販賣、收費、廣告、上架）要先取得作者書面同意。也不可以拿來訓練 AI。
- 細節見 [LICENSE](LICENSE)；別人做的部分（字型）見 [NOTICE.md](NOTICE.md)。
