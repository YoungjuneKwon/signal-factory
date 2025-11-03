# 웹 UI

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

웹 UI는 React 기반의 데스크톱 인터페이스로, 로직 관리, 포트폴리오 구성, 백테스팅, 실시간 모니터링을 제공합니다.

## 기술 스택

### 프론트엔드 프레임워크
- **React 18+**: 컴포넌트 기반 UI
- **TypeScript**: 타입 안전성
- **Vite**: 빠른 개발 서버 및 빌드
- **React Router**: 클라이언트 사이드 라우팅

### UI 라이브러리
- **Material-UI (MUI)**: 컴포넌트 라이브러리
- **Tailwind CSS**: 유틸리티 기반 스타일링
- **Emotion**: CSS-in-JS

### 상태 관리
- **Zustand**: 경량 상태 관리
- **React Query**: 서버 상태 관리 및 캐싱

### 차트 라이브러리
- **TradingView Lightweight Charts**: 금융 차트
- **Recharts**: 대시보드 차트
- **D3.js**: 커스텀 시각화

### 코드 에디터
- **Monaco Editor**: VS Code 에디터
- **CodeMirror**: 경량 대안

## 주요 화면

### 1. 대시보드

```typescript
// Dashboard.tsx
import { useQuery } from '@tanstack/react-query';
import { Grid, Card, CardContent, Typography } from '@mui/material';

function Dashboard() {
  const { data: summary } = useQuery({
    queryKey: ['dashboard-summary'],
    queryFn: async () => {
      const res = await fetch('/api/v1/dashboard/summary');
      return res.json();
    }
  });
  
  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="총 자산"
          value={formatCurrency(summary?.totalAssets)}
          change={summary?.assetChange}
        />
      </Grid>
      
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="오늘 수익률"
          value={formatPercent(summary?.todayReturn)}
          change={summary?.todayReturn}
        />
      </Grid>
      
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="활성 포트폴리오"
          value={summary?.activePortfolios}
        />
      </Grid>
      
      <Grid item xs={12} md={3}>
        <StatsCard 
          title="실행 중인 로직"
          value={summary?.runningLogics}
        />
      </Grid>
      
      <Grid item xs={12} md={8}>
        <EquityCurveChart />
      </Grid>
      
      <Grid item xs={12} md={4}>
        <RecentSignals />
      </Grid>
    </Grid>
  );
}
```

### 2. 로직 에디터

```typescript
// LogicEditor.tsx
import Editor from '@monaco-editor/react';
import { useState, useEffect } from 'react';

function LogicEditor({ logicId }: { logicId?: string }) {
  const [code, setCode] = useState('');
  const [errors, setErrors] = useState<any[]>([]);
  
  const handleEditorChange = (value: string | undefined) => {
    setCode(value || '');
    
    // 실시간 린트
    lintCode(value || '').then(setErrors);
  };
  
  const handleSave = async () => {
    const payload = {
      name: logicName,
      description: logicDescription,
      code,
      tags: selectedTags
    };
    
    if (logicId) {
      await api.updateLogic(logicId, payload);
    } else {
      await api.createLogic(payload);
    }
  };
  
  const handleTest = async () => {
    const result = await api.testLogic({
      code,
      input: sampleData
    });
    
    setTestResult(result);
  };
  
  return (
    <Box sx={{ height: '100vh', display: 'flex', flexDirection: 'column' }}>
      <EditorToolbar 
        onSave={handleSave}
        onTest={handleTest}
        errors={errors}
      />
      
      <Box sx={{ flex: 1, display: 'flex' }}>
        <Box sx={{ flex: 2 }}>
          <Editor
            height="100%"
            defaultLanguage="javascript"
            value={code}
            onChange={handleEditorChange}
            theme="vs-dark"
            options={{
              minimap: { enabled: true },
              fontSize: 14,
              automaticLayout: true
            }}
          />
        </Box>
        
        <Box sx={{ flex: 1, borderLeft: 1, borderColor: 'divider' }}>
          <Tabs value={sideTab} onChange={(_, v) => setSideTab(v)}>
            <Tab label="테스트" />
            <Tab label="문서" />
            <Tab label="예제" />
          </Tabs>
          
          {sideTab === 0 && <TestPanel result={testResult} />}
          {sideTab === 1 && <DocumentationPanel />}
          {sideTab === 2 && <ExamplesPanel />}
        </Box>
      </Box>
    </Box>
  );
}
```

### 3. 포트폴리오 관리

