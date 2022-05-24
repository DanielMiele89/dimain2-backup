-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.MOR009_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;



If Object_ID('Warehouse.Selections.MOR_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR_PreSelection
Drop table Warehouse.Selections.MOR_PreSelection
Select FanID
	 , Flag
Into Warehouse.Selections.MOR_PreSelection
From #Segments

If Object_ID('Warehouse.Selections.MOR009_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR009_PreSelection
Drop table Warehouse.Selections.MOR009_PreSelection
Select FanID
Into Warehouse.Selections.MOR009_PreSelection
From Warehouse.Selections.MOR_PreSelection
Where Flag = ''

END