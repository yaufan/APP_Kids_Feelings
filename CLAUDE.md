# 給 Claude 的專案規則（心情小屋）

這份是這個專案的「記憶」。每個在這個專案裡工作的 Claude 都要照著做。它是「畫畫小鎮」（https://github.com/yaufan/APP_Kids_Paint）、「字母寵物」（https://github.com/yaufan/APP_Kids_Paint_for_learning_writing）、「動物小餐廳」（https://github.com/yaufan/APP_Kids_Cook）、「小卡認天下」（https://github.com/yaufan/APP_Kids_Card_Game）、「想一想樂園」（https://github.com/yaufan/APP_Kids_Brainstorming）、「眼尖尖大挑戰」（https://github.com/yaufan/APP_Kids_FalseCharge）、「迷宮小冒險」（https://github.com/yaufan/APP_Kids_maze）和「小小生活家」（https://github.com/yaufan/APP_Kids_live_circ）的兄弟 APP，技術和流程照那邊（畫風不同），這裡寫這個專案自己的事。程式的架構最接近小小生活家（Python 畫 SVG、ParentPass、休息時間），有疑問先看那邊怎麼做。

## 和使用者合作
- **一律用繁體中文回覆**，用白話說明，少用技術名詞；要用的話順便解釋。
- 使用者用手機上的 Claude App 看對話，**打不開 artifact 連結**。圖片、影片、聲音、QR code 都用傳檔案的方式（SendUserFile）給。
- 設計階段：每個想法都畫成草圖（`docs/mockups/`）傳給使用者看，再問。
- 之後每做完一版：給示範影片片段、手機截圖、下載 QR code（和畫畫小鎮一樣）。
- 有要使用者決定的事，列出選項和我的建議，再問。
- 不要開 pull request，除非使用者要求。用了網路搜尋，回覆最後附「Sources:」和連結。

## 這個 APP
- 給 **2～5 歲**的小朋友，在台灣，國語為主：認識心情、說出心情、讓自己冷靜下來。主角是一朵會變心情的雲「棉棉」（形狀、顏色、臉都跟心情變）。
- 五個房間：認表情、小故事（這是什麼心情）、冷靜小屋（吹氣球深呼吸、數到四、抱抱、搥枕頭、喝水、找大人；不限時）、怎麼辦、心情日記；每個故事後都有「家長一起說」問題卡（可跳過）。
- 兩個難度：小小（2～3 歲）四種心情；大（4～5 歲）十四種（開心、難過、生氣、害怕、驚訝、害羞、緊張、失望、得意、累累的、無聊、嫉妒、安心、委屈）。
- 不教分享輪流（留給真人）；回饋是棉棉的臉變了，沒有星星和分數。
- 設計在 [docs/design.md](docs/design.md)，改設計時一起改它；草圖在 `docs/mockups/`。
- 畫風：**棉花糖雲朵風**，只做一種（霧面、沒有框線、粉彩漸層、圓圓軟軟）。要和兄弟 APP 的畫風**不一樣**。
- 每次玩多久由家長設定（預設 15 分鐘，5／10／15／20／30），時間到了說「換你去做了！去跟爸爸媽媽說說你今天的心情」。
- 搥枕頭以用力點為主、搖手機為輔（加速度感應器不用權限），家長可關。
- 技術名稱：Flutter 專案 `feelings_house`、applicationId `com.yaufan.feelingshouse`、APK `feelings-house-版本-arm64.apk`、簽章環境變數 `FEELINGS_HOUSE_KEYSTORE`。
- 資安：不接受別的 APP 傳來的頁面（`flutter_deeplinking_enabled` 關掉、`overridePlatformDefaultLocation`），家長模式只能從家長關卡進去（`ParentPass`），不要任何權限。
- 不連網、不定位、沒有廣告、沒有帳號。以後上架要收費：免費下載一部分，一次買斷完整版，購買只在家長模式（要過家長關卡）。
- 每個動作都要有音效，全部用程式合成。
- 授權：非商業使用（`LICENSE`），中英文版本；別人做的部分（字型）在 `NOTICE.md`。
- 名稱：心情小屋。GitHub：https://github.com/yaufan/APP_Kids_Feelings

## GitHub Actions
- 工作流程（照小小生活家，2026-11-15 加好；第一次放上 main 前要先問）：
  - `app.yml`（App）：推到 `main` 而且改到 `app/**` 時跑分析、全部測試（含完整流程）、打包 APK，約 15～20 分鐘。
  - `release.yml`（Release）：推到 `main` 而且改到 `app/pubspec.yaml`、`CHANGELOG.md` 或它自己時，版本還沒發布過就打包三個 APK 放上 Releases，約 20 分鐘；版本沒變約 1 分鐘。
  - `cleanup.yml`：手動，刪舊的建置檔案，約 1 分鐘。
