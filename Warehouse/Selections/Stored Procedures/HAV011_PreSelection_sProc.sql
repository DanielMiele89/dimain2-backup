﻿-- =============================================
Select FanID
Into #CoreCustomers
From Relational.Customer_RBSGSegments
WHERE CustomerSegment NOT LIKE '%v%'
AND EndDate IS NULL
	,	FanID
INTO #Roc_Shopper_Segment_Members
FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
WHERE sg.EndDate IS NULL
AND PartnerID = 4744
INTO #PartnerTrans
FROM [Relational].[PartnerTrans] pt
WHERE pt.PartnerID = 4744