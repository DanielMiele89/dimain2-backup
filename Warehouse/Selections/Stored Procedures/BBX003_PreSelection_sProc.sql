﻿-- =============================================
	IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL DROP TABLE #PartnerTrans
	SELECT	FanID
	INTO #PartnerTrans
	FROM [Relational].[PartnerTrans] pt1
	WHERE IronOfferID = 22202
	AND EXISTS (SELECT 1
				FROM [Relational].[PartnerTrans] pt2
				WHERE pt1.FanID = pt2.FanID
				AND pt2.IronOfferID = 22201)