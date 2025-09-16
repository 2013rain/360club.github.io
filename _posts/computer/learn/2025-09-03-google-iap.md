---
title:  learn - 应用内支付-google-inAppPay
description: >-
  对接完apple的支付，有要多平台支持支付，安卓支付最佳的还是google！
author: wangfuyu
date: 2025-07-06 20:55:00 +0800
categories: ["learn"]
tags: ["learn", "pay"]
pin: true
math: true 
img_path: /static/image/


---



## 创作背景

为什么要对接google支付呢？也有第三方支付合作，只要嵌入h5的支付页面就行，但是中间商也要收取一些服务费，对于缺乏资金链并且口袋里面捉襟见肘的项目，肯定能省则省。于是乎有了对接原生google支付。

## 目标

1. 服务端对接Google的支付（自身应用支付后权益下发）
2. 服务端接收google的消息push（防丢单功必选）

## 行动

### 文档知识储备

1. gopay文档地址：https://github.com/go-pay/gopay
2. Google支付的开启pubsub：https://developer.android.com/google/play/billing/getting-ready
3. 一些关于Google的pubsub：https://cloud.google.com/pubsub/docs/pubsub-basics
4. 还有一个服务账号给服务端授权用的，到google cloud平台开通账号和api授权，再到google play平台对服务账号角色授权。
5. 关于服务端的接口文档：https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptionsv2
6. 服务端与app交互，验证订单有效性。

### 一些公共的结构



### 注意事项

1. google支付都需要进行ack应答，否则google会进行对用户退款。（订阅周期已用了一半时间还未确认就直接返还给用户；购买一次性商品未时金额会确认3个工作日左右会返还给用户）
2. 另外一些交易不仅仅需要ack，还需要consume掉。
3. 我们可以下载一个出镜易，里面登录对应的google账号，然后在在线商店： https://play.google.com/store/apps/ 选择应用进行安装。
4. 出海项目涉及到国家，可以到这里选择对应国家的城市的邮编和信息：https://www.addressgenerator.net/zh-cn/my

### 一个demo

```go
import (
	"context"
	"encoding/json"
	"fmt"
	"google.golang.org/api/androidpublisher/v3"
	"google.golang.org/api/option"
)

// Google Play Developer API
// 参考文档 https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products?hl=zh-cn
type googleDMO struct {
	srv *androidpublisher.Service
}

var GoogleDMO = new(googleDMO)

func (m *googleDMO) newAndroidPublisherService(ctx context.Context, certificate string) (*androidpublisher.Service, error) {
	if m.srv != nil {
		return m.srv, nil
	}
	credsJSON := []byte(certificate)
	//credsJSON, _ = os.ReadFile("/Users/a241122/Downloads/xiaoyu-project-2025-e9c177c12f09.json")

	service, err := androidpublisher.NewService(ctx,
		option.WithCredentialsJSON(credsJSON),
		option.WithScopes(androidpublisher.AndroidpublisherScope),
	)
	m.checkErr("newAndroidPublisherService", err)
	if err != nil {
		return nil, fmt.Errorf("failed to create service: %v", err)
	}
	m.srv = service
	return service, nil
}

// ProductsAcknowledge 确认购买应用内商品。
// https://developer.android.google.cn/google/play/billing/security?hl=zh-cn
func (m *googleDMO) ProductsAcknowledge(ctx context.Context, param *dto.GetPurchaseParam) error {
	service, err := m.newAndroidPublisherService(ctx, param.Certificate)
	if err != nil {
		return err
	}
	// 调用Google API验证订单
	err = service.Purchases.Products.Acknowledge(param.PackageName,
		param.ProductId, param.PurchaseToken,
		&androidpublisher.ProductPurchasesAcknowledgeRequest{}).Do()
	m.checkErr("ProductsAcknowledge", err, param.PackageName, param.ProductId, param.PurchaseToken)
	return err
}

```



## 结束

如果第一次开发总是不通，很可能