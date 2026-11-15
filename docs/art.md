# 圖和程式的約定（心情小屋）

畫風是**棉花糖雲朵風**：每樣東西都是軟軟圓圓的一塊，霧面、沒有框線、粉彩色，左上方來一點柔和的光（放射漸層），上半部一點白白的光，下面一點淡淡的陰影。全部用程式畫（`design/art/`），沒有別人的素材。

## 棉棉不是一張一張的圖（已經決定）
- **棉棉、小雨、大人、朋友、弟弟**都是 APP 裡用 `CustomPainter` 照參數畫的（`app/lib/app/cloud.dart`），參數在 `app/lib/core/looks.dart`：
  - 身體：8 個圓圓的「泡泡」（中心、寬高、轉的角度、尖不尖），每種心情排法不一樣（圓圓的、垂下來、壓扁、尖尖的、縮小、拉長、挺胸）。
  - 臉：眉毛的角度、眼睛（圓的大小、開心的 ^、安心的閉眼 ‿、半垂的眼皮、往旁邊看）、嘴巴（彎度、張開、寬度、牙齒、歪歪的、O）、臉紅、眼淚、眼眶的一滴淚、汗。
  - 旁邊的小東西：星光、冒煙、抖抖的線、「叮」的線、遮臉的小手、胸前的星星、z z、嘆氣、三個點、「？」。
- 為什麼：兩個心情之間可以**慢慢變**（`Look.lerp`，大約 0.9 秒），小朋友看得到「心情是會變的」，例如冷靜小屋做完，棉棉從生氣慢慢變成安心；14 種心情不用畫 14 張圖，大小怎麼放都清楚。
- 頭上的記號分得出是誰：棉棉一小撮捲捲的雲、小雨一滴小水珠、朋友兩個小辮子、弟弟一個小圓點、大人沒有（比較大、顏色固定）。
- `design/art/mianmian.py` 讀 `looks.dart` 的數字，用一樣的畫法畫成 SVG（APP 圖示、「找大人」的按鈕、門上的小圖、測試用的總表），所以兩邊永遠一樣。改臉只要改 `looks.dart`。
- `test/rules_test.dart` 檢查：14 種心情每種都有 8 個泡泡、任兩種的眉毛或嘴巴至少一個不一樣、顏色都不一樣。

## SVG 的規則（flutter_svg 畫得出來）
- 只用 `<path>`、`fill`／`stroke`／`fill-opacity`、`<linearGradient>`／`<radialGradient>`（`gradientUnits="userSpaceOnUse"`）、`<g transform opacity>`。
- 不能用 `<filter>`（沒有模糊）、`<mask>`、`<clipPath>`、`<style>`、`<text>`、`<image>`、`<pattern>`。柔和的影子是同一個形狀畫三次、一次比一次大一點、淡一點。
- 每個檔案小於 70 KB；`python3 design/art/build.py fluttercheck` 用真的 flutter_svg 和 Chromium 各畫一次比對。

## 檔案（`app/assets/art/`）
| 資料夾 | 檔案 | 用在哪裡 |
|---|---|---|
| `house/` | `house`、`house_lit`（燈亮著）、`sun`、`moon`、`ground`（雲朵地面）、`puff`（天上的雲） | 小屋門口、休息畫面 |
| `calm/` | `balloon`、`teddy`、`pillow`、`cup`、`numcloud`（數到四的雲，數字由 APP 寫）、`heart`、`way_<方法>` | 冷靜小屋 |
| `icons/` | `door_<faces/story/calm/help/diary>`、`cloud_small`（日記還沒寫的一天） | 小屋的五個門、日記 |
| `stories/` | `bg_<home/school/park/night/clinic/market/rain>`（400×300）和小故事的東西 | 小故事、怎麼辦 |

- 小故事的畫面是 4:3：背景鋪滿，東西照 `stories.dart` 的 `Prop(名字, 中心 x, 底部 y, 寬)` 放（都是 0～1 的比例），每個東西的檔案底部就是它站的地方；雲朵角色由 APP 畫在上面。
- APP 圖示：`design/art/icon.py`（棉棉開心的臉、薰衣草到粉紅的天空、一顆愛心），`export` 寫進 Android 和 iOS。
