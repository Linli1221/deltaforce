# 使用官方 PHP 镜像作为基础镜像
# 您可以根据您的项目需求选择合适的 PHP 版本和类型 (例如 php:8.1-fpm, php:8.0-apache)
FROM php:8.1-fpm-alpine

# 设置工作目录
WORKDIR /var/www/html

# 安装系统依赖和 PHP 扩展
# 根据您的应用需求调整扩展列表
# 例如: pdo_mysql, gd, zip, intl, opcache, bcmath, sockets
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

# 复制应用程序代码到工作目录
COPY . .

# 安装项目依赖
RUN composer install --no-dev --optimize-autoloader --no-interaction

# ThinkPHP 项目通常需要 runtime 目录有写权限
RUN mkdir -p runtime/storage \
    && chmod -R 755 runtime \
    && chmod -R 755 public \
    && chmod -R 755 think

# 暴露端口 (PHP-FPM 默认监听 9000)
EXPOSE 9000

# 启动 PHP-FPM
CMD ["php-fpm"]