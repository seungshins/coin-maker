# 기술 아키텍처

## 제안 스택

- Godot 4 계열 안정 버전 + typed GDScript, Windows x64, 2D 쿼터뷰(아이소메트릭 표현).
- 엔진은 공식 안정판 Godot 4.7.2로 고정했다. 현재 실행/테스트 범위는 [개발 환경](09-development-setup.md)을 따른다.
- 초기 Compatibility 렌더러, 논리 화면 1280×720, 창 크기 대응. 마우스 조준과 UI 좌표 변환을 함께 검증한다.
- 캐릭터는 CharacterBody2D, 공격 범위는 Area2D 또는 명시적 공간 쿼리, 표현은 AnimatedSprite2D와 AnimationPlayer.
- 정의 데이터는 JSON + 검증기, 장면은 `.tscn`, 스크립트는 `.gd`. 복잡한 범용 ECS 대신 작은 조합형 컴포넌트를 사용한다.
- 네트워크, 계정, 외부 DB 없이 실행. 개발 로그와 테스트 결과도 로컬에 저장한다.

Godot 선택은 2D 애니메이션·충돌·에디터·네이티브 저장을 한 도구에서 처리하기 위한 설계 판단이다. 브라우저 필수 조건이 생기면 별도 배포 ADR에서 재평가한다.

## 소스 경계

```text
game/
  src/
    domain/         # 엔진 장면과 독립적인 수치/스킬/경제 규칙
    application/    # 출격, 구매, 장착, 보상 정산 명령
    actors/         # 플레이어와 몹의 구성 컴포넌트
    combat/         # 투사체, 범위 충돌, AI, 상태효과
    presentation/   # 애니메이션, VFX, SFX, UI 연결
    infrastructure/ # 파일 저장, 데이터 로드, 마이그레이션
  scenes/           # 거점, 스테이지, 플레이어, 적, UI
  data/             # skills, supports, items, enemies, stages, loot
  assets/           # sprites, tiles, vfx, audio, ui
  tests/            # 계산/저장/전투 통합 검증
planning/
```

현재 실행 가능한 소형 전투 아레나와 순수 계산 모듈을 구현했다. 나머지 컴포넌트는 목표 설계이며 순차 구현한다.

## 핵심 컴포넌트

쿼터뷰 좌표/깊이 정렬, 직접 드롭, 골드 도박의 추가 책임은 [시점·획득 아키텍처](08-view-loot-gambling.md)에 정의한다. 카메라 회전과 실제 3D 지형은 초기 범위에서 제외한다.

레벨·능력치 추가 서비스와 저장 필드는 [성장 아키텍처 확장](07-progression-and-rules.md)에 정의한다. 기존 ProgressionService는 액트/항로 개방, ExperienceService는 캐릭터 경험치를 담당한다.

| 컴포넌트/서비스 | 책임 | 입력 → 출력 |
|---|---|---|
| InputController | 조작을 명령으로 변환 | 키/마우스 → 이동/공격/회피 |
| MovementComponent | 이동, 충돌, 회피 무적 구간 | 명령/시간 → 위치/행동 상태 |
| StatsResolver | 기본값·장비·버프 합성 | 정의/장착/상태 → 최종 능력치 |
| SkillCompiler | 주스킬과 보조의 호환/제한 계산 | 스킬 구성 → 실행용 SkillSpec |
| SkillRunner | 시전 선딜·발사·후딜·쿨다운 | SkillSpec/조준 → 공격 생성 |
| ProjectileSystem | 이동, 수명, 관통, 연쇄, 적중 이력 | 공격 → HitRequest |
| DamageResolver | 피해/치명타/방어 계산 | 공격 스냅샷/방어/RNG → HitResult |
| HealthComponent | 체력, 무적, 사망 1회 보장 | HitResult → 체력/사망 이벤트 |
| StatusComponent | 지속 피해, 둔화, 석화와 중첩 | 효과 → 시간별 상태 변화 |
| EnemyBrain | 추격·공격·후퇴/보스 패턴 | 주변 상태 → 이동/공격 명령 |
| LootService/GachaService | 보상과 확률 판정 | 풀/진행도/RNG → 인스턴스 |
| InventoryService | 장착·판매·중복·잠금 | 명령 → 변경된 인벤토리 |
| ProgressionService | 액트/항로/보스 개방 | 완료 기록 → 진행도 |
| SaveRepository | 검증·저장·복구·버전 이전 | DTO → 저장 성공/실패 |
| PresentationController | 판정 결과를 시청각 표현 | 이벤트 → 모션/VFX/SFX/UI |