```typescript
// PortfolioBuilder.tsx
import { DndContext, closestCenter } from '@dnd-kit/core';
import { SortableContext } from '@dnd-kit/sortable';

function PortfolioBuilder() {
  const [selectedLogics, setSelectedLogics] = useState<Logic[]>([]);
  const [weights, setWeights] = useState<Record<string, number>>({});
  
  const handleAddLogic = (logic: Logic) => {
    setSelectedLogics([...selectedLogics, logic]);
    setWeights({ ...weights, [logic.id]: 1.0 });
  };
  
  const handleWeightChange = (logicId: string, weight: number) => {
    setWeights({ ...weights, [logicId]: weight });
  };
  
  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={4}>
        <LogicLibrary onSelect={handleAddLogic} />
      </Grid>
      
      <Grid item xs={12} md={8}>
        <Card>
          <CardHeader title="포트폴리오 구성" />
          <CardContent>
            <DndContext collisionDetection={closestCenter}>
              <SortableContext items={selectedLogics}>
                {selectedLogics.map(logic => (
                  <LogicCard
                    key={logic.id}
                    logic={logic}
                    weight={weights[logic.id]}
                    onWeightChange={(w) => handleWeightChange(logic.id, w)}
                  />
                ))}
              </SortableContext>
            </DndContext>
            
            <Divider sx={{ my: 2 }} />
            
            <StrategySelector 
              value={strategy}
              onChange={setStrategy}
            />
            
            <Button 
              variant="contained" 
              onClick={handleSavePortfolio}
              sx={{ mt: 2 }}
            >
              포트폴리오 저장
            </Button>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
}
```

### 4. 백테스트 결과

```typescript
// BacktestResults.tsx
import { LightweightChart } from 'lightweight-charts-react-wrapper';

function BacktestResults({ backtestId }: { backtestId: string }) {
  const { data } = useQuery({
    queryKey: ['backtest', backtestId],
    queryFn: () => api.getBacktestResults(backtestId)
  });
  
  return (
    <Box>
      <Grid container spacing={3}>
        {/* 성과 요약 */}
        <Grid item xs={12}>
          <PerformanceSummary
            totalReturn={data.summary.totalReturn}
            annualizedReturn={data.summary.annualizedReturn}
            sharpeRatio={data.summary.sharpeRatio}
            maxDrawdown={data.summary.maxDrawdown}
          />
        </Grid>
        
        {/* 자산 곡선 */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardHeader title="자산 곡선" />
            <CardContent>
              <EquityCurve data={data.timeline} />
            </CardContent>
          </Card>
        </Grid>
        
        {/* 월별 수익률 */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardHeader title="월별 수익률" />
            <CardContent>
              <MonthlyReturnsHeatmap data={data.monthlyReturns} />
            </CardContent>
          </Card>
        </Grid>
        
        {/* 거래 통계 */}
        <Grid item xs={12} md={6}>
          <TradeStatistics stats={data.trades} />
        </Grid>
        
        {/* 거래 내역 */}
        <Grid item xs={12} md={6}>
          <TradeHistory trades={data.trades.list} />
        </Grid>
      </Grid>
    </Box>
  );
}
```

### 5. 실시간 모니터링

```typescript
// RealtimeMonitoring.tsx
import { useWebSocket } from '@/hooks/useWebSocket';

function RealtimeMonitoring({ portfolioId }: { portfolioId: string }) {
  const { data: signals } = useWebSocket(`/ws/signals/${portfolioId}`);
  const { data: positions } = useQuery(['positions', portfolioId]);
  
  return (
    <Grid container spacing={3}>
      {/* 현재 포지션 */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="현재 포지션" />
          <CardContent>
            <PositionsTable positions={positions} />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 실시간 손익 */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="실시간 손익" />
          <CardContent>
            <PnLChart portfolioId={portfolioId} />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 최근 신호 */}
      <Grid item xs={12}>
        <Card>
          <CardHeader title="최근 신호" />
          <CardContent>
            <SignalsList signals={signals} />
          </CardContent>
        </Card>
      </Grid>
      
      {/* 실시간 차트 */}
      <Grid item xs={12}>
        <RealtimePriceChart 
          symbols={positions?.map(p => p.symbol)}
          signals={signals}
        />
      </Grid>
    </Grid>
  );
}
```

## 차트 컴포넌트

### TradingView Lightweight Charts

