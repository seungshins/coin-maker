# coin-maker

## 개발 시작

현재 작업 폴더: `E:\workspace\coin-maker`. 도구는 저장소 밖 `E:\workspace\.tools`에 보관합니다.

```powershell
cd E:\workspace\coin-maker
.\tools\dev.ps1 editor # Godot 편집기
.\tools\dev.ps1 play   # 게임 실행
.\tools\dev.ps1 test   # 계산/좌표/충돌 테스트
.\tools\git.ps1 status
.\tools\publish.ps1    # GitHub 장치 로그인 후 main 업로드
```

다른 PC에서는 Godot 4.7.2 일반판으로 `game/project.godot`를 열면 됩니다. 개발 스크립트는 위 도구 폴더 구성을 전제로 합니다. 개발 실행 데이터는 `.runtime`에 보관되며 엔진 바이너리와 함께 GitHub에 포함하지 않습니다.

오디세우스의 귀향과 귀환 이후 끝없는 항해를 다루는 오프라인 싱글플레이 2D 핵앤슬래시.

## 디렉터리

- `game/`: Godot 4.7.2 전투 프로토타입, 데이터, 에셋, 테스트.
- `planning/`: 게임 규칙, 경제, 기술 아키텍처, 에셋 및 개발 계획.

## 기획 문서

1. [게임 기획](planning/01-game-design.md)
2. [희귀도와 경제](planning/02-rarity-economy.md)
3. [기술 아키텍처](planning/03-technical-architecture.md)
4. [에셋과 애니메이션](planning/04-assets-animation.md)
5. [개발 단계와 검증](planning/05-roadmap.md)
6. [오프닝·엔딩 연출과 대사](planning/06-story-sequences.md)
7. [레벨·능력치와 추가 규칙](planning/07-progression-and-rules.md)
8. [쿼터뷰·직접 드롭·골드 도박](planning/08-view-loot-gambling.md)
9. [개발 환경과 구현 상태](planning/09-development-setup.md)

2026-09-10 기획 v0.2. 수치와 엔진 선택은 구현 출발점이며 플레이테스트 전 확정 밸런스가 아닙니다.
