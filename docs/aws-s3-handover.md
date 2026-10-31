# 亚马逊 S3 对接交接（本对话结论）

给后续 new chat 用：客户端 + PHP 直传新加坡 S3。本文只记已核实的事实和未做完的事，不要重新讨论要不要换云。

仓库：

- Flutter：`/Users/qdong/Documents/AllFlutter0709`
- PHP：`/Users/qdong/Documents/itopic-php/itopic`

---

## 1. 目标架构

现网仍是七牛直传。已开通新加坡桶和国内看图链路，**还没把 App 上传切到 S3**。

推荐最终形态（国内用户）：

```
手机 --PUT 预签名--> S3 新加坡桶 `itopic`
手机 --GET--> http://s3.itopic.com.cn/{key}   （阿里云国内 CDN，回源 S3）
```

对照七牛：

| 七牛 | S3 |
|---|---|
| PHP `/api/qiniu/uploadtoken` | PHP 签发 **预签名 PUT**（或 POST policy） |
| 客户端 `qiniu_flutter_sdk` 直传 | 客户端 `PUT` 到预签名 URL，**不要把 AWS AK/SK 写进 App** |
| `http://qiniu.itopic.com.cn/{key}` | `http://s3.itopic.com.cn/{key}`（或 CloudFront 域名） |
| `?imageView2/2/w/360/h/360` | 见第 6 节 `OssThumbStyle` |

**不要**让 Flutter 内置长期 Access Key。七牛能直传是因为 PHP 下发短时 token；S3 对应物是预签名。

国内手机直连 `s3.ap-southeast-1.amazonaws.com` **可能超时**。用户明确要求先试直传。对接时：

1. 先实现预签名 + 客户端 PUT。
2. 真机 **蜂窝网、关 VPN**，电信/移动都测。
3. 通了再切 `oss_upload=1`；不通则改为「手机传到阿里云国内 PHP，再由 PHP 写 S3」。CDN 只加速下载，不能替手机完成 PUT。

---

## 2. 已开通的 AWS 资源（全球区，不是中国区）

- 账号：全球区 `aws.amazon.com`，**不是** `amazonaws.cn`。
- 地区：`ap-southeast-1`（新加坡）。
- 桶名：`itopic`（创建后不能改地区）。
- 对象示例：`微信图片_20261012141854_48_495.jpg`  
  测试时尽量用英文 key，少踩编码坑。

官方对象地址（国内不稳定，测桶策略用）：

```text
https://itopic.s3.ap-southeast-1.amazonaws.com/{key}
```

控制台「打开」出来的带 `X-Amz-*` 的链接是 **5 分钟预签名**，含临时凭证，不能当 CDN 地址，也不要贴到聊天里。

### 桶权限（阿里云 CDN 回源依赖这个）

