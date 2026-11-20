# 软件需求说明书 —— 智舍联动（SmartDorm Linkage）

> 鸿蒙高级应用开发工程师认证 · 期末大作业
> 选题：主题三「联动实验室」智能宿舍自动化规则编排 App
> 作者：wuyuting777（吴玉婷）  邮箱：1678427174@qq.com
> 仓库：https://github.com/wuyuting777/smart-dorm-linkage

## 1. 项目背景与选题

学生在宿舍中往往需要手动反复开关空调、台灯、风扇等设备。本应用面向"智能宿舍"场景，让用户自行编排"满足条件时自动执行设备动作"的联动规则，并在一个可调节的 Mock 环境中模拟运行、观察设备联动与执行日志，而不依赖真实硬件或云平台。

选题对应作业主题三要求：至少4类可控设备、至少3项可调模拟环境数据、至少4条规则（含1条双条件规则）、规则引擎按实际输入计算触发结果、记录触发条件/设备变化/执行顺序、冲突有明确优先级、至少2组场景模拟、持久化设备设置/规则/执行记录。本作品在达标基础上扩展为5类设备、4项环境数据、7条规则。

## 2. 用户与使用场景

- **目标用户**：希望体验/编排宿舍自动化规则的学生。
- **典型流程**：新建/修改规则 → 调节 Mock 环境（温度、光照、在场、湿度）→ 点击"运行联动"→ 观察设备状态变化与执行日志 → 发现冲突后调整规则或优先级 → 退出重启后规则与设置仍在。

## 3. 功能需求

### 3.1 功能清单（对照作业硬性指标）

| 编号 | 功能 | 说明 | 对应指标 |
|---|---|---|---|
| F1 | 规则管理 | 新增、查看、修改、启用/停用、删除规则（删除前弹确认框防误删） | ≥4条规则 |
| F2 | 双条件规则 | R1 由"高温+在场"两个条件共同决定 | 含1条双条件规则 |
| F3 | Mock 环境调节 | 调节温度℃、光照lux、在场、湿度% 4项数据 | ≥3项环境数据 |
| F4 | 设备面板 | 展示空调、台灯、窗帘、风扇、加湿器5类设备状态，可手动开关 | ≥4类设备 |
| F5 | 规则引擎计算 | 按实际环境输入判定触发规则，输出动作序列 | 规则引擎真实计算 |
| F6 | 冲突与优先级 | 多规则命中同一设备时按优先级判定，高优先级生效 | 冲突优先级处理 |
| F7 | 手动锁定 | 手动操作的设备锁定后规则不强行改动，解锁恢复 | 自动/手动并存 |
| F8 | 执行日志 | 记录时间、触发规则、命中条件、设备动作与执行顺序，可清空 | 记录触发/变化/顺序 |
| F9 | 场景演练 | 预置≥2组场景一键模拟，也可手动自定义 | ≥2组场景 |
| F10 | 数据持久化 | 规则、设备设置、环境快照、空调模式、执行记录均存 Preferences；杀进程重启可恢复 | 持久化+恢复 |
| F11 | 单元测试 | ≥6条自动化测试，覆盖正常/边界/异常 | 测试要求 |

### 3.2 规则定义（阈值默认可在界面编辑）

| 规则 | 触发条件 | 执行动作 | 优先级 | 默认启停 |
|---|---|---|---|---|
| R1 高温制冷 | 室温 ≥ 30℃ **且** 在场 | 空调切制冷26℃；关闭风扇 | 3 | 启用 |
| R2 暗光补光 | 光照 < 100lux **且** 在场 | 打开台灯 | 2 | 启用 |
| R3 低温制热 | 室温 < 16℃ | 关闭风扇；空调切换制热 | 2 | 启用 |
| R4 无人兜底 | 无人在场 | 关闭全部设备 | 4（兜底强制） | 启用 |
| R5 干燥加湿 | 空调处于制热状态 **且** 湿度 < 40% | 打开加湿器 | 1 | 启用 |
| R6 光照充足关灯 | 光照 ≥ 100lux | 关闭台灯（与R2成对） | 1 | 启用 |
| R7 湿度充足关加湿 | 湿度 ≥ 40% | 关闭加湿器（与R5成对） | 1 | 启用 |

**优先级与冲突规则**：优先级数值越大越高。引擎先收集所有触发规则，按优先级降序执行；高优先级动作先落地；当低优先级动作与已执行的高优先级动作冲突（如高优先级已关闭风扇，低优先级尝试打开风扇），该冲突动作被丢弃并在日志中注明冲突。R4 兜底优先级最高、最后强制执行。
**手动锁定**：设备 locked=true 时，规则引擎跳过对该设备的自动改写；用户在面板手动操作后可点"解锁"恢复自动管理。

### 3.3 预置场景

- **场景A 夏日午后**：温度33℃ / 光照900lux / 在场 / 湿度65% → 预期 R1 触发（空调制冷、关风扇），其余不触发。
- **场景B 深夜无人**：温度15℃ / 光照20lux / 无人 / 湿度50% → 预期 R4 兜底触发，全部设备关闭。
- **自定义**：用户可自由拖动滑块/开关构成任意环境输入并运行。

## 4. 模块划分

