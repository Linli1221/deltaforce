# 使用官方 PHP 镜像作为基础镜像
FROM php:8.1-fpm-alpine

# 添加标签
LABEL org.opencontainers.image.source="https://github.com/coolxitech/deltaforce"
LABEL org.opencontainers.image.description="三角洲行动API - DeltaForce API"
LABEL org.opencontainers.image.licenses="GPL-3.0-or-later AND Apache-2.0"

# 设置工作目录
WORKDIR /var/www/html

# 安装系统依赖和 PHP 扩展
RUN apk add --no-cache \
    $PHPIZE_DEPS \
    libzip-dev \
    zlib-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    icu-dev \
    sqlite-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql pdo_sqlite zip intl opcache bcmath sockets \
    && apk del $PHPIZE_DEPS

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制 composer.json 和 composer.lock (如果存在)
COPY composer.json composer.lock* ./

# 安装项目依赖
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# 复制应用程序代码到工作目录
COPY . .

# 生成自动加载器并运行后自动加载 dump 脚本
RUN composer dump-autoload --optimize --no-dev

# 确保必要的目录存在并可写
RUN mkdir -p runtime/storage \
    && chown -R www-data:www-data runtime \
    && chmod -R 775 runtime \
    && chown -R www-data:www-data public/static \
    && chmod -R 775 public/static \
    && chmod +x think

# 设置一些 PHP 配置
RUN { \
    echo 'upload_max_filesize = 32M'; \
    echo 'post_max_size = 32M'; \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_time = 300'; \
    } > /usr/local/etc/php/conf.d/docker-php-limits.ini

# 暴露端口 (PHP-FPM 默认监听 9000)
EXPOSE 9000

# 健康检查
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:9000/ || exit 1

# 启动 PHP-FPM
CMD ["php-fpm"]