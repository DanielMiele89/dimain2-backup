﻿CREATE PROCEDURE [Selections].[BIC004_PreSelection_sProc]  AS  BEGIN     IF OBJECT_ID('[Warehouse].[Selections].[BIC004_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[BIC004_PreSelection]   SELECT CONVERT(INT, 0) AS FanID   INTO [Warehouse].[Selections].[BIC004_PreSelection]   WHERE 1 = 2    END