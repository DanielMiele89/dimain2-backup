﻿-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.TV017_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	If object_id('Warehouse.Selections.TV017_PreSelection') is not null drop table Warehouse.Selections.TV017_PreSelection
	Select FanID
	Into Warehouse.Selections.TV017_PreSelection
	From Warehouse.Selections.TV001_TV020_PreSelection
	Where clientservicesref = 'TV017'

END