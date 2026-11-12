# HSA-MoE-ACC

Heterogeneous System Architecture for MoE Edge Acceleration.

# 仓库管理须知

## 简述

本仓库由myh于2026/11/12创建，服务于NJU D-SMART-EDGE小组的科研探索，目标是在异构平台（FPGA+CPU+NPU+...）上部署开源MoE网络并实现加速。

## ==BM规范==

==**由于本仓库为公开开源仓库，请检查待上传所有资料是否包含SM信息，切勿上传。**==

## Git 协作规范

本项目采用 GitHub Flow。每项独立改动从最新的 `main` 创建短期分支，完成后通过 Pull Request（PR）合并回 `main`。

### 分支与主分支保护

- 有 `Write` 权限的协作者可推送工作分支。==**`main` 的修改统一通过 PR 合并，禁止直接推送、强推或删除 `main`**==。
- 分支名使用 `<类型>/<简短说明>`，说明使用小写英文和连字符。有对应 Issue 时可加入编号。

| 类型 | 用途 | 示例 |
| --- | --- | --- |
| `feat` | 新功能或硬件模块 | `feat/24-expert-dispatch` |
| `fix` | 修复缺陷 | `fix/axi-backpressure` |
| `refactor` | 重构 | `refactor/rtl-fifo` |
| `docs`、`test`、`ci` | 文档、测试或持续集成 | `docs/git-workflow` |
| `exp` | 设计空间探索或性能实验 | `exp/expert-cache-sweep` |

### 日常开发与提交

```bash
git switch main
git pull --ff-only origin main
git switch -c feat/24-expert-dispatch
# 修改并验证后，按文件暂存
git add <文件路径>
git diff --cached
git commit -m "feat(rtl): add expert dispatch queue"
git push -u origin feat/24-expert-dispatch
```

- 提交信息采用 Conventional Commits 格式 `<type>(<scope>): <summary>`，其中 `scope` 可省略，常见取值有 `rtl`、`hls`、`host`、`sim` 和 `docs`。常用类型包括 `feat`、`fix`、`docs`、`refactor`、`perf`、`test`、`build` 和 `ci`。
- 每次提交聚焦一个可审查的变更，相关测试与变更一起提交。涉及不兼容的接口、寄存器映射或配置变更时，在提交正文和 PR 中说明影响及迁移方式。

#### 提交信息示例

| 提交信息 | 适用场景 |
| --- | --- |
| `feat(rtl): add expert dispatch queue` | 新增专家分发队列 |
| `fix(rtl): handle AXI backpressure` | 修复 AXI 下游暂停接收时的数据传输问题 |
| `perf(hls): reuse expert weight tiles` | 在 HLS 计算核中复用专家权重分块 |
| `test(sim): cover uneven expert loads` | 补充专家负载不均的仿真用例 |
| `docs: document the board bring-up procedure` | 更新板卡调试文档，省略影响范围 |

如果修改了主机程序依赖的寄存器映射，可在标题中用 `!` 标记不兼容变更，并用 `BREAKING CHANGE:` 说明如何迁移。正文和尾注前各留一空行。

```text
feat(host)!: update DMA register map

Move the control register to make room for per-queue status registers.

BREAKING CHANGE: Update the host driver to use the new register offsets.
```

### PR 审查、合并与回滚

1. 创建目标为 `main` 的 PR，写明改动目的、涉及模块、验证结果及关联 Issue。可先建 Draft PR 征求反馈。
2. RTL、HLS 或主机接口变更应附上与改动相符的验证记录，例如仿真、综合、时序检查或板上测试。记录使用的板卡、工具版本、命令及结果，并注明尚未执行的检查。
3. 审查意见处理完毕并通过已配置的必需检查后合并。常规 PR 推荐使用 **Squash and merge**，并检查压缩后的提交标题是否符合提交格式。合并后删除工作分支。
4. 如需回滚，基于 `main` 提交回滚 PR，保留问题、修复和回滚记录。

### FPGA 源文件与实验产物

- 用 Git 管理可复现构建所需的 RTL／HLS 源码、主机程序、约束文件、仿真用例、构建脚本和参数配置。
- Vivado／Vitis 缓存、临时构建目录、仿真波形及生成日志应排除在版本控制之外。需要共享的 bitstream、模型权重和大型数据可使用有相应访问控制的 Git LFS、Release 附件或团队制品存储。发布可复用的硬件制品时记录对应 commit、工具版本、板卡及构建参数。
- 不提交密钥、访问令牌、许可证文件或含凭据的本地配置。

### 参考规范

- [GitHub Flow](https://docs.github.com/en/get-started/using-github/github-flow)
- [GitHub 分支规则集](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [GitHub 大文件管理](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)
