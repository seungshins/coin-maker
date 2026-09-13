# v0.2.5 — 직접 생성할 에셋 프롬프트

현재 마을과 액트1은 Godot의 실제 3D 메시로 그립니다. 아래 이미지는 캐릭터/건물 모델링 참고도 또는 표면 텍스처입니다. PNG를 받는 것만으로 움직이는 3D 캐릭터가 완성되지는 않습니다. 캐릭터는 이후 GLB 모델과 리깅/걷기·공격 애니메이션이 필요합니다. 그때까지 코드로 만든 저해상도 3D 모델을 사용합니다.

우선순위는 **1번 주인공 참고도 → 2번 사티로스 참고도 → 3번 바닥 텍스처**입니다. 한 요청에 여러 에셋을 합치지 말고, 아래 코드 블록 하나씩 그대로 붙여 넣으세요. 4번 건물 참고도는 이후 선택 사항입니다. 새 그림이 마음에 들면 원본 PNG 그대로 전달해 주세요. 기존 게임 에셋을 덮어쓰지 않아도 됩니다.

## 1. 오디세우스 3D 제작용 참고도

권장 파일명: odysseus-turnaround.png. 가로 3:2 또는 가장 가까운 가로 비율, 가능한 최고 해상도.

~~~text
Create one professional orthographic character turnaround reference sheet for an original low-poly 3D action RPG hero inspired by the ancient Greek Odyssey. This is a modeling reference, NOT a game screenshot, cinematic painting, isometric sprite, or finished 3D file.

Character: a weathered Greek seafaring warrior in his early forties, athletic and practical proportions, short dark curly hair, short dark beard, olive skin. Bronze cuirass over a muted ivory linen tunic, short segmented leather skirt, dark red narrow shoulder cloth ending at the upper thigh, bronze greaves, worn leather sandals. A simple bronze helmet with a small dark-red crest. The silhouette must remain clear when the character occupies only 70 pixels in an overhead game. Large readable shapes, restrained details, matte materials, subtle wear only. Colors: warm bronze, terracotta red, ivory, dark brown. No jewelry clutter, no elaborate engravings, no glowing runes, no oversized fantasy shoulder armor, no modern clothing, no guns.

Layout: exactly THREE full-body views arranged left to right: front, strict left profile, back. Identical character, identical clothing and helmet in every view. Strict orthographic projection, zero perspective, all views at the same scale, feet on the same baseline, complete body from helmet crest to sandal soles visible with generous margins. Front and back use a relaxed A-pose: straight elbows, arms approximately 35 degrees away from the torso, palms inward, legs slightly apart. Profile view uses the corresponding pose and must clearly show equipment depth. Empty hands so the arms and hands can be modeled separately; no weapon or shield obscuring anatomy. Show the helmet consistently in all three views. Exactly one person per view, no extra faces or limbs.

Presentation: clean neutral medium-gray opaque background, evenly lit diffuse studio lighting, minimal contact shadow, no dramatic directional shadows, no depth of field. Stylized 3D model-like surfaces with simple planar forms, not photorealistic skin or painterly brushwork. No text, labels, letters, numbers, arrows, grid, watermark, logos, UI, frame or scenery. Deliver one clear high-resolution PNG image.
~~~

## 2. 사티로스 적 참고도

권장 파일명: satyr-turnaround.png. 1번과 같은 가로 비율.

~~~text
Create one clean orthographic turnaround reference sheet for an original Greek-mythology satyr enemy for the same stylized low-poly overhead action RPG. Exactly three aligned full-body views: front, strict left profile, back. Consistent anatomy and clothing, identical scale, feet aligned, neutral A-pose, empty hands, no perspective. This is a model-making reference, not an action illustration or sprite animation sheet.

Design: adult male satyr, lean muscular humanoid upper body, warm desaturated brown skin, two short curved goat horns emerging symmetrically from the forehead, short coarse dark hair, short pointed beard, pointed ears. Goat hind legs with visible hocks and dark split hooves, fur from the hips downward. Simple ragged muted green waist cloth and one leather shoulder strap. No human shoes. No armor covering the entire body. A hostile but readable face without exaggerated gore. The figure is about the same height as an ordinary human warrior. Distinctive horns, goat legs and hunched shoulders must identify the enemy at small screen sizes.

