# OpenTPU 网页对话测试指南

网页用于检查模型加载、真实文本生成、流式输出和多轮对话。它与 OpenTPU 的 `/v1/models`、`/v1/chat/completions` 共用一个本地服务。网页根据服务返回的模型 ID 显示当前模型，并按模型保存浏览器端对话历史。

## 文件与依赖

| 文件 | 用途 |
|---|---|
| [Start-OpenTPUChat.ps1](../web/Start-OpenTPUChat.ps1) | 从 Windows PowerShell 启动 WSL 内的服务，选择模型、后端、端口及上下文 |
| [server.py](../web/server.py) | 复用 `opentpu.serve.api`，增加 `/chat` 页面入口 |
| [index.html](../web/index.html) | 对话界面，支持流式回复、停止生成和新对话，无需前端构建 |

需有可运行 OpenTPU 的 WSL 环境、 Python 环境及已下载的模型。启动器默认使用 `OpenTPU-Ubuntu`、用户 `opentpu`、源码目录 `/opt/opentpu/OpenTPU` 和解释器 `/opt/opentpu/venv/bin/python`。可分别用 `-Distro`、`-WslUser`、`-OpenTPUSource`、`-Python` 覆盖。模型、专家池、运行日志及镜像缓存放在仓库外。

## 一、在 Windows 上运行

从仓库根目录打开 PowerShell。先用小模型确认网页接口和流式输出。

```powershell
.\web\Start-OpenTPUChat.ps1 -ModelPath 'F:\OpenTPU\models\LFM2.5-230M' -Context 128
```

终端显示服务已监听后，在浏览器打开 `http://127.0.0.1:8765/chat`。首次建议选择「冒烟测试 · 4 tokens」，输入 `What is the capital of France? Answer briefly.`。确认页面显示预期模型 ID，能增量显示回答，再发一条关于上一轮的追问。换模型时先在终端按 `Ctrl+C` 停止服务，或用 `-Port` 指定不同端口。

Qwen3.5-4B 可直接用默认模型路径 `F:\OpenTPU\models\Qwen3.5-4B`。如需沿用之前网页测试的 FP4 配置：

```powershell
.\web\Start-OpenTPUChat.ps1 -WeightFormat fp4 -HeadFormat int8
```

## 二、用 35B 权重测试

本机的原始权重和 FP4 稀疏专家池均在 `F:\OpenTPU\models\Qwen3.6-35B-A3B`。使用已有的池与镜像缓存，避免重复创建。若是新环境，在已安装 OpenTPU 的 WSL 中从源码根目录初始化专家池。先创建镜像缓存目录。

```bash
model=/mnt/f/OpenTPU/models/Qwen3.6-35B-A3B
mkdir -p /mnt/f/OpenTPU/qwen36-isa-images
OTPU_FORMATS=attn=nvfp4,delta=nvfp4,mlp=nvfp4 \
  python3 tools/offload/pack_pool.py "$model" "$model/pool-mx1-fp4.bin" init --wformat fp4
```

初始化后，模拟器会从完整 checkpoint 按需打包缺失专家。

```powershell
$model = 'F:\OpenTPU\models\Qwen3.6-35B-A3B'
.\web\Start-OpenTPUChat.ps1 -ModelPath $model -Context 128 -ExpertSlots 8 `
    -PoolPath (Join-Path $model 'pool-mx1-fp4.bin') `
    -ImageCachePath 'F:\OpenTPU\qwen36-isa-images'
```

`-ExpertSlots 8` 对应每层 8 个槽。模型配置默认自动选择权重格式。短提示词也可能触发新专家打包，首次提交的响应时间以终端日志为准。测试时分别记录服务启动、首 token 和后续 decode 时间，并注明专家池及镜像缓存状态。生成速度不能直接换算为 FPGA 性能。

## 三、后端与排查

- `-Backend isa` 使用软件 ISA 模拟，适合模型加载和功能验证。启动器默认关闭批量 prompt runs，可用 `-EnablePromptRuns` 单独做对照。
- `-Backend board -Device /dev/xdma0` 指向 OpenTPU 上游 XDMA 实板路径，前提是运行环境能访问已配置板卡。ZCU102 的 PS–PL 控制和专家回填仍需对应的上位机后端。
- 网页一直显示等待服务时，先核对终端是否已完成加载，再访问 `http://127.0.0.1:8765/v1/models`。服务只监听 `127.0.0.1`，请通过服务地址打开网页。
- 日志如果报告缺少权重分片，检查 `model.safetensors.index.json` 和文件清单。如果报告 `no expert pool` 或池格式不匹配，核对 `-PoolPath`、模型 revision、OpenTPU 版本及量化配置。
- 记录实验时保存模型、后端、上下文、输入、生成上限和服务日志。网页请求采用流式输出，页面停止按钮取消当前浏览器请求。再次发送时先检查服务是否已结束上一轮。
