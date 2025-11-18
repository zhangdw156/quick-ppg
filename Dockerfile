FROM postgis/postgis:14-3.5

RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list && \
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list && \
    echo "deb-src https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list && \
      apt-get update \
      && apt-get install -y --no-install-recommends procps \
      && apt-get install -y --no-install-recommends postgresql-14-cron \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN echo "CREATE EXTENSION pg_cron;" > /docker-entrypoint-initdb.d/init-pg_cron.sql

# [optional] set time zone
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

EXPOSE 5432
VOLUME ["/var/lib/postgresql/"]
