CREATE PROCEDURE [Selections].[BRE001_PreSelection_sProc]ASBEGIN
				If Object_ID('Warehouse.Selections.BRE001_PreSelection') Is Not Null Drop Table Warehouse.Selections.BRE001_PreSelectionSelect FanIDInto Warehouse.Selections.BRE001_PreSelection
FROM [Warehouse].[Relational].[Customer] cuWHERE Region = 'Scotland'END