의존 방향: UI/장면 → application → domain. 파일·엔진 API는 infrastructure/presentation 쪽에 둔다. 전역 싱글턴은 부팅, 씬 이동, 서비스 보관 정도로 제한한다. 이벤트는 직접 참조/타입을 정한 signal을 우선하고 모든 기능을 문자열 전역 버스에 연결하지 않는다.

## 전투 흐름과 계산

고정 물리 틱 60Hz에서 이동·쿨다운·적중을 처리하고 렌더링 프레임과 분리한다. 장착/버프 변경 시 능력치 캐시를 무효화하며 매 프레임 모든 옵션을 다시 읽지 않는다.

```text
AttackCommand → SkillRunner(선딜/발사 틱)
 → Projectile 또는 MeleeHitbox
 → HitRequest → DamageResolver → HealthComponent
 → DamageApplied / ActorDied
 → 표시·소리 / 보상 생성
```

공격 발사 시 공격 능력치를 스냅샷하고, 방어는 적중 시점에 읽는다. 화면의 애니메이션 프레임이 바뀌거나 낮은 FPS여도 발사/피해 횟수는 같아야 한다.

초기 속성은 물리·번개·냉기. 변환 피해와 복잡한 관통은 후속 범위다.

`원시 피해 = (기본 피해 + 고정 추가 피해) × (1 + increased 합계) × more 배율들의 곱 × 스킬 계수`

`적중 피해 = 원시 피해 × 치명타 배율 × 방어 배율`

- increased는 가산, more는 곱산. 표기와 내부 modifier 연산을 일치시킨다.
- 물리 방어 배율은 초기 `100/(100+방어력)`; 방어력은 0 이상. 속성은 `1-저항`, 기본 저항 범위 -50%~75%.
- 치명타는 명시된 RNG로 판정하며 확률 0~100% 제한. 피해는 마지막에만 소수 처리하고 최소 0.
- 예: (100+20)×(1+0.5)×1.4×1=252. 저항 25%라면 비치명타 189.
- 지속 피해는 초기 치명타 불가. 같은 상태 계열은 가장 강한 1개를 적용하고 지속시간만 갱신한다. 세부 출처 규칙을 테스트에 고정한다.
- 사망 플래그를 먼저 세워 같은 틱의 다중 적중으로 보상이 중복되지 않게 한다.
- 투사체는 이전 위치→새 위치 구간 검사로 빠른 이동의 충돌 누락을 방지한다. collision layer/mask로 지형·대상·공격을 구분한다.
- 같은 attack_id/target_id의 중복 적중 제한, 관통/연쇄 예산, 발동 깊이 제한을 적용한다.

## 데이터 계약

| 데이터 | 필수 필드 |
|---|---|
| SkillDefinition | id, family_id, rarity, tags, base_damage, cooldown, windup, projectile_spec, visual_id |
| SupportDefinition | id, family_id, rarity, required_tags, modifiers, effect_id |
| ItemDefinition | id, slot, rarity, base_stats, affix_pool_id, unique_effect_id? |
| ItemInstance | instance_id, definition_id, item_level, rolled_affixes, locked |
| EnemyDefinition | id, stats, brain_id, animation_set_id, loot_table_id |
| StageDefinition | id, act_id, scene_id, encounter_ids, boss_id, reward_table_id |
| LootTable | id, progression_requirement, rarity_weights, subpool_weights, entries |

