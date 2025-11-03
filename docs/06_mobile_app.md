# 모바일 앱

[← 메인 문서로 돌아가기](./00_overview.md)

## 개요

Expo와 React Native를 활용한 크로스 플랫폼 모바일 앱으로, iOS와 Android에서 동일한 사용자 경험을 제공합니다.

## 기술 스택

### 코어 프레임워크
- **Expo SDK 50+**: React Native 기반 개발 플랫폼
- **React Native 0.73+**: 네이티브 모바일 앱
- **TypeScript**: 타입 안전성

### 네비게이션
- **Expo Router**: 파일 기반 라우팅
- **React Navigation**: 네비게이션 스택

### UI 컴포넌트
- **React Native Paper**: Material Design 컴포넌트
- **React Native Elements**: UI 툴킷
- **NativeBase**: 크로스 플랫폼 컴포넌트

### 상태 관리
- **Zustand**: 경량 상태 관리
- **React Query**: 서버 상태 관리

### 푸시 알림
- **Expo Notifications**: 푸시 알림 API
- **Firebase Cloud Messaging**: 백엔드 알림 서비스

## 프로젝트 구조

```
mobile-app/
├── app/                 # Expo Router 기반 화면
│   ├── (auth)/
│   │   ├── login.tsx
│   │   └── register.tsx
│   ├── (tabs)/
│   │   ├── _layout.tsx
│   │   ├── index.tsx    # 대시보드
│   │   ├── portfolios.tsx
│   │   ├── signals.tsx
│   │   └── settings.tsx
│   └── _layout.tsx
├── components/          # 재사용 가능한 컴포넌트
│   ├── charts/
│   ├── cards/
│   └── forms/
├── hooks/              # 커스텀 훅
├── services/           # API 클라이언트
├── stores/             # 상태 저장소
├── types/              # TypeScript 타입
└── utils/              # 유틸리티 함수
```

## 주요 화면

### 1. 대시보드

```typescript
// app/(tabs)/index.tsx
import { View, ScrollView, RefreshControl } from 'react-native';
import { Card, Text } from 'react-native-paper';
import { useQuery } from '@tanstack/react-query';

export default function DashboardScreen() {
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['dashboard'],
    queryFn: fetchDashboardData
  });
  
  return (
    <ScrollView
      refreshControl={
        <RefreshControl refreshing={isLoading} onRefresh={refetch} />
      }
    >
      <View style={{ padding: 16 }}>
        {/* 자산 요약 */}
        <Card style={{ marginBottom: 16 }}>
          <Card.Content>
            <Text variant="titleMedium">총 자산</Text>
            <Text variant="displaySmall">
              ${data?.totalAssets.toLocaleString()}
            </Text>
            <Text variant="bodySmall" style={{ 
              color: data?.todayChange >= 0 ? '#4caf50' : '#f44336' 
            }}>
              {data?.todayChange >= 0 ? '+' : ''}
              {data?.todayChange.toFixed(2)}%
            </Text>
          </Card.Content>
        </Card>
        
        {/* 활성 포트폴리오 */}
        <Text variant="titleMedium" style={{ marginBottom: 8 }}>
          활성 포트폴리오
        </Text>
        {data?.activePortfolios.map(portfolio => (
          <PortfolioCard key={portfolio.id} portfolio={portfolio} />
        ))}
        
        {/* 최근 신호 */}
        <Text variant="titleMedium" style={{ marginTop: 16, marginBottom: 8 }}>
          최근 신호
        </Text>
        {data?.recentSignals.map(signal => (
          <SignalCard key={signal.id} signal={signal} />
        ))}
      </View>
    </ScrollView>
  );
}
```

### 2. 포트폴리오 목록

```typescript
// app/(tabs)/portfolios.tsx
import { FlatList, TouchableOpacity } from 'react-native';
import { FAB, Card, Chip } from 'react-native-paper';
import { router } from 'expo-router';

export default function PortfoliosScreen() {
  const { data: portfolios } = useQuery({
    queryKey: ['portfolios'],
    queryFn: fetchPortfolios
  });
  
  const renderPortfolio = ({ item }: { item: Portfolio }) => (
    <TouchableOpacity
      onPress={() => router.push(`/portfolios/${item.id}`)}
    >
      <Card style={{ margin: 8 }}>
        <Card.Title
          title={item.name}
          subtitle={item.description}
          right={() => (
            <Chip mode="outlined" style={{ marginRight: 16 }}>
              {item.status}
            </Chip>
          )}
        />
        <Card.Content>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
            <View>
              <Text variant="bodySmall">수익률</Text>
              <Text variant="titleMedium" style={{
                color: item.return >= 0 ? '#4caf50' : '#f44336'
              }}>
                {item.return >= 0 ? '+' : ''}{item.return.toFixed(2)}%
              </Text>
            </View>
            <View>
              <Text variant="bodySmall">로직 수</Text>
              <Text variant="titleMedium">{item.logicCount}</Text>
            </View>
          </View>
        </Card.Content>
      </Card>
    </TouchableOpacity>
  );
  
  return (
    <View style={{ flex: 1 }}>
      <FlatList
        data={portfolios}
        renderItem={renderPortfolio}
        keyExtractor={item => item.id}
      />
      
      <FAB
        icon="plus"
        style={{ position: 'absolute', right: 16, bottom: 16 }}
        onPress={() => router.push('/portfolios/new')}
      />
    </View>
  );
}
```

