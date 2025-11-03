#!/bin/bash
# PDF 생성 스크립트

echo "Signal Factory 통합 문서 PDF 생성 중..."

# 필요한 도구 설치 확인
if ! command -v pandoc &> /dev/null; then
    echo "Pandoc 설치 중..."
    sudo apt-get update && sudo apt-get install -y pandoc texlive-xetex texlive-fonts-recommended texlive-lang-korean
fi

# 모든 마크다운 파일을 하나로 합치기
cat > combined.md << 'COMBINED'
---
title: "Signal Factory - 상세 기획 문서"
author: "Signal Factory Team"
date: "2025-11-03"
geometry: margin=2cm
fontsize: 11pt
---

COMBINED

# 순서대로 문서 추가
for file in 00_overview.md 01_architecture_overview.md 02_data_pipeline.md 03_signal_generation.md 04_execution_engine.md 05_web_ui.md 06_mobile_app.md 07_security.md 08_deployment.md 09_api_specifications.md 10_data_models.md 11_tech_stack.md 12_user_workflows.md 13_business_model.md 14_roadmap.md; do
    if [ -f "$file" ]; then
        echo "" >> combined.md
        echo "\\newpage" >> combined.md
        echo "" >> combined.md
        cat "$file" >> combined.md
    fi
done

# PDF 생성
echo "PDF 생성 중..."
pandoc combined.md \
    -o signal_factory_planning_docs.pdf \
    --pdf-engine=xelatex \
    --toc \
    --toc-depth=2 \
    -V mainfont="NanumGothic" \
    -V documentclass=article \
    -V geometry:margin=2cm \
    --highlight-style=tango \
    2>/dev/null || {
        echo "PDF 생성 실패. Pandoc 없이 마크다운 파일만 사용하세요."
        echo "통합 마크다운 파일: combined.md"
    }

# 정리
if [ -f "signal_factory_planning_docs.pdf" ]; then
    echo "✅ PDF 생성 완료: signal_factory_planning_docs.pdf"
    rm combined.md
else
    echo "⚠️  PDF 생성 실패. 통합 마크다운 파일 사용: combined.md"
fi
