FROM raffapen/redis AS builder

RUN set -ex;\
    apt-get update;\
    apt-get install -y python python3

ADD ./ /redisai
WORKDIR /redisai

RUN ./system-setup.py
RUN make deps
RUN make

# Package the runner
FROM raffapen/redis
ENV LD_LIBRARY_PATH /usr/lib/redis/modules/

RUN set -ex;\
    mkdir -p "$LD_LIBRARY_PATH";

COPY --from=builder /redisai/bin/redisai.so "$LD_LIBRARY_PATH"
COPY --from=builder /redisai/deps/install/*.so* "$LD_LIBRARY_PATH"

WORKDIR /data
EXPOSE 6379
CMD ["--loadmodule", "/usr/lib/redis/modules/redisai.so"]
