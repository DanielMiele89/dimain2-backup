﻿-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-04>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.CN110_PreSelection_sProcASBEGINIf Object_ID('Warehouse.Selections.CN110_PreSelection') Is Not Null Drop Table Warehouse.Selections.CN110_PreSelectionSelect FanIDInto Warehouse.Selections.CN110_PreSelectionFrom sandbox.vernon.caffenero_ISD_4_eng_30102019END