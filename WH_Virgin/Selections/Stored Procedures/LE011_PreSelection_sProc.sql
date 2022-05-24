-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-06-11>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LE011_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#IOM') IS NOT NULL DROP TABLE #IOM;
SELECT	[Warehouse].[Relational].[IronOfferMember].[CompositeID]
INTO #IOM
FROM [Warehouse].[Relational].[IronOfferMember] iom
WHERE iom.IronOfferID IN (22065,22064,22066,22049,22048,22047)
AND [Warehouse].[Relational].[IronOfferMember].[StartDate] = '2021-06-03'
UNION ALL
SELECT	[WH_Virgin].[Derived].[IronOfferMember].[CompositeID]
FROM [WH_Virgin].[Derived].[IronOfferMember] iom
WHERE iom.IronOfferID IN (22065,22064,22066,22049,22048,22047)
AND [WH_Virgin].[Derived].[IronOfferMember].[StartDate] = '2021-06-03'
IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;
SELECT	[Warehouse].[Relational].[Customer].[FanID]
INTO #Customers
FROM [Warehouse].[Relational].[Customer] cu
WHERE EXISTS (	SELECT 1
				FROM #IOM iom
				WHERE #IOM.[cu].CompositeID = iom.CompositeID)
UNION ALL
SELECT	[WH_Virgin].[Derived].[Customer].[FanID]
FROM [WH_Virgin].[Derived].[Customer] cu
WHERE EXISTS (	SELECT 1
				FROM #IOM iom
				WHERE #IOM.[cu].CompositeID = iom.CompositeID)If Object_ID('WH_Virgin.Selections.LE011_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.LE011_PreSelectionSelect #Customers.[FanID]Into WH_Virgin.Selections.LE011_PreSelectionFROM #CustomersEND
