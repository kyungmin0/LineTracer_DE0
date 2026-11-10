# LineTracer_DE0

# DE0 FPGA 기반 Line Tracer

## 1. Project Overview

DE0 FPGA 보드를 활용하여 VHDL로 제어하는 라인트레이서를 제작한 프로젝트입니다.

8개의 적외선 센서를 이용하여 검은색 라인을 인식하고, 센서별 가중치(Weighted Control)를 기반으로 좌우 DC 모터의 속도를 조절하여 주행하도록 구현했습니다.

또한 FSM(Finite State Machine)을 활용하여 직선 및 곡선 주행, 정지, 회전, 경로 선택 등의 동작을 구현했으며, 7-Segment를 통해 주행 시간을 표시하도록 설계했습니다.

- **Project:** Line Tracer
- **Platform:** DE0 FPGA Board
- **HDL:** VHDL
- **Control Method:** Weighted Sensor Control, PWM, FSM

## 2. Main Features

- **Line Detection:** 8개의 적외선 센서를 활용한 검은색 라인 인식
- **Motor Control:** PWM을 이용한 좌우 DC 모터 속도 제어
- **Weighted Control:** 센서 위치별 가중치를 이용한 주행 방향 조절
- **FSM Control:** 상태 기반 주행 및 특수 구간 동작 구현
- **Direction Selection:** DE0 보드의 스위치를 이용한 분기 경로 선택
- **Lap Time Display:** 7-Segment를 이용한 주행 시간 표시
- **LED Indicator:** 센서 입력 상태를 LED로 시각화

## 3. Hardware Configuration

| Component | Description |
|---|---|
| DE0 FPGA Board | 전체 주행 제어 및 신호 처리 |
| IR Sensor (8-channel) | 검은색 라인 감지 |
| DC Motor | 좌우 바퀴 구동 |
| LM7805(Regulator) | 12V 입력을 5V로 변환 |
| TLP250(IC) | PWM 모터 구동 신호 전달 |
| Capacitor | 전원 안정화 |
| Transistor | 센서 신호 처리 |
| Variable Resistor | 센서 감도 조절 |

### Power Configuration

- 약 12V 전원을 시스템에 공급
- LM7805를 이용하여 센서 및 주변 회로에 필요한 5V 전원 생성
- 모터에는 12V 전원을 공급
- TLP250을 통해 DE0 보드의 PWM 신호를 모터 구동부에 전달

## 4. Software Architecture

전체 제어 시스템은 VHDL로 구현했으며, 하나의 `Line_Tracer` 설계 내부에서 센서 처리, 모터 제어, FSM 및 시간 표시 기능을 수행

### 4.1 Line Detection

8개의 적외선 센서로부터 입력을 받아 검은색 라인을 인식

- 센서 입력은 8-bit `in_bit`으로 전달
- 입력값이 `'0'`인 센서를 검은색 감지 상태로 처리
- 검은색을 감지한 센서의 개수를 계산하여 주행 상태 판단
- LED 출력을 통해 센서 인식 상태 확인

### 4.2 Weighted Sensor Control

센서의 위치에 따라 서로 다른 가중치를 부여하고, 검은색 라인을 감지한 센서의 가중치를 합산하여 좌우 모터의 속도를 제어

```vhdl
constant WEIGHT : weight_array_t :=
    (12000, 6000, 3000, 1500,
     -1500, -3000, -6000, -12000);

constant speed_standard : integer := 15000;
```

좌우 모터의 속도는 다음과 같이 계산합니다.

$$
V_L = V_{standard} + V_{add} + W
$$

$$
V_R = V_{standard} + V_{add} - W
$$

- $V_L$: 왼쪽 모터 속도 제어값
- $V_R$: 오른쪽 모터 속도 제어값
- $V_{standard}$: 기본 주행 속도
- $V_{add}$: 추가 속도 보정값
- $W$: 검은색을 감지한 센서 가중치의 합

