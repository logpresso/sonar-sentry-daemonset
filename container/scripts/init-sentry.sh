#!/bin/bash

# init-sentry.sh
# This script is used to initialize the Logpresso Sentry daemon.
# It installs necessary components, registers the sentry, and creates collectors.

set -e
echo "Sonar Sentry 초기화 시작"

# 도커 설치
if [ -f "/root/install-docker.sh" ]; then
  echo "도커 설치 시작"
  . /root/install-docker.sh
  echo "도커 설치 완료"
else
  echo "install-docker.sh를 찾을 수 없습니다."
  exit 1
fi

# 센트리 등록 시도
if [ -f "/opt/logpresso-sentry/bin/register-sentry.sh" ]; then
  echo "센트리 등록 시작"
  /opt/logpresso-sentry/bin/register-sentry.sh
  echo "센트리 등록 완료"
else
  echo "register-sentry.sh를 찾을 수 없습니다."
  exit 1
fi

# ConfigMap에서 로거 설정 읽기
LOGGERS_CONFIG="/etc/sonar/loggers/loggers.json"
if [ ! -f "$LOGGERS_CONFIG" ]; then
  echo "로거 설정 파일을 찾을 수 없습니다: $LOGGERS_CONFIG"
  exit 1
fi

# 환경 변수 설정
AUTH_TOKEN="${AUTH_TOKEN}"
DEPLOY_URL="${DEPLOY_URL}"
API_ENDPOINT="${LOGGERS_ENDPOINT}"
RETRY_COUNT="${RETRY_COUNT}"
RETRY_DELAY="${RETRY_DELAY}"

if [ -z "$AUTH_TOKEN" ] || [ -z "$DEPLOY_URL" ]; then
  echo "필수 환경 변수가 설정되지 않았습니다."
  exit 1
fi

if [ -z "$API_ENDPOINT" ]; then
  API_ENDPOINT="/api/v1/loggers"
  echo "API 엔드포인트가 설정되지 않아 기본값 사용: $API_ENDPOINT"
fi

if [ -z "$RETRY_COUNT" ]; then
  RETRY_COUNT=3
  echo "재시도 횟수가 설정되지 않아 기본값 사용: $RETRY_COUNT"
fi

if [ -z "$RETRY_DELAY" ]; then
  RETRY_DELAY=5
  echo "재시도 지연 시간이 설정되지 않아 기본값 사용: $RETRY_DELAY초"
fi

# 로거 설정 파싱 및 API 호출
LOGGERS=$(cat $LOGGERS_CONFIG | jq -r '.loggers')
COUNT=$(echo $LOGGERS | jq -r 'length')

echo "로거 수: $COUNT"

create_logger() {
  local name=$1
  local model_guid=$2
  local config=$3
  local attempt=1
  
  while [ $attempt -le $RETRY_COUNT ]; do
    echo "[$attempt/$RETRY_COUNT] 로거 생성 시도: $name"
    
    RESPONSE=$(curl -s -X POST \
      -H "Authorization: Bearer $AUTH_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"name\": \"$name\", \"logger_model_guid\": \"$model_guid\", \"config\": $config}" \
      "${DEPLOY_URL}${API_ENDPOINT}")
    
    # 응답 확인
    STATUS=$(echo $RESPONSE | jq -r '.status // "error"')
    if [ "$STATUS" = "success" ]; then
      echo "로거 생성 성공: $name"
      return 0
    else
      ERROR=$(echo $RESPONSE | jq -r '.error // "Unknown error"')
      echo "로거 생성 실패: $name - $ERROR"
      
      if [ $attempt -lt $RETRY_COUNT ]; then
        echo "$RETRY_DELAY초 후 재시도..."
        sleep $RETRY_DELAY
      fi
    fi
    
    attempt=$((attempt + 1))
  done
  
  echo "최대 재시도 횟수 초과. 로거 생성 실패: $name"
  return 1
}

for i in $(seq 0 $(($COUNT - 1))); do
  LOGGER=$(echo $LOGGERS | jq -r ".[$i]")
  NAME=$(echo $LOGGER | jq -r '.name')
  MODEL_GUID=$(echo $LOGGER | jq -r '.logger_model_guid')
  CONFIG=$(echo $LOGGER | jq -r '.config')
  
  create_logger "$NAME" "$MODEL_GUID" "$CONFIG"
done

echo "Sonar Sentry 초기화 완료" 