- 推工作分支（`claude/...`）不會啟動任何工作流程。
- 簽章：和畫畫小鎮用**同一把測試金鑰**（別名 `kidspaint`），Secrets 名稱一樣：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`，要放在這個專案的 Actions → Secrets → Repository secrets。指紋 `TEST_KEY_SHA256` 寫在工作流程裡。以後上架要換成正式的上傳金鑰。
- 發新版本：`app/pubspec.yaml` 的 `version`、`app/lib/app/version.dart` 的預設值、`CHANGELOG.md` 最上面一段（`## 版本 …`）三個要一致（`test/version_test.dart` 檢查）。
- **任何會啟動 Actions 的動作，都要先問使用者，等使用者同意才做**，問的時候說清楚四件事：
  1. 會跑哪些工作流程。
  2. 這次大約用掉幾分鐘。
  3. 這個月目前用了多少。
  4. 跑完大約還剩多少。

  規則和畫畫小鎮的 `CLAUDE.md` 一樣；那個帳號每月 2,000 分鐘是所有私有專案共用的，Mac 主機的 1 分鐘算 10 分鐘。

## Git
- **發布新版本、做成可以安裝的 APK、給下載 QR code**：照 skill `release-kids-app`（`.claude/skills/release-kids-app/SKILL.md`），兄弟 APP 共用同一份。
- 在系統指定的 `claude/...` 工作分支上開發，commit 完就推這個分支。
- commit 訊息用英文寫清楚改了什麼和為什麼，結尾加系統要求的署名行。不要寫模型名稱。
- 不能 commit：金鑰、密碼、不公開的文件、`__pycache__`。

## 和畫畫小鎮共用的做法（開始寫程式時照著做）
- Flutter 3.47.8、Riverpod、flutter_svg、audioplayers、flutter_tts。存檔是一個 JSON 檔（`app/lib/core/store.dart`），沒有用 drift，所以本機跑測試**不用** sqlite 那段，直接 `flutter test`。
- 觸控：用原始的手指事件（`Listener`），手指一碰就畫。不要用拖曳手勢，它要移動 36 點才開始，小朋友短短的一筆會不見。
- 圖和聲音都用程式產生（SVG 用 Python 畫；聲音用 numpy 合成），不用別人的素材。
- 本機測試：在 `app/` 裡 `flutter test`（不含 `test/flow_test.dart`），`flutter analyze` 要零問題。以後加了 drift，才照畫畫小鎮的 `tools/run_tests.sh`（pubspec 的 sqlite 那段不能 commit）。
- 完整流程和截圖：`flutter test test/flow_test.dart`，截圖在 `app/build/screenshots/`。
- 示範影片（每一版都要給使用者）：在 `app/` 裡 `flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true`（約 5～10 分鐘，要 ffmpeg），再在專案根目錄 `python3 tools/demo_audio.py` 把背景音樂和音效混進去。輸出 `app/build/demo/demo.mp4`；`chapters.txt` 是每一段開始的格數（每秒 10 格），用來剪新功能的片段。

## 程式在哪裡
- `app/lib/core/`：心情和相近的心情（`feelings.dart`）、棉棉的臉和身體的參數（`looks.dart`：8 個泡泡、眉毛、眼睛、嘴巴、眼淚、旁邊的小東西，`Look.lerp` 慢慢變）、20 個小故事和問題卡（`stories.dart`：對的心情、小小的答案、畫面上東西的位置、家長一起說；`HelpWay` 是怎麼辦的三個好方法）、冷靜小屋六個方法（`calm.dart`）、設定、日記、出題（`game.dart`：`faceQuestion`、`storyQuestion`，相近的心情不會一起當錯的選項）、存檔、聲音、語音、搖手機（`shake.dart`，sensors_plus，不用權限）。
- `app/lib/app/cloud.dart`：棉棉、小雨、大人、朋友、弟弟都是 `CloudPainter` 照參數畫的，不是圖檔（`docs/art.md`）；`widgets.dart` 是按鈕（`Pressable` 用原始的手指事件）、心情卡、對話框。
- `app/lib/features/`：小屋（`home/`）、認表情（`faces/`）、小故事（`story/`，畫面在 `story_picture.dart`）、怎麼辦（`help/`）、冷靜小屋（`calm/`：`calm_views.dart` 是六個方法）、心情日記（`diary/`）、家長一起說（`talk/`）、休息（`rest/`）、家長關卡和家長模式（`parent/`）。
- 冷靜小屋不受休息時間限制（`RestGuard` 不管 `/calm`）；家長模式可以一鍵打開。
- 圖：`design/art/`（`kit.py` 棉花糖畫法、`house.py`、`props.py`、`scenes.py`、`mianmian.py` 讀 `looks.dart` 畫棉棉、`icon.py`；`build.py all`、`sheet`、`fluttercheck`）；聲音：`design/sounds/make_sounds.py`（42 個檔）。

## 目前的狀態（2026-11-15）
- 0.1.0 已發布（2026-11-15）：Releases 有三個 APK，App 和 Release 都成功；Secrets 加好了。
- 還沒在真手機上試過：TTS 的聲音、搖手機的力道（`SystemShakes.threshold`）、聲音好不好聽，要使用者裝到手機後再看。