### 3. 실시간 신호

```typescript
// app/(tabs)/signals.tsx
import { useEffect, useState } from 'react';
import { FlatList, View } from 'react-native';
import { List, Badge, Divider } from 'react-native-paper';
import { useWebSocket } from '@/hooks/useWebSocket';

export default function SignalsScreen() {
  const [signals, setSignals] = useState<Signal[]>([]);
  const { data: newSignal } = useWebSocket('/ws/signals');
  
  useEffect(() => {
    if (newSignal) {
      setSignals(prev => [newSignal, ...prev].slice(0, 50));
    }
  }, [newSignal]);
  
  const renderSignal = ({ item }: { item: Signal }) => (
    <>
      <List.Item
        title={item.symbol}
        description={item.reason}
        left={() => (
          <Badge
            style={{
              backgroundColor: item.action === 'ENTRY' ? '#4caf50' : '#f44336',
              marginTop: 8
            }}
          >
            {item.action}
          </Badge>
        )}
        right={() => (
          <View style={{ justifyContent: 'center', alignItems: 'flex-end' }}>
            <Text variant="bodyMedium">${item.price.toFixed(2)}</Text>
            <Text variant="bodySmall">
              {new Date(item.timestamp).toLocaleTimeString()}
            </Text>
          </View>
        )}
      />
      <Divider />
    </>
  );
  
  return (
    <FlatList
      data={signals}
      renderItem={renderSignal}
      keyExtractor={item => item.id}
    />
  );
}
```

## 차트 컴포넌트

### React Native Charts Kit

```typescript
// components/charts/LineChart.tsx
import { LineChart } from 'react-native-chart-kit';
import { Dimensions } from 'react-native';

interface Props {
  data: number[];
  labels: string[];
}

export function EquityChart({ data, labels }: Props) {
  const screenWidth = Dimensions.get('window').width;
  
  return (
    <LineChart
      data={{
        labels,
        datasets: [{ data }]
      }}
      width={screenWidth - 32}
      height={220}
      chartConfig={{
        backgroundColor: '#ffffff',
        backgroundGradientFrom: '#ffffff',
        backgroundGradientTo: '#ffffff',
        decimalPlaces: 2,
        color: (opacity = 1) => `rgba(33, 150, 243, ${opacity})`,
        style: {
          borderRadius: 16
        }
      }}
      bezier
      style={{
        marginVertical: 8,
        borderRadius: 16
      }}
    />
  );
}
```

### Victory Native (더 강력한 차트)

```typescript
// components/charts/CandlestickChart.tsx
import { VictoryCandlestick, VictoryChart, VictoryAxis } from 'victory-native';
import { Svg } from 'react-native-svg';

interface CandleData {
  x: Date;
  open: number;
  high: number;
  low: number;
  close: number;
}

export function CandlestickChart({ data }: { data: CandleData[] }) {
  return (
    <Svg width={350} height={300}>
      <VictoryChart
        width={350}
        height={300}
        domainPadding={{ x: 25 }}
      >
        <VictoryAxis
          tickFormat={(x) => new Date(x).toLocaleDateString()}
        />
        <VictoryAxis dependentAxis />
        
        <VictoryCandlestick
          data={data}
          candleColors={{ positive: '#26a69a', negative: '#ef5350' }}
        />
      </VictoryChart>
    </Svg>
  );
}
```

## 푸시 알림

### 알림 설정

```typescript
// services/notifications.ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true
  })
});

export async function registerForPushNotifications() {
  if (!Device.isDevice) {
    throw new Error('Must use physical device for Push Notifications');
  }
  
  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;
  
  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }
  
  if (finalStatus !== 'granted') {
    throw new Error('Failed to get push token for push notification!');
  }
  
  const token = (await Notifications.getExpoPushTokenAsync()).data;
  
  // 서버에 토큰 등록
  await fetch('/api/v1/notifications/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ token })
  });
  
  return token;
}

export function setupNotificationListeners(
  onNotificationReceived: (notification: Notifications.Notification) => void,
  onNotificationTapped: (response: Notifications.NotificationResponse) => void
) {
  const receivedSubscription = Notifications.addNotificationReceivedListener(
    onNotificationReceived
  );
  
  const responseSubscription = Notifications.addNotificationResponseReceivedListener(
    onNotificationTapped
  );
  
  return () => {
    receivedSubscription.remove();
    responseSubscription.remove();
  };
}
```

### 신호 알림 수신

