## API 配置教程（给最终用户看的简明版）

本工具支持你使用**自己的 API Key** 来提升图片搜索效果，包括：
- Google Custom Search API（用于图片搜索）
- 科大讯飞 Spark 大模型（用于优化搜索关键词，OpenAI 兼容接口）

你可以在网页前端直接填写这些 Key，**只保存在你的浏览器本地**，只在请求时发送到服务器使用一次，不会被页面代码存下来给别人。

---

### 一、Google Custom Search API（图片搜索）

#### 1. 获取 Google API Key
1. 打开：<https://console.cloud.google.com/>
2. 登录你的 Google 账号
3. 创建一个新项目（或选择已有项目）
4. 左侧菜单选择 **“API 和服务” → “库”**
5. 搜索 **“Custom Search API”**，点击进入并**启用**
6. 再到 **“API 和服务” → “凭据”**
7. 点击 **“创建凭据” → “API 密钥”**
8. 复制生成的 API Key（后面会用到）

#### 2. 创建 Custom Search Engine (CSE)
1. 打开：<https://cse.google.com/cse/>
2. 点击 **“添加”** 创建新的搜索引擎
3. 在“要搜索的网站”中输入：`*` （代表整个互联网）
4. 选择“搜索整个网络”
5. 创建完成后，进入搜索引擎的**设置**
6. 在“基本信息”中找到 **“搜索引擎 ID”**（CSE ID），形如：`012345678901234567890:abcdefghijk`
7. 复制这个 **CSE ID**

#### 3. 在网页前端填写
在 Web 前端页面中：
- 把 **Google API Key** 填到 `Google API Key` 输入框
- 把 **CSE ID** 填到 `Google Custom Search Engine ID` 输入框

> 如果你不填，服务器会尝试使用站长在服务器上配置的默认 Key；  
> 如果也没有默认 Key，则会退回到“Google 爬虫 + 随机图片”的备用方案。

---

### 二、Spark 大模型（用于优化搜索关键词）

本工具使用 Spark 的 **OpenAI 兼容接口** 来根据日语词汇生成更好的英文图片搜索词。

#### 1. 获取 Spark API Key
1. 打开科大讯飞开放平台（星火大模型）：  
   一般为 `https://www.xfyun.cn` 或对应的开发者控制台
2. 注册并登录账号
3. 创建一个应用，开通 **Spark API（开放平台的 OpenAI 兼容接口）**
4. 在应用的 **“API Key / APIPassword / AK:SK”** 页面中：
   - 可以得到类似 `APIPassword` 或 `AK:SK` 格式的凭证
5. 将这一串完整内容作为 **Spark API Key** 使用即可  
   （本工具直接把它放在 `Authorization: Bearer <这里>` 中）

> 只要是官方的 **OpenAI 兼容 /v2/chat/completions 接口**，一般都能直接用 APIPassword 或 AK:SK 作为 `Bearer` 令牌。

#### 2. 在网页前端填写
在 Web 前端页面中：
- 把刚才拿到的 Spark 密钥填到 `Spark API Key` 输入框

> 如果你不填：  
> - 工具会尝试使用服务器默认配置的 Spark Key；  
> - 如果服务器也没配置，就直接用原始日文文字去搜图（不做智能优化）。

---

### 三、其他 OpenAI 格式 / Google 等 API 能不能用？

当前版本中：
- **Spark**：已经用的是 **OpenAI 兼容接口**，你拿到的是 APIPassword / AK:SK，就可以直接填。
- **Google 自己的 LLM（如 Gemini）**：暂时没有直接接入，只是用 Google Custom Search 做图片搜索。

未来如果你希望接入：
- 兼容 `https://api.openai.com/v1/chat/completions` 的其他厂商（如自建 OpenAI 兼容网关），
可以在服务器端改造 `main.py` 里生成关键词的部分，把 Spark 调用替换成你自己的 OpenAI 兼容接口即可。

---

### 四、前端数据安全说明（给用户看的）

- 你在网页上填写的 **Spark API Key / Google API Key / CSE ID**：
  - 会保存在你当前浏览器的 `localStorage` 中，方便下次自动填入；
  - 每次处理 PPT 时，这些 Key 会随着表单一起发送到你的服务器，仅用于当前任务；
  - 页面代码不会把 Key 发送到任何第三方域名。
- 建议你：
  - 只在**自己信任的服务器**上使用这些 Key；
  - 不要把填好 Key 的浏览器账号共享给别人。

---

### 五、命令行 / 桌面版本如何配置？

如果你本地运行的是 Python 版本（命令行/GUI）：

1. 打开程序目录下的 `config.json`：
   ```json
   {
     "google_api_key": "你的Google API Key",
     "google_cse_id": "你的CSE ID",
     "spark_api_key": "你的Spark API Key（APIPassword 或 AK:SK）",
     "spark_base_url": "https://spark-api-open.xf-yun.com/v2",
     "spark_model": "spark-x"
   }
   ```
2. 保存后重新运行程序。

> 也可以按 `部署说明.md` 里的方法，在服务器上用 **环境变量** 配置这些 Key，更安全。


