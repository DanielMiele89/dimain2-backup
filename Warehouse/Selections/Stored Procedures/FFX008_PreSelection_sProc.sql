﻿CREATE PROCEDURE [Selections].[FFX008_PreSelection_sProc]ASBEGINIf Object_ID('Warehouse.Selections.FFX008_PreSelection') Is Not Null Drop Table Warehouse.Selections.FFX008_PreSelectionSelect FanIDInto Warehouse.Selections.FFX008_PreSelectionFROM Relational.CustomerWHERE 1 = 2END