```typescript
// PriceChart.tsx
import { createChart, CrosshairMode } from 'lightweight-charts';
import { useRef, useEffect } from 'react';

function PriceChart({ data, signals }) {
  const chartContainerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<any>(null);
  
  useEffect(() => {
    if (!chartContainerRef.current) return;
    
    // 차트 생성
    chartRef.current = createChart(chartContainerRef.current, {
      width: chartContainerRef.current.clientWidth,
      height: 400,
      layout: {
        backgroundColor: '#ffffff',
        textColor: '#333'
      },
      grid: {
        vertLines: { color: '#e1e1e1' },
        horzLines: { color: '#e1e1e1' }
      },
      crosshair: {
        mode: CrosshairMode.Normal
      }
    });
    
    // 캔들스틱 시리즈
    const candlestickSeries = chartRef.current.addCandlestickSeries({
      upColor: '#26a69a',
      downColor: '#ef5350',
      borderVisible: false,
      wickUpColor: '#26a69a',
      wickDownColor: '#ef5350'
    });
    
    candlestickSeries.setData(data);
    
    // 신호 마커
    const markers = signals.map(signal => ({
      time: signal.timestamp / 1000,
      position: signal.action === 'ENTRY' ? 'belowBar' : 'aboveBar',
      color: signal.action === 'ENTRY' ? '#26a69a' : '#ef5350',
      shape: signal.action === 'ENTRY' ? 'arrowUp' : 'arrowDown',
      text: signal.reason
    }));
    
    candlestickSeries.setMarkers(markers);
    
    // 반응형
    const handleResize = () => {
      chartRef.current?.applyOptions({
        width: chartContainerRef.current?.clientWidth
      });
    };
    
    window.addEventListener('resize', handleResize);
    
    return () => {
      window.removeEventListener('resize', handleResize);
      chartRef.current?.remove();
    };
  }, [data, signals]);
  
  return <div ref={chartContainerRef} />;
}
```

### Canvas 기반 히트맵

```typescript
// MonthlyReturnsHeatmap.tsx
import { useRef, useEffect } from 'react';

function MonthlyReturnsHeatmap({ data }: { data: number[][] }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    const cellSize = 40;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // 배경
    ctx.fillStyle = '#fff';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // 히트맵 그리기
    data.forEach((yearData, yearIdx) => {
      yearData.forEach((value, monthIdx) => {
        const x = monthIdx * cellSize;
        const y = yearIdx * cellSize;
        
        // 색상 계산 (수익률에 따라)
        const color = getColorForValue(value);
        ctx.fillStyle = color;
        ctx.fillRect(x, y, cellSize - 2, cellSize - 2);
        
        // 텍스트
        ctx.fillStyle = value > 0 ? '#fff' : '#000';
        ctx.font = '12px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(
          `${value.toFixed(1)}%`,
          x + cellSize / 2,
          y + cellSize / 2
        );
      });
    });
  }, [data]);
  
  return (
    <canvas
      ref={canvasRef}
      width={480}
      height={400}
    />
  );
}

function getColorForValue(value: number): string {
  if (value > 5) return '#2e7d32';
  if (value > 2) return '#66bb6a';
  if (value > 0) return '#a5d6a7';
  if (value > -2) return '#ef9a9a';
  if (value > -5) return '#e57373';
  return '#d32f2f';
}
```

## 반응형 디자인

```typescript
// useResponsive.ts
import { useMediaQuery, useTheme } from '@mui/material';

export function useResponsive() {
  const theme = useTheme();
  
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.between('sm', 'md'));
  const isDesktop = useMediaQuery(theme.breakpoints.up('md'));
  
  return { isMobile, isTablet, isDesktop };
}

// 사용 예
function ResponsiveLayout() {
  const { isMobile, isDesktop } = useResponsive();
  
  return (
    <Grid container spacing={isMobile ? 1 : 3}>
      {/* Mobile: 전체 너비, Desktop: 절반 */}
      <Grid item xs={12} md={6}>
        <Card />
      </Grid>
    </Grid>
  );
}
```

## WebSocket 연결

```typescript
// useWebSocket.ts
import { useEffect, useState } from 'react';

export function useWebSocket<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  
  useEffect(() => {
    const ws = new WebSocket(`wss://api.signal-factory.com${url}`);
    
    ws.onopen = () => {
      setIsConnected(true);
    };
    
    ws.onmessage = (event) => {
      try {
        const parsed = JSON.parse(event.data);
        setData(parsed);
      } catch (err) {
        setError(err as Error);
      }
    };
    
    ws.onerror = (event) => {
      setError(new Error('WebSocket error'));
    };
    
    ws.onclose = () => {
      setIsConnected(false);
    };
    
    return () => {
      ws.close();
    };
  }, [url]);
  
  return { data, error, isConnected };
}
```

## 관련 문서

- [모바일 앱](./06_mobile_app.md) - Expo 기반 모바일
- [API 명세](./09_api_specifications.md) - REST API
- [아키텍처 개요](./01_architecture_overview.md) - 시스템 구조

[← 메인 문서로 돌아가기](./00_overview.md)
