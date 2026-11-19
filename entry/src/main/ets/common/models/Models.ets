// common/models/Models.ets
// 智舍联动 —— 数据模型定义与默认数据工厂

/** 设备类型 */
export enum DeviceType {
  AC = 'ac',
  LAMP = 'lamp',
  CURTAIN = 'curtain',
  FAN = 'fan',
  HUMIDIFIER = 'humidifier'
}

/** 条件类型 */
export enum CondType {
  TEMP_ABOVE = 'tempAbove',      // 室温 ≥ 阈值
  TEMP_BELOW = 'tempBelow',       // 室温 < 阈值
  LIGHT_BELOW = 'lightBelow',     // 光照 < 阈值
  PRESENT = 'present',            // 人体在场判定
  HUMIDITY_BELOW = 'humidityBelow', // 湿度 < 阈值
  AC_HEATING = 'acHeating'        // 空调处于制热状态
}

/** 多条件组合逻辑 */
export enum LogicOp {
  AND = 'AND',
  OR = 'OR'
}

/** 单个条件 */
export interface Condition {
  type: CondType;
  operator: '>=' | '<' | '==' | '!=';
  value: number | boolean;
}

/** 规则触发后的设备动作 */
export interface RuleAction {
  deviceId: string;
  action: 'on' | 'off' | 'setMode';
  target?: number | string;
}

/** 一条联动规则 */
export interface Rule {
  id: string;
  name: string;
  conditions: Condition[];
  logic: LogicOp;
  actions: RuleAction[];
  priority: number;   // 数值越大优先级越高
  enabled: boolean;   // 是否启用
}

/** 一台可控设备 */
export interface Device {
  id: string;
  type: DeviceType;
  name: string;
  on: boolean;
  locked: boolean;      // 手动锁定后规则不改写
  targetValue?: number;
}

/** Mock 环境快照 */
export interface EnvState {
  temp: number;      // 室温 ℃
  light: number;     // 光照 lux
  present: boolean;  // 是否在场
  humidity: number;  // 湿度 %
}

/** 一条执行日志 */
export interface ExecLog {
  id: string;
  time: string;
  ruleName: string;
  conditionDesc: string;
  actions: string[];
  order: number;
  conflict?: string;
}

/** 规则触发结果（引擎内部使用） */
export interface TriggerResult {
  rule: Rule;
  conditionDesc: string;
}

/** 默认设备清单 */
export function defaultDevices(): Device[] {
  return [
    { id: 'dev-ac', type: DeviceType.AC, name: '空调', on: false, locked: false, targetValue: 26 },
    { id: 'dev-lamp', type: DeviceType.LAMP, name: '台灯', on: false, locked: false },
    { id: 'dev-curtain', type: DeviceType.CURTAIN, name: '窗帘', on: false, locked: false },
    { id: 'dev-fan', type: DeviceType.FAN, name: '风扇', on: false, locked: false },
    { id: 'dev-humidifier', type: DeviceType.HUMIDIFIER, name: '加湿器', on: false, locked: false }
  ];
}

/** 默认规则清单（阈值为默认值，界面可编辑） */
export function defaultRules(): Rule[] {
  return [
    {
      id: 'r1',
      name: 'R1 高温制冷',
      conditions: [
        { type: CondType.TEMP_ABOVE, operator: '>=', value: 30 },
        { type: CondType.PRESENT, operator: '==', value: true }
      ],
      logic: LogicOp.AND,
      actions: [
        { deviceId: 'dev-ac', action: 'setMode', target: 'cool26' },
        { deviceId: 'dev-fan', action: 'off' }
      ],
      priority: 3,
      enabled: true
    },
    {
      id: 'r2',
      name: 'R2 暗光补光',
      conditions: [
        { type: CondType.LIGHT_BELOW, operator: '<', value: 100 },
        { type: CondType.PRESENT, operator: '==', value: true }
      ],
      logic: LogicOp.AND,
      actions: [
        { deviceId: 'dev-lamp', action: 'on' }
      ],
      priority: 2,
      enabled: true
    },
    {
      id: 'r3',
      name: 'R3 低温制热',
      conditions: [
        { type: CondType.TEMP_BELOW, operator: '<', value: 16 }
      ],
      logic: LogicOp.AND,
      actions: [
        { deviceId: 'dev-fan', action: 'off' },
        { deviceId: 'dev-ac', action: 'setMode', target: 'heating' }
      ],
      priority: 2,
      enabled: true
    },
    {
      id: 'r4',
      name: 'R4 无人兜底',
      conditions: [
        { type: CondType.PRESENT, operator: '==', value: false }
      ],
      logic: LogicOp.AND,
      actions: [
        { deviceId: 'dev-ac', action: 'off' },
        { deviceId: 'dev-lamp', action: 'off' },
        { deviceId: 'dev-curtain', action: 'off' },
        { deviceId: 'dev-fan', action: 'off' },
        { deviceId: 'dev-humidifier', action: 'off' }
      ],
      priority: 4,
      enabled: true
    },
    {
      id: 'r5',
      name: 'R5 干燥加湿',
      conditions: [
        { type: CondType.AC_HEATING, operator: '==', value: true },
        { type: CondType.HUMIDITY_BELOW, operator: '<', value: 40 }
      ],
      logic: LogicOp.AND,
      actions: [
        { deviceId: 'dev-humidifier', action: 'on' }
      ],
      priority: 1,
      enabled: true
    }
  ];
}

/** 默认环境快照 */
export function defaultEnv(): EnvState {
  return { temp: 24, light: 500, present: true, humidity: 55 };
}
