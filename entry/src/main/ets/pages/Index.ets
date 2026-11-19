// pages/Index.ets
// 智舍联动主界面：环境调节 / 设备面板 / 规则列表 / 执行日志
import { defaultDevices, defaultEnv, defaultRules, CondType, LogicOp } from '../common/models/Models';
import type { Device, EnvState, ExecLog, Rule } from '../common/models/Models';
import { runRules } from '../common/engine/RuleEngine';
import type { AcMode } from '../common/engine/RuleEngine';
import { common } from '@kit.AbilityKit';
import { saveRules, saveDevices, saveEnv, saveAcMode, saveLogs, loadRules, loadDevices, loadEnv, loadAcMode, loadLogs, clearLogs } from '../common/store/Store';

@Entry
@Component
struct Index {
  @State rules: Rule[] = defaultRules();
  @State devices: Device[] = defaultDevices();
  @State env: EnvState = defaultEnv();
  @State acMode: AcMode = 'off';
  @State logs: ExecLog[] = [];
  @State currentTab: number = 1;
  // 规则新增/编辑表单
  @State showForm: boolean = false;
  @State editingId: string = '';
  @State fName: string = '';
  @State fCondLabel: string = '温度高于';
  @State fThreshold: string = '28';
  @State fDeviceLabel: string = '台灯';
  @State fActionOn: boolean = true;
  @State fPriority: string = '1';

  private getCtx(): common.UIAbilityContext {
    return this.getUIContext().getHostContext() as common.UIAbilityContext;
  }

  async aboutToAppear(): Promise<void> {
    const ctx: common.UIAbilityContext = this.getCtx();
    const savedRules: Rule[] | null = await loadRules(ctx);
    if (savedRules) {
      this.rules = savedRules;
    }
    const savedDevices: Device[] | null = await loadDevices(ctx);
    if (savedDevices) {
      this.devices = savedDevices;
    }
    const savedEnv: EnvState | null = await loadEnv(ctx);
    if (savedEnv) {
      this.env = savedEnv;
    }
    const savedMode: string = await loadAcMode(ctx);
    this.acMode = savedMode as AcMode;
    this.logs = await loadLogs(ctx);
  }

  private persist(): void {
    const ctx: common.UIAbilityContext = this.getCtx();
    saveRules(ctx, this.rules);
    saveDevices(ctx, this.devices);
    saveEnv(ctx, this.env);
    saveAcMode(ctx, this.acMode);
    saveLogs(ctx, this.logs);
  }

  /** 运行联动：规则引擎计算 + 应用动作 + 记录日志 */
  onRun(): void {
    const lockedSet: Set<string> = new Set<string>();
    this.devices.forEach((d: Device) => {
      if (d.locked) {
        lockedSet.add(d.id);
      }
    });
    const result = runRules(this.rules, this.env, this.devices, lockedSet, this.acMode);

    const updated: Device[] = this.devices.map((d: Device): Device => {
      return { id: d.id, type: d.type, name: d.name, on: d.on, locked: d.locked, targetValue: d.targetValue };
    });
    result.applied.forEach((act) => {
      const dev: Device | undefined = updated.find((d: Device) => d.id === act.deviceId);
      if (!dev || lockedSet.has(act.deviceId)) {
        return;
      }
      if (act.action === 'on') {
        dev.on = true;
      } else if (act.action === 'off') {
        dev.on = false;
      } else if (act.action === 'setMode') {
        dev.on = true;
        this.acMode = act.target === 'heating' ? 'heating' : 'cool';
      }
    });
    this.devices = updated;

    if (result.logs.length > 0) {
      this.logs = result.logs.concat(this.logs);
    }
    this.persist();
  }

  /** 手动切换设备：手动操作后锁定，规则不改写 */
  toggleDevice(id: string): void {
    const updated: Device[] = this.devices.map((d: Device): Device => {
      const nd: Device = { id: d.id, type: d.type, name: d.name, on: d.on, locked: d.locked, targetValue: d.targetValue };
      if (nd.id === id) {
        nd.on = !nd.on;
        nd.locked = true; // 手动接管，锁定
      }
      return nd;
    });
    this.devices = updated;
    this.persist();
  }

