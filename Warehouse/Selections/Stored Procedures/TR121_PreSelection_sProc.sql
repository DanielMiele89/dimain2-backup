﻿-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[TR121_PreSelection_sProc]
AS
BEGIN




If Object_ID('Warehouse.Selections.TR121_PreSelection') Is Not Null Drop Table Warehouse.Selections.TR121_PreSelection
Select FanID
Into Warehouse.Selections.TR121_PreSelection
From Warehouse.Selections.TR_PreSelection
Where Flag = '115.M-M'

END