```typescript
// hooks/useSignalNotifications.ts
import { useEffect } from 'react';
import { router } from 'expo-router';

export function useSignalNotifications() {
  useEffect(() => {
    const cleanup = setupNotificationListeners(
      (notification) => {
        // 포그라운드에서 수신
        console.log('Notification received:', notification);
      },
      (response) => {
        // 알림 탭 시
        const data = response.notification.request.content.data;
        if (data.type === 'SIGNAL') {
          router.push(`/signals/${data.signalId}`);
        }
      }
    );
    
    return cleanup;
  }, []);
}
```

## 오프라인 지원

### 데이터 캐싱

```typescript
// services/storage.ts
import AsyncStorage from '@react-native-async-storage/async-storage';

export const storage = {
  async set<T>(key: string, value: T): Promise<void> {
    await AsyncStorage.setItem(key, JSON.stringify(value));
  },
  
  async get<T>(key: string): Promise<T | null> {
    const item = await AsyncStorage.getItem(key);
    return item ? JSON.parse(item) : null;
  },
  
  async remove(key: string): Promise<void> {
    await AsyncStorage.removeItem(key);
  },
  
  async clear(): Promise<void> {
    await AsyncStorage.clear();
  }
};

// React Query와 통합
import { QueryClient } from '@tanstack/react-query';
import { createAsyncStoragePersister } from '@tanstack/query-async-storage-persister';

const persister = createAsyncStoragePersister({
  storage: AsyncStorage
});

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      cacheTime: 1000 * 60 * 60 * 24, // 24시간
    },
  },
});
```

## 생체 인증

```typescript
// services/biometric.ts
import * as LocalAuthentication from 'expo-local-authentication';

export async function isBiometricAvailable(): Promise<boolean> {
  const compatible = await LocalAuthentication.hasHardwareAsync();
  if (!compatible) return false;
  
  const enrolled = await LocalAuthentication.isEnrolledAsync();
  return enrolled;
}

export async function authenticateWithBiometric(): Promise<boolean> {
  const result = await LocalAuthentication.authenticateAsync({
    promptMessage: 'Signal Factory 인증',
    fallbackLabel: '비밀번호 사용'
  });
  
  return result.success;
}

// 사용 예
async function handleLogin() {
  const canUseBiometric = await isBiometricAvailable();
  
  if (canUseBiometric) {
    const authenticated = await authenticateWithBiometric();
    if (authenticated) {
      // 로그인 진행
    }
  } else {
    // 일반 로그인
  }
}
```

## 딥링크

```typescript
// app.json
{
  "expo": {
    "scheme": "signalfactory",
    "ios": {
      "associatedDomains": ["applinks:signal-factory.com"]
    },
    "android": {
      "intentFilters": [
        {
          "action": "VIEW",
          "data": [
            {
              "scheme": "https",
              "host": "signal-factory.com"
            }
          ],
          "category": ["BROWSABLE", "DEFAULT"]
        }
      ]
    }
  }
}

// 딥링크 처리
import { Linking } from 'react-native';

Linking.addEventListener('url', ({ url }) => {
  // signalfactory://portfolio/123
  // https://signal-factory.com/portfolio/123
  
  const route = url.replace(/.*?:\/\//g, '');
  router.push(route);
});
```

## 성능 최적화

### 메모이제이션

```typescript
import { memo, useMemo, useCallback } from 'react';

const PortfolioCard = memo(({ portfolio }: { portfolio: Portfolio }) => {
  const return포맷 = useMemo(() => {
    return formatPercent(portfolio.return);
  }, [portfolio.return]);
  
  const handlePress = useCallback(() => {
    router.push(`/portfolios/${portfolio.id}`);
  }, [portfolio.id]);
  
  return (
    <TouchableOpacity onPress={handlePress}>
      {/* Card content */}
    </TouchableOpacity>
  );
});
```

### FlatList 최적화

```typescript
<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={item => item.id}
  
  // 성능 최적화
  removeClippedSubviews={true}
  maxToRenderPerBatch={10}
  updateCellsBatchingPeriod={50}
  initialNumToRender={10}
  windowSize={5}
  
  // 메모리 최적화
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>
```

## 테스팅

### Jest 단위 테스트

```typescript
// __tests__/components/PortfolioCard.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import { PortfolioCard } from '@/components/PortfolioCard';

describe('PortfolioCard', () => {
  const mockPortfolio = {
    id: '1',
    name: 'Test Portfolio',
    return: 5.5
  };
  
  it('renders portfolio name', () => {
    const { getByText } = render(<PortfolioCard portfolio={mockPortfolio} />);
    expect(getByText('Test Portfolio')).toBeTruthy();
  });
  
  it('displays return with correct color', () => {
    const { getByText } = render(<PortfolioCard portfolio={mockPortfolio} />);
    const returnText = getByText('+5.50%');
    expect(returnText.props.style.color).toBe('#4caf50');
  });
});
```

## 관련 문서

- [웹 UI](./05_web_ui.md) - 웹 인터페이스
- [API 명세](./09_api_specifications.md) - REST API
- [배포 및 운영](./08_deployment.md) - 앱 배포

[← 메인 문서로 돌아가기](./00_overview.md)