  /** 解锁设备，恢复规则自动管理 */
  unlockDevice(id: string): void {
    const updated: Device[] = this.devices.map((d: Device): Device => {
      const nd: Device = { id: d.id, type: d.type, name: d.name, on: d.on, locked: d.locked, targetValue: d.targetValue };
      if (nd.id === id) {
        nd.locked = false;
      }
      return nd;
    });
    this.devices = updated;
    this.persist();
  }

  /** 规则启停 */
  toggleRule(id: string): void {
    this.rules = this.rules.map((r: Rule): Rule => {
      const nr: Rule = { id: r.id, name: r.name, conditions: r.conditions, logic: r.logic, actions: r.actions, priority: r.priority, enabled: r.enabled };
      if (nr.id === id) {
        nr.enabled = !nr.enabled;
      }
      return nr;
    });
    this.persist();
  }

  private condLabelOf(t: CondType): string {
    if (t === CondType.TEMP_ABOVE) return '温度高于';
    if (t === CondType.TEMP_BELOW) return '温度低于';
    if (t === CondType.LIGHT_BELOW) return '光照低于';
    return '湿度低于';
  }

  private condTypeOfLabel(label: string): CondType {
    if (label === '温度高于') return CondType.TEMP_ABOVE;
    if (label === '温度低于') return CondType.TEMP_BELOW;
    if (label === '光照低于') return CondType.LIGHT_BELOW;
    return CondType.HUMIDITY_BELOW;
  }

  private deviceIdOfLabel(label: string): string {
    const d: Device | undefined = this.devices.find((x: Device) => x.name === label);
    return d ? d.id : 'dev-lamp';
  }

  private deviceLabelOfId(id: string): string {
    const d: Device | undefined = this.devices.find((x: Device) => x.id === id);
    return d ? d.name : '台灯';
  }

  openAddForm(): void {
    this.editingId = '';
    this.fName = '';
    this.fCondLabel = '温度高于';
    this.fThreshold = '28';
    this.fDeviceLabel = '台灯';
    this.fActionOn = true;
    this.fPriority = '1';
    this.showForm = true;
  }

  startEdit(r: Rule): void {
    this.editingId = r.id;
    this.fName = r.name;
    const c = r.conditions[0];
    if (c) {
      this.fCondLabel = this.condLabelOf(c.type);
      this.fThreshold = String(c.value);
    }
    const a = r.actions[0];
    if (a) {
      this.fDeviceLabel = this.deviceLabelOfId(a.deviceId);
      this.fActionOn = a.action === 'on';
    }
    this.fPriority = String(r.priority);
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
    this.editingId = '';
  }

  saveForm(): void {
    const threshold: number = Number(this.fThreshold);
    const cType: CondType = this.condTypeOfLabel(this.fCondLabel);
    const operator: '>=' | '<' = cType === CondType.TEMP_ABOVE ? '>=' : '<';
    const deviceId: string = this.deviceIdOfLabel(this.fDeviceLabel);
    const action: 'on' | 'off' = this.fActionOn ? 'on' : 'off';
    const priority: number = Number(this.fPriority) || 1;

    if (this.editingId === '') {
      const newRule: Rule = {
        id: `r-${Date.now()}`,
        name: this.fName || '自定义规则',
        conditions: [{ type: cType, operator: operator, value: threshold }],
        logic: LogicOp.AND,
        actions: [{ deviceId: deviceId, action: action }],
        priority: priority,
        enabled: true
      };
      this.rules = this.rules.concat([newRule]);
    } else {
      this.rules = this.rules.map((r: Rule): Rule => {
        if (r.id !== this.editingId) {
          return r;
        }
        return {
          id: r.id,
          name: this.fName || r.name,
          conditions: [{ type: cType, operator: operator, value: threshold }],
          logic: r.logic,
          actions: [{ deviceId: deviceId, action: action }],
          priority: priority,
          enabled: r.enabled
        };
      });
    }
    this.showForm = false;
    this.editingId = '';
    this.persist();
  }