modifier는 `{stat, operation, value, source_id}`로 표현한다. 고유 효과는 검증된 effect_id→코드 구현 레지스트리를 통해 호출한다. JSON 안의 임의 코드를 실행하지 않는다. ID는 영구 식별자로 사용하며 표시명과 분리한다. 로드 시 중복 ID, 없는 참조, 음수 가중치, 빈 풀, 잘못된 태그/수치 범위를 거부한다.

## 오프라인 저장

`user://saves/slot_01.json`, 이전 정상본 `.bak`, 임시 `.tmp`를 사용한다. 설정은 ConfigFile로 분리한다. 세이브에는 schema_version, content_version, revision, player_id, gold, inventory, owned_skills, loadout, progression, pity, RNG state, checkpoint, transaction 기록을 담는다. 임의의 장면 경로를 세이브에서 로드하지 않는다.

- 구매/가차: 메모리 복사본에 명령 적용 → 전체 DTO 검증 → tmp 쓰기/닫기 → 재읽기 검증 → 기존 정상본 백업 → 교체 → 성공을 UI에 통지. 플랫폼의 rename/replace 동작과 실패 시 복구는 실제 Windows 테스트로 확인한다.
- 골드 차감과 결과 아이템, RNG 진행, 천장 갱신은 같은 revision에 저장한다. 저장 실패 시 이전 상태를 유지한다.
- 보상은 run_id와 정산 ID로 한 번만 지급한다. 인벤토리 보상과 진행도 갱신도 같은 트랜잭션이다.
- 저장 시점: 구매, 장착, 보상 정산, 방 체크포인트, 정상 종료. 변경을 직렬화하고 저장 중 추가 명령은 큐 처리한다.
- 중간 저장은 방 단위다. 방 입장 시 캐릭터 체력/자원, 획득 대기 보상, 방 seed와 RNG 상태를 저장한다. 비정상 종료 시 해당 방 처음으로 돌아간다. 개별 투사체/적 애니메이션 프레임은 저장하지 않는다.
- 현재 방의 미정산 획득물은 체크포인트 복귀 시 되돌려 중복 수급을 막는다. 사망은 별도 패배 정산 후 거점으로 이동한다.
- 주 파일 실패 시 backup 검증/복구 안내. 둘 다 손상되면 원본을 보존하고 복구 불가 안내 후 새 슬롯 선택을 제공한다. 조용히 초기화하지 않는다.
- schema_version별 순차 마이그레이션, 이전 파일 보관. 알 수 없는 미래 버전은 덮어쓰지 않는다. 삭제된 콘텐츠는 ID 매핑/보상 정책으로 이전한다.
- JSON 숫자 정밀도 문제를 피하기 위해 큰 정수 RNG 상태와 식별자는 문자열로 저장한다. 골드는 안전한 정수 범위에서 검증한다.
- 체크섬은 우발적 손상 확인용이며 오프라인 변조 방지 장치로 간주하지 않는다. 백엔드 보안·클라우드 동기화는 범위 밖이다.

## 성능과 검증 목표

초기 부하 목표: 적 100, 투사체 200, 일시 VFX 100, 720p 60FPS. 기준 PC는 첫 프로파일링 때 CPU/GPU/RAM과 함께 고정한다. 아직 측정 결과가 아니다. 스트레스 장면에서 p95 프레임 시간 16.7ms 이내를 목표로 하고 렌더링/물리/스크립트를 구분해 측정한다. 병목 확인 후 풀링과 공간 분할을 적용한다. VFX와 피해 숫자는 예산 초과 시 생략 가능하나 실제 공격 판정은 생략하지 않는다.

## 공식 참고

- [Godot 2D 스프라이트 애니메이션](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html): 스프라이트 시트와 애니메이션 도구 검토.
- [Godot 저장 가이드](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html): FileAccess, user 경로, JSON 저장의 기초. 위 트랜잭션/복구 구조는 본 프로젝트의 추가 설계다.
