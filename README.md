# AI 日程 MVP

极简 AI 日程 App：文本/分享输入 → DeepSeek 解析 → JSON(events[]) → SQLite 本地存储 → 列表渲染。适配 OPPO Find X7 Ultra（Android / ColorOS）。

## 功能

- **主页**：日程时间轴列表，下拉刷新。
- **输入页**：输入或粘贴日程文本，或通过系统分享接收文本；一键「解析并保存」调用 DeepSeek 并入库。
- **设置页**：配置 DeepSeek API Key（仅存本地）。

## 环境与运行

1. 安装 Flutter SDK（或使用本机已解压的 `flutter_sdk`），并确保 `flutter` 在 PATH 中。
2. 在项目根目录执行：
   - `flutter pub get`
   - 真机/模拟器：`flutter run`
   - 打包 APK：`flutter build apk --release`
3. 首次使用前在「设置」中填写 DeepSeek API Key。

## 中国镜像（可选）

如遇网络问题，可设置：

- `PUB_HOSTED_URL=https://pub.flutter-io.cn`
- `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`

## 真机适配（ColorOS）

- **后台网络**：若 App 在后台调用 AI API 失败，请在系统设置中允许本 App 后台运行/省电无限制。
- **通知/闹钟**：若后续加本地提醒，需在设置中开启通知权限。
- **分享入口**：从相机识图、相册、微信等分享文本到「AI 日程」即可打开输入页并填入内容。

## 数据协议

- AI 输出格式：`{"events":[{"start_time":"<ISO8601>","title":"<字符串>","duration_minutes":<整数>,"notes":"<可选>"}]}`。
- 冲突排期：新日程与已有日程时间重叠时，自动顺延到已有日程结束之后（线性堆叠）。