중앙 센서가 라인을 감지하면 좌우 모터의 속도 차이가 작아지고, 가장자리 센서가 라인을 감지하면 속도 차이가 커지도록 설계했습니다.

### 4.3 PWM Motor Control

DE0 보드의 클럭을 기준으로 카운터를 증가시키고, 카운터와 각 모터의 속도 제어값을 비교하여 PWM 신호를 생성합니다.

- 기본 클럭: 50MHz
- PWM 카운터 주기: 50,000 클럭
- PWM 주기: 약 1ms
- 기본 주행 속도 제어값: 15,000
- 기본 PWM 듀티비: 약 30%

좌우 모터에 서로 다른 PWM 신호를 출력하여 라인트레이서의 방향과 속도를 제어합니다.

### 4.4 Finite State Machine (FSM)

총 13개의 상태(`Mr`, `M0` ~ `M11`)를 이용하여 주행 상황에 따른 동작을 제어합니다.

| State | Function |
|---|---|
| Mr | 대기 및 STOP 표시 |
| M0 | 기본 주행 및 출발 구간 |
| M1 | LED 점등 및 주행 속도 증가 |
| M2 | 기본 주행 및 곡선 구간 |
| M3 | 3초 정지 후 주행 재개 |
| M4 | 추가 속도 보정 및 가속 |
| M5 | 감속 및 직각 구간 진입 |
| M6 | 직각 구간 회전 |
| M7 | 직각 구간 이후 다음 상태 전환 |
| M8 | 스위치 설정에 따른 좌회전 또는 우회전 |
| M9 | 기본 주행 및 마지막 구간 |
| M10 | 주행 완료 및 정지 |
| M11 | FIN 표시 및 초기화 대기 |

FSM은 센서 감지 개수, 센서별 입력 조합, 시간 조건 및 보드 스위치 입력을 기반으로 다음 상태를 결정합니다.

### 4.5 Lap Time Display

DE0 보드의 4개 7-Segment를 활용하여 주행 시간을 표시합니다.

- 50MHz 클럭 기반 카운터 사용
- 0.01초 단위로 시간 갱신
- 4개의 7-Segment를 통해 경과 시간 표시
- 주행 시작 시 시간 초기화
- 주행 완료 시 정지 및 FIN 표시

## 5. Input / Output

| Type | Signal | Description |
|---|---|---|
| Input | `in_bit(0 to 7)` | 8개 센서 입력 |
| Input | `clk` | 시스템 클럭 |
| Input | `sw0` | 주행 시작 및 완료 제어 |
| Input | `sw9` | 분기 경로 선택 |
| Input | `sw1` | 완료 상태에서 초기화 |
| Output | `LED(0 to 7)` | 센서 상태 표시 |
| Output | `seg0 ~ seg3` | 7-Segment 출력 |
| Output | `Motor_L` | 왼쪽 모터 PWM 출력 |
| Output | `Motor_R` | 오른쪽 모터 PWM 출력 |

## 6. Repository Structure

```text
DE0-Line-Tracer/
├── README.md
├── src/
│   └── LineTracer.vhd
└── images/
    ├── MAP.jpg
    ├── Pin_Planner.jpg
    ├── robot1.jpg
    ├── Robot2.jpg
    └── Robot3.jpg
```

## 7. Results

본 프로젝트에서는 센서 입력을 기반으로 라인 추종 및 구간별 주행 동작을 구현했습니다.

- 8개 센서를 활용한 라인 인식
- 가중치 기반 좌우 모터 속도 조절
- PWM 기반 모터 구동
- FSM 기반 직각 회전 및 분기 경로 선택
- 7-Segment 기반 주행 시간 표시

## 8. Development Environment

- FPGA Board: DE0
- Hardware Description Language: VHDL
- FPGA Design Tool: Quartus 13.1
- Clock Frequency: 50MHz

