// common/engine/RuleEngine.ets
// 智舍联动 —— 规则引擎（纯函数，无 UI 依赖，可独立单元测试）

import { CondType, LogicOp } from '../models/Models';
import type { Condition, Device, EnvState, ExecLog, Rule, RuleAction, TriggerResult } from '../models/Models';

/** 空调模式 */
export type AcMode = 'off' | 'cool' | 'heating';

export interface AppliedAction {
  deviceId: string;
  action: 'on' | 'off' | 'setMode';
  target?: number | string;
  byRule: string;
  conflict?: string;
}

export interface EngineResult {
  fired: TriggerResult[];
  applied: AppliedAction[];
  logs: ExecLog[];
}

/** 判定单个条件是否成立 */
export function matchCondition(cond: Condition, env: EnvState, acMode: AcMode): boolean {
  switch (cond.type) {
    case CondType.TEMP_ABOVE:
      return env.temp >= (cond.value as number);
    case CondType.TEMP_BELOW:
      return env.temp < (cond.value as number);
    case CondType.LIGHT_BELOW:
      return env.light < (cond.value as number);
    case CondType.LIGHT_ABOVE:
      return env.light >= (cond.value as number);
    case CondType.PRESENT:
      return env.present === (cond.value as boolean);
    case CondType.HUMIDITY_BELOW:
      return env.humidity < (cond.value as number);
    case CondType.HUMIDITY_ABOVE:
      return env.humidity >= (cond.value as number);
    case CondType.AC_HEATING:
      return acMode === 'heating';
    default:
      return false;
  }
}

/** 生成条件的可读描述 */
export function conditionDesc(cond: Condition): string {
  switch (cond.type) {
    case CondType.TEMP_ABOVE:
      return `室温≥${cond.value}℃`;
    case CondType.TEMP_BELOW:
      return `室温<${cond.value}℃`;
    case CondType.LIGHT_BELOW:
      return `光照<${cond.value}lux`;
    case CondType.LIGHT_ABOVE:
      return `光照≥${cond.value}lux`;
    case CondType.PRESENT:
      return (cond.value as boolean) ? '在场' : '无人';
    case CondType.HUMIDITY_BELOW:
      return `湿度<${cond.value}%`;
    case CondType.HUMIDITY_ABOVE:
      return `湿度≥${cond.value}%`;
    case CondType.AC_HEATING:
      return '空调制热中';
    default:
      return '未知条件';
  }
}

/** 判定一条规则是否触发；停用规则直接不触发 */
export function evaluateRule(rule: Rule, env: EnvState, acMode: AcMode): TriggerResult | null {
  if (!rule.enabled) {
    return null;
  }
  const results: boolean[] = rule.conditions.map((c: Condition) => matchCondition(c, env, acMode));
  const hit: boolean = rule.logic === LogicOp.AND
    ? results.every((v: boolean) => v)
    : results.some((v: boolean) => v);
  if (!hit) {
    return null;
  }
  const desc: string = rule.conditions.map((c: Condition) => conditionDesc(c)).join(' 且 ');
  return { rule, conditionDesc: desc };
}

/** 动作的可读描述 */
export function actionDesc(action: RuleAction, devices: Device[]): string {
  const dev: Device | undefined = devices.find((d: Device) => d.id === action.deviceId);
  const name: string = dev ? dev.name : action.deviceId;
  switch (action.action) {
    case 'on':
      return `打开${name}`;
    case 'off':
      return `关闭${name}`;
    case 'setMode':
      return action.target === 'heating' ? `空调切制热` : `空调切制冷26℃`;
    default:
      return '未知动作';
  }
}

/**
 * 规则主入口：计算触发规则、按优先级仲裁冲突、产出动作与日志
 * @param rules 全部规则
 * @param env 当前环境
 * @param devices 设备表（用于查设备名）
 * @param lockedSet 手动锁定的设备 id 集合
 * @param acMode 当前空调模式
 */
export function runRules(rules: Rule[], env: EnvState, devices: Device[],
  lockedSet: Set<string>, acMode: AcMode): EngineResult {
  // 1. 收集触发规则
  const fired: TriggerResult[] = [];
  for (const r of rules) {
    const tr: TriggerResult | null = evaluateRule(r, env, acMode);
    if (tr) {
      fired.push(tr);
    }
  }
  // 2. 按优先级降序（优先级高的先定夺）
  fired.sort((a: TriggerResult, b: TriggerResult) => b.rule.priority - a.rule.priority);

  // 3. 冲突仲裁：每个设备只保留最终决策动作
  const decided: Map<string, AppliedAction> = new Map();
  const applied: AppliedAction[] = [];
  let order: number = 1;

  for (const tr of fired) {
    for (const act of tr.rule.actions) {
      // 锁定设备：规则不改写
      if (lockedSet.has(act.deviceId)) {
        continue;
      }
      const existing: AppliedAction | undefined = decided.get(act.deviceId);
      if (existing) {
        // 已有更高/同优先级决策 → 本条冲突丢弃
        const conflictItem: AppliedAction = {
          deviceId: act.deviceId,
          action: act.action,
          target: act.target,
          byRule: tr.rule.name,
          conflict: `与更高优先级规则冲突，动作被丢弃`
        };
        applied.push(conflictItem);
        continue;
      }
      const item: AppliedAction = {
        deviceId: act.deviceId,
        action: act.action,
        target: act.target,
        byRule: tr.rule.name
      };
      decided.set(act.deviceId, item);
      applied.push(item);
    }
  }

  // 4. 生成日志（每个触发规则一条）
  const logs: ExecLog[] = fired.map((tr: TriggerResult): ExecLog => {
    const log: ExecLog = {
      id: `log-${Date.now()}-${order}`,
      time: new Date().toLocaleString(),
      ruleName: tr.rule.name,
      conditionDesc: tr.conditionDesc,
      actions: tr.rule.actions.map((a: RuleAction) => actionDesc(a, devices)),
      order: order++
    };
    return log;
  });

  return { fired, applied, logs };
}