Use broad, simple low-poly forms, matte materials, subtle limited surface variation, muted earth palette. No photorealistic fur strands, no excessive accessories, no transparent magic, no particles. Same two horns and same leg structure in all views. Keep hands, elbows, hooves and horn tips fully inside the canvas with margins. Neutral opaque gray background, uniform diffuse studio lighting, minimal floor shadow. No scenery, weapon, text, labels, watermark, UI, grid or border. High-resolution PNG.
~~~

## 3. 액트1 해안 바닥 텍스처

권장 파일명: coast-ground-albedo.png. 정사각형 1:1. 이 이미지는 참고도가 아니라 실제 재질에 사용할 수 있습니다. 생성 후 타일 경계는 게임에서 별도 확인합니다.

~~~text
Generate a single seamless tileable BASE COLOR texture for a stylized low-poly 3D ancient Greek coastal action RPG. Square image, pure top-down orthographic surface view. The entire canvas is filled with the same continuous ground material, with no objects outside it and no empty margins.

Surface: compact warm beige coastal sand blended with dusty pale limestone grit. Mostly calm, broad color areas suitable beneath a small moving character. Very sparse tiny desaturated pebbles and subtle weathered mineral patches, distributed evenly with no central focal point. Palette: muted sand beige, pale ochre, soft gray limestone. Keep contrast low so enemies, loot and spell effects remain readable. No bright yellow or pure white areas, no dark black cracks, no large rocks.

CRITICAL: a flat albedo/base-color texture only. No baked directional lighting, no shadows, no ambient-occlusion halos, no specular highlights, no horizon, no perspective, no camera vignette. All four edges must wrap seamlessly. No footprints, roads, buildings, plants, shells, water, characters, text, labels, border, watermark, texture preview sphere or material chart. Do not include a normal map, roughness map or multiple panels. Output exactly one high-resolution square PNG, ideally 2048 by 2048 if supported.
~~~

## 4. 마을 모듈 건물 참고도 (선택)

권장 파일명: harbor-modules-reference.png. 가로 3:2.

~~~text
Create a clean architectural modeling reference sheet for three small modular structures for a stylized low-poly ancient Greek harbor village. This is a 3D asset concept reference, not an in-game background image.

Exactly three separate structures across a neutral medium-gray background, evenly spaced, fully visible, no overlap. Left: a simple Hermes market stall with four wooden posts, a muted terracotta fabric canopy, one plain wooden counter and two small crates. Middle: a small open marble shrine with four short Doric columns, a simple triangular pediment and two broad steps, no enclosed room. Right: a low wooden storage chest with bronze corner bands, next to one small mooring bollard. Consistent scale: market stall approximately 2.5 meters wide and 2.4 meters tall; shrine 3 meters wide and 2.8 meters tall; chest 1 meter wide.

Each structure shown in the same clean three-quarter orthographic view, no lens distortion, no dramatic perspective. Keep the construction understandable and easy to rebuild from boxes, cylinders and simple roof meshes. Thick readable silhouettes, few large pieces, matte warm wood, muted red cloth, cream limestone, restrained weathering. Light from upper left, soft minimal shadows, no excessive ornate detail, no vegetation covering structures, no gods or character statues. No people, no floor diorama, no ocean, no town panorama, no text, labels, dimensions, symbols, logos, UI, watermark or border. High-resolution PNG, generous margins.
~~~

## 모델 파일을 별도로 구할 경우

Godot에 넣을 최종 형식은 GLB/glTF2.0을 우선합니다. 캐릭터는 Y-up, 실제 크기 약1.7m, 발바닥 원점, 걷기·대기·공격 애니메이션, 몸과 무기를 분리할 수 있는 구조가 좋습니다. 상용/무료 모델은 배포 허용 라이선스도 함께 보관합니다. 이미지 생성만으로 이 조건을 충족한다고 가정하지 않습니다.
