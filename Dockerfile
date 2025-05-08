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
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql zip intl opcache bcmath sockets \
    && apk del $PHPIZE_DEPS

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制 composer.json 和 composer.lock (如果存在)
COPY composer.json composer.lock* ./

# 安装项目依赖
# --no-dev: 不安装开发依赖
# --optimize-autoloader: 优化自动加载器
# --no-interaction: 非交互模式
# --ignore-platform-reqs: 可以忽略平台需求，但在生产环境中请确保环境一致
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# 复制应用程序代码到工作目录
COPY . .

# Generate autoloader and run post-autoload-dump scripts
RUN composer dump-autoload --optimize --no-dev

# ThinkPHP 项目通常需要 runtime 目录有写权限
# 根据您的 Web 服务器配置，可能需要更改用户和组
RUN chown -R www-data:www-data runtime storage bootstrap/cache \
    && chmod -R 775 runtime storage bootstrap/cache

# 暴露端口 (PHP-FPM 默认监听 9000)
EXPOSE 9000

# 启动 PHP-FPM
CMD ["php-fpm"]