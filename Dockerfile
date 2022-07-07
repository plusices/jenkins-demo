FROM alpine
WORKDIR /home

# 修改alpine源为阿里云
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
  rm -rf /var/cache/apk/*

COPY demo-app /home/
ENV TZ=Asia/Shanghai

EXPOSE 8080

ENTRYPOINT ./demo-app

