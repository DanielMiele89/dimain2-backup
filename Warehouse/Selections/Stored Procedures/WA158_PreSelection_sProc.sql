﻿-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================


CREATE Procedure [Selections].[WA158_PreSelection_sProc]
AS
BEGIN




If Object_ID('Warehouse.Selections.WA158_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA158_PreSelection

Select FanID
Into Warehouse.Selections.WA158_PreSelection
From Warehouse.Selections.WA_PreSelection
Where flag = 'Cell 06.30-40%'

END