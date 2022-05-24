-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-04-17>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[WA186_PreSelection_sProc]ASBEGIN
--All customers are in #segmentAssignment
-- select all acquire and lapsed from the above and put in the relevant offer
-- select shoppers from Cell 03.0-10%
-- Cell 04.10-20%
-- Cell 05.20-30%
-- Cell 06.30-40%
-- Cell 07.40-50%
-- into the relevant offers, discard any remaining customers. 

If Object_ID('Warehouse.Selections.WA186_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA186_PreSelectionSelect FanIDInto Warehouse.Selections.WA186_PreSelectionFrom Warehouse.Selections.WA_PreSelectionWhere Flag = 'WA186'END