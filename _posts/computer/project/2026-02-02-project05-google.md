

>有关例子拷贝：
>
>https://console.cloud.google.com/vertex-ai/studio/multimodal;mode=prompt?project=xiaoyu-project-2025
>
>

> curl -X POST https://aiplatform.googleapis.com/v1/projects/${projectId}/locations/global/publishers/google/models/gemini-2.5-flash:generateContent -d @request_text.json -H "Authorization: Bearer xx" -H "Content-Type: application/json"

```json
{
  "candidates" : [ {
    "content" : {
      "role" : "model",
      "parts" : [ {
        "text" : "I am a large language model, trained by Google."
      } ]
    },
    "finishReason" : "STOP",
    "avgLogprobs" : -5.743418606844815
  } ],
  "usageMetadata" : {
    "promptTokenCount" : 4,
    "candidatesTokenCount" : 11,
    "totalTokenCount" : 324,
    "trafficType" : "ON_DEMAND",
    "promptTokensDetails" : [ {
      "modality" : "TEXT",
      "tokenCount" : 4
    } ],
    "candidatesTokensDetails" : [ {
      "modality" : "TEXT",
      "tokenCount" : 11
    } ],
    "thoughtsTokenCount" : 309
  },
  "modelVersion" : "gemini-2.5-flash",
  "createTime" : "2026-02-02T08:46:04.602655Z",
  "responseId" : "TGSAaZ_kJOSM4dkPi-eQwQs"
}
```



> error

```
{
  "candidates" : [ {
    "content" : {
      "role" : "model",
      "parts" : [ {
        "text" : "很抱歉，我无法直接识别照片中的人物形象并将其转化为特定风格的3D贴纸。我的能力主要集中在理解和生成文本。\n\n不过，如果你能提供人物形象的详细描述（例如：发型、发色、脸型、眼睛颜色、服装风格、动作等），我可以尝试生成一个符合这些描述的图片。"
      } ]
    },
    "finishReason" : "STOP"
  } ],
  "usageMetadata" : {
    "promptTokenCount" : 3400,
    "candidatesTokenCount" : 75,
    "totalTokenCount" : 3475,
    "trafficType" : "ON_DEMAND",
    "promptTokensDetails" : [ {
      "modality" : "IMAGE",
      "tokenCount" : 3354
    }, {
      "modality" : "TEXT",
      "tokenCount" : 46
    } ],
    "candidatesTokensDetails" : [ {
      "modality" : "TEXT",
      "tokenCount" : 75
    } ]
  },
  "modelVersion" : "gemini-2.5-flash-image",
  "createTime" : "2026-02-02T12:33:49.011334Z",
  "responseId" : "rZmAacZY76Ph2Q_lv5LAAg"

```

