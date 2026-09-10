# 게임 개발 폴더

Godot 4.7.2 일반판 + typed GDScript 기반 오프라인 Windows 쿼터뷰 전투 프로토타입입니다.

Godot에서 `project.godot`를 가져와 F6 대신 F5로 프로젝트를 실행합니다.
WASD 이동, 마우스 조준+좌클릭 발사, Space 회피, ESC 일시정지, R 재시작.

임시 도형 캐릭터, 쿼터뷰 바닥, 적 12마리 추격/피격/사망, 처치 골드를 구현했습니다.
저장·장비·젬·가차·도박·액트·최종 에셋은 아직 미구현입니다.
현재 아레나는 조작 검증용이며 최종 스테이지나 완성된 캐릭터 컴포넌트 구조가 아닙니다.

검증 명령(실행 파일 경로는 설치 위치에 맞게 변경):
```powershell
godot --headless --path . --script res://tests/test_combat.gd
godot --headless --path . --quit-after 120
```

아키텍처와 책임 분리는 [기술 기획](../planning/03-technical-architecture.md)을 참고합니다.
