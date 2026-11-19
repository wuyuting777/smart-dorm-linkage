// common/store/Store.ets
// 智舍联动 —— Preferences 持久化封装
import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import type { Device, EnvState, ExecLog, Rule } from '../models/Models';

const PREF_NAME: string = 'smart_dorm_pref';
const KEY_RULES: string = 'rules';
const KEY_DEVICES: string = 'devices';
const KEY_ENV: string = 'env';
const KEY_ACMODE: string = 'acMode';
const KEY_LOGS: string = 'logs';

async function getPref(context: common.UIAbilityContext): Promise<preferences.Preferences> {
  return preferences.getPreferences(context, PREF_NAME);
}

/** 保存规则列表 */
export async function saveRules(context: common.UIAbilityContext, rules: Rule[]): Promise<void> {
  const pref: preferences.Preferences = await getPref(context);
  await pref.put(KEY_RULES, JSON.stringify(rules));
  await pref.flush();
}

/** 读取规则列表；无记录返回 null */
export async function loadRules(context: common.UIAbilityContext): Promise<Rule[] | null> {
  const pref: preferences.Preferences = await getPref(context);
  const raw: string = (await pref.get(KEY_RULES, '')) as string;
  if (!raw) {
    return null;
  }
  try {
    return JSON.parse(raw) as Rule[];
  } catch (e) {
    return null;
  }
}

/** 保存设备设置 */
export async function saveDevices(context: common.UIAbilityContext, devices: Device[]): Promise<void> {
  const pref: preferences.Preferences = await getPref(context);
  await pref.put(KEY_DEVICES, JSON.stringify(devices));
  await pref.flush();
}

/** 读取设备设置；无记录返回 null */
export async function loadDevices(context: common.UIAbilityContext): Promise<Device[] | null> {
  const pref: preferences.Preferences = await getPref(context);
  const raw: string = (await pref.get(KEY_DEVICES, '')) as string;
  if (!raw) {
    return null;
  }
  try {
    return JSON.parse(raw) as Device[];
  } catch (e) {
    return null;
  }
}

/** 保存环境快照 */
export async function saveEnv(context: common.UIAbilityContext, env: EnvState): Promise<void> {
  const pref: preferences.Preferences = await getPref(context);
  await pref.put(KEY_ENV, JSON.stringify(env));
  await pref.flush();
}

/** 读取环境快照；无记录返回 null */
export async function loadEnv(context: common.UIAbilityContext): Promise<EnvState | null> {
  const pref: preferences.Preferences = await getPref(context);
  const raw: string = (await pref.get(KEY_ENV, '')) as string;
  if (!raw) {
    return null;
  }
  try {
    return JSON.parse(raw) as EnvState;
  } catch (e) {
    return null;
  }
}

/** 保存空调模式 */
export async function saveAcMode(context: common.UIAbilityContext, mode: string): Promise<void> {
  const pref: preferences.Preferences = await getPref(context);
  await pref.put(KEY_ACMODE, mode);
  await pref.flush();
}

/** 读取空调模式；无记录返回 'off' */
export async function loadAcMode(context: common.UIAbilityContext): Promise<string> {
  const pref: preferences.Preferences = await getPref(context);
  return (await pref.get(KEY_ACMODE, 'off')) as string;
}

/** 追加执行日志（保留最近100条） */
export async function saveLogs(context: common.UIAbilityContext, logs: ExecLog[]): Promise<void> {
  const pref: preferences.Preferences = await getPref(context);
  const kept: ExecLog[] = logs.slice(-100);
  await pref.put(KEY_LOGS, JSON.stringify(kept));
  await pref.flush();
}

/** 读取执行日志；无记录返回空数组 */
export async function loadLogs(context: common.UIAbilityContext): Promise<ExecLog[]> {
  const pref: preferences.Preferences = await getPref(context);
  const raw: string = (await pref.get(KEY_LOGS, '')) as string;
  if (!raw) {
    return [];
  }
  try {
    return JSON.parse(raw) as ExecLog[];
  } catch (e) {
    return [];
  }
}

/** 清空执行日志 */
export async function clearLogs(context: common.UIAbilityContext): Promise<void> {
  const pref: preferences.Preferences = await getPref(context);
  await pref.delete(KEY_LOGS);
  await pref.flush();
}