| 模块 | 职责 | 关键内容 |
|---|---|---|
| 页面层 pages | 规则管理页、环境模拟页、设备面板页、执行日志页（Tabs 主容器） | ArkUI 布局、交互、结果反馈 |
| 模型层 common/models | Rule / Device / EnvState / ExecLog 数据结构与枚举定义 | 类型与默认值 |
| 规则引擎层 common/engine | 条件匹配、规则触发判定、冲突仲裁、动作序列与日志生成 | 纯 ArkTS 函数，可独立单测 |
| 持久化层 common/store | Preferences 存规则/设备/环境快照/空调模式/执行日志 | 保存与重启恢复 |
| 状态管理 | 页面层 @State 管理本地状态，引擎纯函数与 UI 解耦 | 页面联动更新 |

## 5. 数据模型

| 对象 | 关键字段与类型 | 业务含义 | 存储方式 |
|---|---|---|---|
| Rule | id:string; name:string; conditions:Condition[]; logic:'AND'|'OR'; actions:RuleAction[]; priority:number; enabled:boolean | 一条联动规则 | Preferences(JSON数组) |
| Condition | type:'tempAbove'|'tempBelow'|'lightBelow'|'lightAbove'|'present'|'humidityBelow'|'humidityAbove'|'acHeating'; operator:'>='|'<'|'=='; value:number|boolean | 单个条件 | 随 Rule |
| RuleAction | deviceId:string; action:'on'|'off'|'setMode'; target?:number|string | 规则触发后的动作 | 随 Rule |
| Device | id:string; type:'ac'|'lamp'|'curtain'|'fan'|'humidifier'; name:string; on:boolean; locked:boolean; targetValue?:number | 一台可控设备 | Preferences(JSON数组) |
| EnvState | temp:number; light:number; present:boolean; humidity:number | 当前 Mock 环境快照 | Preferences |
| ExecLog | id:string; time:string; ruleName:string; conditionDesc:string; actions:string[]; order:number; conflict?:string | 一条执行记录 | Preferences(JSON数组) |

## 6. 接口设计（规则引擎核心，纯函数）

| 接口/方法 | 输入参数 | 返回值 | 异常/边界处理 |
|---|---|---|---|
| matchCondition(cond, env) | cond:Condition; env:EnvState | boolean | 条件类型未知时返回false，不抛异常 |
| evaluateRule(rule, env, devices) | rule:Rule; env:EnvState; devices:Device[] | TriggerResult \| null（触发或未触发） | 规则停用(enabled=false)直接返回null |
| resolveConflict(triggered, devices, lockedSet) | 触发规则集合; 设备表; 锁定设备id集合 | ExecAction[]（最终动作序列） | 锁定设备跳过；冲突动作丢弃并标注 |
| runRules(rules, env, devices, lockedSet) | rules:Rule[]; env:EnvState; devices:Device[]; lockedSet:Set\<string\> | { actions:ExecAction[]; logs:ExecLog[] } | 空规则列表返回空结果，不崩溃 |

## 7. 持久化设计

- **Preferences**：保存 rules 数组、devices 数组、最近一次 env 快照、空调模式与执行日志数组；应用启动时读取还原。
- **实现说明**：早期设计的 RDB 存执行记录，实现中统一改为轻量 Preferences 键值存储，与本报告、源码一致。
- **恢复验证**：运行联动产生数据 → 结束应用进程 → 重新打开，规则、设备设置与历史日志仍可读取。

## 8. 测试方案（≥6条，覆盖正常/边界/异常）

| 类别 | 用例 | Mock输入/前置 | 预期结果 |
|---|---|---|---|
| 正常 | T1 夏日午后 | temp=33,light=900,present=true,humidity=65 | R1触发，空调制冷、风扇关 |
| 正常 | T2 无人兜底 | present=false 任意温湿度 | R4触发，全部设备关闭 |
| 边界 | T3 临界值 | temp=30(≥30边界)、light=100(＜100边界)、humidity=40(＜40边界) | 等于临界值按约定阈值判定，不误触发/不漏触发 |
| 边界 | T4 停用规则 | 将某规则 enabled=false 后运行 | 该规则不参与计算、不触发 |
| 异常 | T5 非法输入 | 温度传 null/超范围/空串 | 引擎兜底处理，不崩溃、不写脏数据 |
| 异常 | T6 手动锁定 | 目标设备 locked=true，规则尝试改它 | 跳过该设备自动动作 |
| 正常(补) | T7 冲突优先级 | R1关风扇与低优先级开风扇竞争 | 高优先级R1生效，低优先级动作被丢弃 |

测试框架：@ohos/hypium，ohosTest 目录下 OnDevice Instrument Test（在设备侧运行，可引用 main 模块），对规则引擎纯函数直接断言。

## 9. 分工

独立完成：本人 wuyuting777 承担需求分析、架构设计、全部模块开发、单元测试、README、录屏与个人报告。

## 10. 验收标准

1. 应用可在 DevEco Studio 编译运行，4个页面可切换、交互有反馈。
2. 7条规则可增改启停删除；双条件R1、兜底R4、干燥R5、反向R6/R7行为正确。
3. 规则引擎对给定环境输入真实计算，日志含触发规则、条件、动作与顺序。
4. 冲突按优先级仲裁；手动锁定设备不被自动改写。
5. 规则、设备设置、环境快照、执行记录持久化，杀进程重启可恢复。
6. ≥6条自动化测试真实运行通过，覆盖正常/边界/异常。
7. 仓库含源码、README、截图、录屏，Commit 历史可核验。
