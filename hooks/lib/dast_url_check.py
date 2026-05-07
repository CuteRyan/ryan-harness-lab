# -*- coding: utf-8 -*-
"""
DAST URL 차단 검사 helper — production URL/도메인 매칭 공통 사용.

호출 위치:
- pretooluse-dast-prod-guard.py (WebFetch 검사)
- pretooluse-dast-prod-guard-bash.py (Bash 명령 URL 추출 후 검사)

근거:
- 본 프로젝트 Day 21 turn 2 #028 (d) — Bash matcher 확장 시 R-22 helper 추출.
  코드 중복 제거 + 단일 SSOT (PRODUCTION/EXCLUDE 패턴 양 hook 공유).
"""

import re

# GAP-A 정합 (.kr TLD 추가)
PRODUCTION_PATTERNS = [
    re.compile(r"^https?://api\.[\w-]+\.(com|io|net|co\.kr)/"),
    re.compile(r"^https?://prod\."),
    re.compile(r"^https?://www\."),
    re.compile(r"^https?://([\w-]+)\.(com|io|net|co\.kr|org)/"),
    re.compile(r"^https?://[\w.-]+\.kr/"),
]

# GAP-B 정합 (R-19 dast-analyzer 외부 리서치 도메인)
EXCLUDE_PATTERNS = [
    re.compile(r"(staging|stage|dev|test|qa|uat|preview|preprod)\."),
    re.compile(r"\.(internal|local|test|localhost)"),
    re.compile(r"^https?://(127\.0\.0\.1|localhost|0\.0\.0\.0)"),
    re.compile(r"^https?://10\.|^https?://172\.(1[6-9]|2\d|3[01])\.|^https?://192\.168\."),
    re.compile(r"portswigger\.net"),
    re.compile(r"owasp\.org"),
    re.compile(r"cve\.mitre\.org"),
    re.compile(r"nvd\.nist\.gov"),
    re.compile(r"zaproxy\.org"),
]


def check_url(url):
    """URL 차단 검사.

    Args:
        url: 검사 대상 URL (https?:// 시작 권장).

    Returns:
        (blocked, matched_pattern, exclude_matched):
        - blocked=True: production 매칭 + exclude 미매칭 → 차단 권고
        - blocked=False: exclude 매칭 OR production 미매칭 → 통과 (보수적 디폴트)
        - matched_pattern: 매칭된 production pattern 문자열 또는 None
        - exclude_matched: exclude 우선 매칭 시 pattern 문자열 또는 None
    """
    if not url:
        return False, None, None

    # exclude_patterns 우선 평가 (allowlist)
    for pat in EXCLUDE_PATTERNS:
        if pat.search(url):
            return False, None, pat.pattern

    # production_patterns 매칭
    for pat in PRODUCTION_PATTERNS:
        if pat.search(url):
            return True, pat.pattern, None

    # 매칭 X = 통과 (보수적 디폴트)
    return False, None, None
