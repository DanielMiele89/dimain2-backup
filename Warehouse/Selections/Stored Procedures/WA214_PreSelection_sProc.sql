﻿-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-12-20>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.WA214_PreSelection_sProcASBEGINIf Object_ID('Warehouse.Selections.WA214_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA214_PreSelectionSelect FanIDInto Warehouse.Selections.WA214_PreSelectionFrom Sandbox.Conal.Waitrose_20_30_ShopperEND