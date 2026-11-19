// ohosTest/ets/test/RuleEngine.test.ets
// 规则引擎 OnDevice 单元测试：正常 / 边界 / 异常（模拟器上运行，可引用 main 模块）
import { describe, it, expect } from '@ohos/hypium';
import { runRules, evaluateRule } from '../../../../src/main/ets/common/engine/RuleEngine';
import type { EngineResult, AppliedAction } from '../../../../src/main/ets/common/engine/RuleEngine';
import { defaultRules } from '../../../../src/main/ets/common/models/Models';
import type { EnvState, Rule, TriggerResult } from '../../../../src/main/ets/common/models/Models';

export default function ruleEngineTest() {
  describe('RuleEngineTest', () => {

    // 正常1：场景A 夏日午后，R1 高温制冷应触发
    it('T1_正常_高温在场触发R1', 0, () => {
      const env: EnvState = { temp: 33, light: 900, present: true, humidity: 65 };
      const res: EngineResult = runRules(defaultRules(), env, [], new Set<string>(), 'off');
      const r1: TriggerResult | undefined = res.fired.find((tr: TriggerResult): boolean => tr.rule.id === 'r1');
      expect(r1 !== undefined).assertTrue();
    });

    // 正常2：无人在场，R4 兜底应触发并全关
    it('T2_正常_无人触发R4兜底', 0, () => {
      const env: EnvState = { temp: 15, light: 20, present: false, humidity: 50 };
      const res: EngineResult = runRules(defaultRules(), env, [], new Set<string>(), 'off');
      const r4: TriggerResult | undefined = res.fired.find((tr: TriggerResult): boolean => tr.rule.id === 'r4');
      expect(r4 !== undefined).assertTrue();
    });

    // 边界1：临界值判定 —— 等于阈值按约定处理
    it('T3_边界_临界值判定', 0, () => {
      // temp=30 满足 >=30；light=100 不满足 <100；acMode=off 时 R5 不触发
      const env: EnvState = { temp: 30, light: 100, present: true, humidity: 40 };
      const res: EngineResult = runRules(defaultRules(), env, [], new Set<string>(), 'off');
      const firedIds: string[] = res.fired.map((tr: TriggerResult): string => tr.rule.id);
      expect(firedIds.indexOf('r1') >= 0).assertTrue();   // 30℃ 计入高温
      expect(firedIds.indexOf('r2') >= 0).assertFalse();  // 光照=100 不触发补光
      expect(firedIds.indexOf('r5') >= 0).assertFalse();  // 非制热/湿度=40 不触发加湿
    });

    // 边界2：停用规则不参与计算
    it('T4_边界_停用规则不触发', 0, () => {
      const rules: Rule[] = defaultRules();
      rules[0].enabled = false; // 停用 R1
      const env: EnvState = { temp: 33, light: 900, present: true, humidity: 65 };
      const res: EngineResult = runRules(rules, env, [], new Set<string>(), 'off');
      const r1: TriggerResult | undefined = res.fired.find((tr: TriggerResult): boolean => tr.rule.id === 'r1');
      expect(r1 === undefined).assertTrue();
    });

    // 异常1：非法/空输入下引擎不崩溃、不抛异常
    it('T5_异常_非法输入不崩溃', 0, () => {
      let crashed: boolean = false;
      try {
        const env: EnvState = { temp: Number.NaN, light: Number.NaN, present: true, humidity: Number.NaN };
        const res: EngineResult = runRules([], env, [], new Set<string>(), 'off');
        expect(res.fired.length === 0).assertTrue();
      } catch (e) {
        crashed = true;
      }
      expect(crashed).assertFalse();
    });

    // 异常2：手动锁定设备，规则动作被跳过
    it('T6_异常_锁定设备跳过', 0, () => {
      const env: EnvState = { temp: 33, light: 900, present: true, humidity: 65 };
      const locked: Set<string> = new Set<string>();
      locked.add('dev-ac'); // 锁定空调
      const res: EngineResult = runRules(defaultRules(), env, [], locked, 'off');
      const touchedAc: boolean = res.applied.some((a: AppliedAction): boolean => a.deviceId === 'dev-ac');
      expect(touchedAc).assertFalse();
    });

    // 正常3：evaluateRule 对停用规则返回 null
    it('T7_正常_停用规则evaluate返回null', 0, () => {
      const rules: Rule[] = defaultRules();
      rules[0].enabled = false;
      const env: EnvState = { temp: 33, light: 900, present: true, humidity: 65 };
      const result: TriggerResult | null = evaluateRule(rules[0], env, 'off');
      expect(result === null).assertTrue();
    });
  })
}
