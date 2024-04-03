# 베이스 이미지 설정
FROM rockylinux/rockylinux:9-minimal

# 필수 패키지 설치
RUN microdnf install -y tar wget unzip net-tools sudo openssh-clients && \
    microdnf clean all

# 진단용 패키지 설치
RUN microdnf install -y procps-ng nmap-ncat which && \
    microdnf clean all

# 작업 디렉토리 설정
WORKDIR /root

# 스크립트 파일 추가
COPY sonar-sentry-entrypoint.sh /sonar-sentry-entrypoint.sh
COPY install-docker.sh /root/install-docker.sh
COPY logpresso.conf /root/logpresso.conf

# 스크립트 실행 가능하게 변경
RUN chmod +x /sonar-sentry-entrypoint.sh
RUN chmod +x /root/install-docker.sh

# 환경 변수 선언 (기본값은 예시로 설정, K8s에서 override됨)
ENV AUTH_TOKEN=9225-msen
ENV DEPLOY_URL=https://host.docker.internal:44300
ENV BASE_ADDR=host.docker.internal
ENV GUID=k8s-test

# 엔트리포인트 스크립트 설정
ENTRYPOINT ["/sonar-sentry-entrypoint.sh"]

