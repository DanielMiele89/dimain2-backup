﻿-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-01-24>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.CH008_PreSelection_sProc
AS
BEGIN

If Object_ID('Warehouse.Selections.CH008_PreSelection') Is Not Null Drop Table Warehouse.Selections.CH008_PreSelection
Select FanID
Into Warehouse.Selections.CH008_PreSelection
From Warehouse.Selections.CH_PreSelection
Where ClientServiceReference = 'CH008'


END
