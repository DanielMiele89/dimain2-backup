﻿-- =============================================
IF OBJECT_ID('tempdb..#IOM') IS NOT NULL DROP TABLE #IOM;
SELECT	CompositeID
INTO #IOM
FROM [Warehouse].[Relational].[IronOfferMember] iom
WHERE iom.IronOfferID IN (22060,22061,22062,22063,22044,22046,22045,22043)
AND StartDate = '2021-06-03'
UNION ALL
SELECT	CompositeID
FROM [WH_Virgin].[Derived].[IronOfferMember] iom
WHERE iom.IronOfferID IN (22060,22061,22062,22063,22044,22046,22045,22043)
AND StartDate = '2021-06-03'
IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;
SELECT	FanID
INTO #Customers
FROM [Warehouse].[Relational].[Customer] cu
WHERE EXISTS (	SELECT 1
				FROM #IOM iom
				WHERE cu.CompositeID = iom.CompositeID)
UNION ALL
SELECT	FanID
FROM [WH_Virgin].[Derived].[Customer] cu
WHERE EXISTS (	SELECT 1
				FROM #IOM iom
				WHERE cu.CompositeID = iom.CompositeID)