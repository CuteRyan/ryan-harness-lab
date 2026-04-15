#!/bin/bash
# Streamlit 자동 실행 훅 (글로벌)
# — 웹 개발 프로젝트(Streamlit/Flask 등)에서 세션 시작 시 자동 실행
# — 이미 실행 중이면 즉시 리턴 (0.01초), 아닐 때만 시작

# 진입점 탐색: .streamlit-entry > 관례적 파일명 (루트 → 하위 1단계)
ENTRY=""

# 1순위: .streamlit-entry 파일에 명시된 경로
if [ -f "${PWD}/.streamlit-entry" ]; then
    CANDIDATE=$(cat "${PWD}/.streamlit-entry" | tr -d '[:space:]')
    if [ -f "${PWD}/${CANDIDATE}" ] && grep -q "streamlit" "${PWD}/${CANDIDATE}" 2>/dev/null; then
        ENTRY="${PWD}/${CANDIDATE}"
    fi
fi

# 2순위: 관례적 파일명 자동 탐색 (루트 → 하위 1단계)
if [ -z "$ENTRY" ]; then
    for NAME in app.py dashboard.py main.py; do
        # 루트 먼저
        if [ -f "${PWD}/${NAME}" ] && grep -q "streamlit" "${PWD}/${NAME}" 2>/dev/null; then
            ENTRY="${PWD}/${NAME}"
            break
        fi
        # 하위 1단계 디렉토리
        for DIR in "${PWD}"/*/; do
            if [ -f "${DIR}${NAME}" ] && grep -q "streamlit" "${DIR}${NAME}" 2>/dev/null; then
                ENTRY="${DIR}${NAME}"
                break 2
            fi
        done
    done
fi

# Streamlit 프로젝트가 아니면 즉시 종료
if [ -z "$ENTRY" ]; then
    exit 0
fi

# 포트 설정: 프로젝트별 .streamlit-port 파일이 있으면 그 포트, 없으면 8501
PORT_FILE="${PWD}/.streamlit-port"
if [ -f "$PORT_FILE" ]; then
    PORT=$(cat "$PORT_FILE" | tr -d '[:space:]')
else
    PORT=8501
fi

# 이미 실행 중이면 즉시 리턴
if curl -s -o /dev/null --connect-timeout 1 "http://localhost:${PORT}/_stcore/health" 2>/dev/null; then
    exit 0
fi

# venv 경로 탐색 (Windows/Linux 호환)
# 진입점이 하위 폴더에 있을 수 있으므로 진입점 디렉토리 + 프로젝트 루트 모두 탐색
ENTRY_DIR=$(dirname "$ENTRY")
STREAMLIT=""
for BASE in "$ENTRY_DIR" "$PWD"; do
    for VENV in venv .venv; do
        for BIN in Scripts/streamlit bin/streamlit; do
            if [ -f "${BASE}/${VENV}/${BIN}" ]; then
                STREAMLIT="${BASE}/${VENV}/${BIN}"
                break 3
            fi
        done
    done
done

if [ -z "$STREAMLIT" ]; then
    exit 0  # streamlit 미설치 — 건너뜀
fi

# 백그라운드 실행
nohup "$STREAMLIT" run "$ENTRY" --server.port "$PORT" > /dev/null 2>&1 &
echo "✅ Streamlit 자동 시작: $(basename "$ENTRY") (포트 ${PORT})"