  async clearAllLogs(): Promise<void> {
    this.logs = [];
    await clearLogs(this.getCtx());
  }

  private tabButton(idx: number): void {
    this.currentTab = idx;
  }

  @Builder
  tabBar() {
    Row({ space: 8 }) {
      ForEach(['环境', '设备', '规则', '日志'], (label: string, idx: number) => {
        Text(label)
          .fontSize(14)
          .fontColor(this.currentTab === idx ? '#FFFFFF' : '#333333')
          .backgroundColor(this.currentTab === idx ? '#2E6BE6' : '#E8ECF3')
          .borderRadius(14)
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .onClick(() => this.tabButton(idx))
      })
    }
    .margin({ top: 8, bottom: 8 })
  }

  @Builder
  envPanel() {
    Column({ space: 12 }) {
      Text('模拟环境调节').fontSize(16).fontWeight(FontWeight.Bold)
      Row() {
        Text(`室温：${this.env.temp.toFixed(0)}℃`).layoutWeight(1)
        Slider({ min: 0, max: 40, value: this.env.temp, step: 1 })
          .layoutWeight(2)
          .onChange((v: number) => {
            this.env.temp = v;
          })
      }
      Row() {
        Text(`光照：${this.env.light.toFixed(0)} lux`).layoutWeight(1)
        Slider({ min: 0, max: 1000, value: this.env.light, step: 10 })
          .layoutWeight(2)
          .onChange((v: number) => {
            this.env.light = v;
          })
      }
      Row() {
        Text(`湿度：${this.env.humidity.toFixed(0)}%`).layoutWeight(1)
        Slider({ min: 0, max: 100, value: this.env.humidity, step: 1 })
          .layoutWeight(2)
          .onChange((v: number) => {
            this.env.humidity = v;
          })
      }
      Row() {
        Text('人体在场').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.env.present })
          .onChange((isOn: boolean) => {
            this.env.present = isOn;
          })
      }
      Button('保存环境快照')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => this.persist())
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  devicePanel() {
    Column({ space: 10 }) {
      Text('设备面板').fontSize(16).fontWeight(FontWeight.Bold)
      ForEach(this.devices, (d: Device) => {
        Row() {
          Column() {
            Text(d.name).fontSize(16)
            Text(d.locked ? '已锁定（手动接管）' : (d.on ? '运行中' : '已关闭'))
              .fontSize(12)
              .fontColor(d.locked ? '#E67E22' : '#888888')
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          if (d.locked) {
            Button('解锁').fontSize(12).height(28)
              .onClick(() => this.unlockDevice(d.id))
          }
          Toggle({ type: ToggleType.Switch, isOn: d.on })
            .onChange(() => this.toggleDevice(d.id))
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F7FA')
        .borderRadius(10)
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  ruleForm() {
    Column({ space: 8 }) {
      Text(this.editingId === '' ? '新增规则' : '编辑规则').fontSize(15).fontWeight(FontWeight.Bold)
      TextInput({ placeholder: '规则名称', text: this.fName })
        .onChange((v: string) => { this.fName = v; })
      Row({ space: 8 }) {
        Text('条件').fontSize(13).layoutWeight(1)
        ForEach(['温度高于', '温度低于', '光照低于', '湿度低于'], (label: string) => {
          Text(label)
            .fontSize(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor(this.fCondLabel === label ? '#2E6BE6' : '#E8ECF3')
            .fontColor(this.fCondLabel === label ? '#FFFFFF' : '#333333')
            .onClick(() => { this.fCondLabel = label; })
        })
      }
      TextInput({ placeholder: '阈值（数字）', text: this.fThreshold })
        .type(InputType.Number)
        .onChange((v: string) => { this.fThreshold = v; })
      Row({ space: 8 }) {
        Text('动作设备').fontSize(13).layoutWeight(1)
        ForEach(['空调', '台灯', '窗帘', '风扇', '加湿器'], (label: string) => {
          Text(label)
            .fontSize(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor(this.fDeviceLabel === label ? '#2E6BE6' : '#E8ECF3')
            .fontColor(this.fDeviceLabel === label ? '#FFFFFF' : '#333333')
            .onClick(() => { this.fDeviceLabel = label; })
        })
      }
      Row({ space: 12 }) {
        Text('动作').fontSize(13).layoutWeight(1)
        Text('打开')
          .fontSize(12).padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(8)
          .backgroundColor(this.fActionOn ? '#2E6BE6' : '#E8ECF3')
          .fontColor(this.fActionOn ? '#FFFFFF' : '#333333')
          .onClick(() => { this.fActionOn = true; })
        Text('关闭')
          .fontSize(12).padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(8)
          .backgroundColor(!this.fActionOn ? '#2E6BE6' : '#E8ECF3')
          .fontColor(!this.fActionOn ? '#FFFFFF' : '#333333')
          .onClick(() => { this.fActionOn = false; })
      }
      TextInput({ placeholder: '优先级（数字，越大越高）', text: this.fPriority })
        .type(InputType.Number)
        .onChange((v: string) => { this.fPriority = v; })
      Row({ space: 12 }) {
        Button('保存').height(32).onClick(() => this.saveForm())
        Button('取消').height(32).backgroundColor('#999999').onClick(() => this.cancelForm())
      }
    }
    .padding(10)
    .backgroundColor('#F0F4FF')
    .borderRadius(10)
  }

  @Builder
  rulePanel() {
    Column({ space: 10 }) {
      Row() {
        Text('规则列表（开关启停，可编辑/新增）').fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('＋ 新增规则').fontSize(13).height(32).onClick(() => this.openAddForm())
      }
      if (this.showForm) {
        this.ruleForm()
      }
      ForEach(this.rules, (r: Rule) => {
        Column({ space: 4 }) {
          Row() {
            Text(r.name).fontSize(15).fontWeight(FontWeight.Bold).layoutWeight(1)
            Text('编辑').fontSize(12).fontColor('#2E6BE6').margin({ right: 8 })
              .onClick(() => this.startEdit(r))
            Toggle({ type: ToggleType.Switch, isOn: r.enabled })
              .onChange(() => this.toggleRule(r.id))
          }
          Text(`优先级 ${r.priority} ｜ 条件：${r.conditions.map((c) => `${c.type}${c.operator}${c.value}`).join(' 且 ')}`)
            .fontSize(12).fontColor('#666666')
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F7FA')
        .borderRadius(10)
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  logPanel() {
    Column({ space: 10 }) {
      Row() {
        Text('执行日志').fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('清空').fontSize(12).height(28).onClick(() => this.clearAllLogs())
      }
      if (this.logs.length === 0) {
        Text('暂无执行记录，点下方「运行联动」开始模拟').fontColor('#999999').fontSize(14)
      }
      ForEach(this.logs, (log: ExecLog) => {
        Column({ space: 2 }) {
          Text(`#${log.order} ${log.time} ｜ ${log.ruleName}`).fontSize(13).fontWeight(FontWeight.Bold)
          Text(`条件：${log.conditionDesc}`).fontSize(12).fontColor('#666666')
          Text(`动作：${log.actions.join('、')}`).fontSize(12).fontColor('#2E6BE6')
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#F5F7FA')
        .borderRadius(10)
      })
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  build() {
    Column() {
      Text('智舍联动 · 智能宿舍规则编排')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 16, bottom: 4 })
      Text('调节环境 → 运行联动 → 观察设备与日志').fontSize(13).fontColor('#888888')

      this.tabBar()

      Scroll() {
        Column({ space: 12 }) {
          if (this.currentTab === 0) {
            this.envPanel()
          } else if (this.currentTab === 1) {
            this.devicePanel()
          } else if (this.currentTab === 2) {
            this.rulePanel()
          } else {
            this.logPanel()
          }
        }.padding(12)
      }
      .layoutWeight(1)
      .align(Alignment.Top)

      Button('▶ 运行联动')
        .width('90%')
        .height(48)
        .fontSize(17)
        .backgroundColor('#2E6BE6')
        .margin({ bottom: 16 })
        .onClick(() => this.onRun())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F2F5')
    .padding({ left: 12, right: 12 })
  }
}
