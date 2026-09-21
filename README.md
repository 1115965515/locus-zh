# Locus 1.0.2-zh

基于 [Locus](https://github.com/ChrisMack32/Locus) 1.0.2 的简体中文版。

## 相对原版的改动

- 界面与文案汉化
- 中国大陆地图选点自动纠偏（GCJ-02 → WGS-84；港澳台与海外不变）
- 适配 LocalDevVPN 当前默认本机地址（`10.7.1.1` / 对端 `10.7.0.1`）

版本号与上游对齐，仅追加 `-zh`。上游若已自行修复坐标偏移，后续 `-zh` 版本将只做汉化。

## 构建

见 `BUILD-ZH.md`，或推送到 GitHub 后由 Actions 自动产出未签名 IPA。

## 许可

MIT（与上游一致）。定位注入使用 MIT 许可的 idevice FFI。
