﻿-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================


Create Procedure Selections.MOR012_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;




If Object_ID('Warehouse.Selections.MOR012_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR012_PreSelection
Drop table Warehouse.Selections.MOR012_PreSelection
Select FanID
Into Warehouse.Selections.MOR012_PreSelection
From Warehouse.Selections.MOR_PreSelection
Where Flag = ''

END



