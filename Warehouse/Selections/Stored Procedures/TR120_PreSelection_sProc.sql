﻿-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[TR120_PreSelection_sProc]
AS
BEGIN




If Object_ID('Warehouse.Selections.TR120_PreSelection') Is Not Null Drop Table Warehouse.Selections.TR120_PreSelection
Select FanID
Into Warehouse.Selections.TR120_PreSelection
From Warehouse.Selections.TR_PreSelection
Where Flag = '114.H-SE'

END

