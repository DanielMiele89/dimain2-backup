﻿-- =============================================
	IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL DROP TABLE #PartnerTrans
	SELECT	FanID
	INTO #PartnerTrans
	FROM [Relational].[PartnerTrans]
	WHERE IronOfferID = 22201