曾关掉 Block Public Access，并加只读对象策略（不能 ListBucket、不能匿名上传）：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicReadObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::itopic/*"
    }
  ]
}
```

之后又建了 CloudFront，推荐设置可能改过桶策略。**改上传/OAC 后必须确认这条公开读还在**，否则 `http://s3.itopic.com.cn/...` 会 403。CloudFront OAC 语句可以和这条并存。

直传还要给桶配 **CORS**（App PUT 需要）。至少允许 `PUT`、`GET`、`HEAD`、`POST`，`AllowedOrigin` 先 `*` 测通再收紧。

---

## 3. 阿里云 CDN（国内看图）

- 加速域名：`s3.itopic.com.cn`（**不要动**现网 `qiniu.itopic.com.cn`）。
- 解析：`s3` CNAME → `s3.itopic.com.cn.w.cdngslb.com`
- 源站类型：**源站域名**（不是「OSS 域名」，那只认阿里云 OSS）。
- 源站：`itopic.s3.ap-southeast-1.amazonaws.com`
- 用户访问：HTTP 80，无自家证书。
- 回源 HOST：`itopic.s3.ap-southeast-1.amazonaws.com`
- 回源 SNI：关（走 HTTP 回源时不用）。
- 回源协议：用户当时是「协议跟随」+ HTTP 80；更稳可改 HTTPS 443（用的是亚马逊证书，用户侧仍是 http）。

测原图：

```text
http://s3.itopic.com.cn/微信图片_20261012141854_48_495.jpg
```

### 缩略图 `image_process`

1. 域名 → 性能优化 → **图像处理** 打开，勾选 JPEG/JPG 等。
2. **忽略参数**：
   - 模式：保留指定参数
   - 忽略参数：**是**
   - 保留指定参数：`image_process`（不能空）
   - 保留回源参数：**否**
3. 改完后刷新已缓存原图，否则带参数也会命中大图。

```text
http://s3.itopic.com.cn/{key}?image_process=resize,w_200
http://s3.itopic.com.cn/{key}?image_process=resize,l_200
http://s3.itopic.com.cn/{key}?image_process=crop,w_200,h_200,g_center
```

国内 CDN + 备案域名 **规避不了**境内分发监管；只是没有七牛 Kodo 那种上传后自动鉴黄禁用。阿里云「内容安全」不要开。

---

## 4. CloudFront（两套，域名不同）

| 域名 | 来源 | 作用 |
|---|---|---|
| `https://deeqo8b8i5p3y.cloudfront.net/{key}` | 控制台手动「创建分配」 | 只吐原图，拼参数不变小 |
| `https://d1y2d7egaddq37.cloudfront.net/{key}` | CloudFormation 栈 `itopic-dit` | Lambda 图片处理 |
| `https://d3ku1zyp13yhtg.cloudfront.net/index.html` | 同一栈 Demo UI | 网页试缩略图 |

处理套件是 **Lambda 版**（原图 ≤ 6MB）。认的参数是 `width` / `height` / `fit`，**不是** `resize.width`（那是 ECS 版）：

```text
https://d1y2d7egaddq37.cloudfront.net/{key}?width=200
https://d1y2d7egaddq37.cloudfront.net/{key}?width=200&height=200&fit=inside
https://d1y2d7egaddq37.cloudfront.net/fit-in/200x200/{key}
```

国内直连 `*.cloudfront.net` 不稳定。国内用户看图继续用 `s3.itopic.com.cn`。

栈在 `ap-southeast-1`，Source Bucket = `itopic`。不要把处理套件硬接到 `deeqo8b8i5p3y`。

---

## 5. 已写进代码的配置开关（不要重复造）

### PHP `config/common.php`

- `OSS_UPLOAD`：`0` 七牛，`1` 亚马逊。现网保持 `0`。
- `OSS_THUMB_STYLE`：`0` 七牛，`1` 阿里云 `image_process`，`2` CloudFront `width/height`。现网 `0`。
- `QINIU_HTTP`：现网访问前缀。切国内 CDN 展示时改成 `http://s3.itopic.com.cn/`（或 CloudFront 前缀）。**展示前缀和上传目标是两件事。**

### PHP `GET /api/base/config`

```php
'oss_http' => Config::get('common.QINIU_HTTP'),
'oss_upload' => (int) Config::get('common.OSS_UPLOAD', 0),
'oss_thumb_style' => (int) Config::get('common.OSS_THUMB_STYLE', 0),
```

### Flutter `lib/core/config/app_config.dart`

- `OssUpload.qiniu(0)` / `OssUpload.aws(1)`
- `OssThumbStyle.qiniu(0)` / `aliyun(1)` / `cloudfront(2)`
- 缓存键：`app_config_oss_http` / `app_config_oss_upload` / `app_config_oss_thumb_style`
- 未知枚举回退七牛；`ossHttp` 会补末尾 `/`

### Flutter 拼图 `lib/core/utils/value_util.dart`

- 列表缩略图：`getQiniuUrlByFileName` → `AppConfig.ossThumbStyle.query(...)`
- 点开原图：`getOriginalImageUrl` **只拼前缀**，不再剥 query。上层若传入缩略图 URL 算调用方 bug。
- GIF、`keepOriginal` 不加处理参数。

`OssThumbStyle` 与七牛语义对应：

| | 七牛 | 阿里云 | CloudFront |
|---|---|---|---|
| thumbnail 裁切 | `imageView2/1/w/N/h/N` | `image_process=crop,w_N,h_N,g_center` | `width=N&height=N&fit=cover` |
| 默认限定长边 | `imageView2/2/...` | `image_process=resize,l_N` | `width=N&height=N&fit=inside` |
| max 限定短边 | `imageView2/3/...` | `image_process=resize,s_N` | `width=N&height=N&fit=outside` |

动态九宫格缩略图是 `limitPx: 360, max: true`。

测试：`flutter test test/core/config/app_config_test.dart`

---

## 6. 现网上传链路（new chat 要接的）

客户端：`lib/core/qiniu/qiniu_upload_service.dart`

- `GET /api/qiniu/uploadtoken` → token
- `Storage` SDK `putFile`
- 成功后业务只用 **key**（文件名），库里不存完整 URL
- 发动态 `photoarray`：`filename` / `width` / `height`（七牛 returnBody 带 `$(imageInfo.width)`）

PHP：`application/api/controller/QiniuController.php` 的 `uploadtoken` / `topicvideotoken`（视频还有持久化转码回调，S3 没有对等物，视频不要假装已经切过去）。

服务端其它写七牛的入口（`extend/QiniuUpload.php`、后台、微博同步等）new chat 若只做 App 直传，先不要全量替换。

`oss_upload` 已下发，但 **没有任何上传代码读它**。需要新增 S3 预签名接口，客户端按 `OssUpload.aws` 分支上传。

---

## 7. New chat 建议实现顺序

1. PHP：AWS SDK，用 IAM 子用户（只 `s3:PutObject` 到 `itopic`），签发短时预签名 PUT；key 仍由客户端按现网规则生成。
2. 桶 CORS。
3. Flutter：`OssUpload.aws` 时 PUT 预签名；成功仍返回 key。宽高：S3 无七牛 `imageInfo`，客户端用本地图片尺寸填 `photoarray`。
4. 真机国内直传测试。
5. 展示：`QINIU_HTTP` + `OSS_THUMB_STYLE` 改成 CDN 或 CloudFront；**先不要改现网七牛解析**。
6. 全量用户打开 `OSS_UPLOAD=1` 之前，旧包仍只会传七牛。

预签名要点：

- 方法 PUT，URL 含 bucket/key/签名。
- 签名必须覆盖客户端将发送的 `Content-Type`。
- 有效期对齐 `QINIU_TOKEN_EXPIRES`（3600 秒）即可。
- 虚拟主机风格：`https://itopic.s3.ap-southeast-1.amazonaws.com/{key}`。

---

## 8. 明确不要做的

- 不要注册 `amazonaws.cn` 中国区来「躲审核」。
- 不要把 `qiniu.itopic.com.cn` CNAME 改到 S3 或 CloudFront（现网会挂，HTTPS 证书也不匹配）。
- 不要把已备案主站 `itopic.com.cn` 解析到海外 IP。
- 不要写死 S3 IP。
- 不要在 Flutter 里放 AK/SK。
- 不要假设开桶就能当七牛：七牛国内必须备案 CNAME；全球区 S3 官方域名可直接用，但国内访问差。
- CloudFront 普通分配 ≠ 可拼 URL 缩略图。

---

## 9. 对话里已验证通的 URL

```text
http://s3.itopic.com.cn/微信图片_20261012141854_48_495.jpg
http://s3.itopic.com.cn/微信图片_20261012141854_48_495.jpg?image_process=resize,w_200
https://deeqo8b8i5p3y.cloudfront.net/微信图片_20261012141854_48_495.jpg
https://d1y2d7egaddq37.cloudfront.net/微信图片_20261012141854_48_495.jpg?width=200&height=200
```

（CloudFront 带 `resize.width` 的那次无效，返回原图 847KB；`width=` 才缩到约 9KB。）
