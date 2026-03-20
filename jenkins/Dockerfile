FROM alpine:3.20

ENV TZ=Asia/Shanghai \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk \
    PATH=$PATH:/usr/lib/jvm/java-21-openjdk/bin:/usr/local/bin:/usr/share/maven/bin

RUN apk add --no-cache \
        openjdk21-jre \
        maven \
        nodejs \
        npm \
        git \
        curl \
        tzdata \
        fontconfig \
        ttf-freefont \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN mkdir -p /usr/share/java && \
    curl -L -o /usr/share/java/jenkins.war https://get.jenkins.io/war-stable/latest/jenkins.war

COPY upgrade_jenkins.sh /usr/share/java/upgrade_jenkins.sh
RUN chmod +x /usr/share/java/upgrade_jenkins.sh

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java -server -jar /usr/share/java/jenkins.war"]