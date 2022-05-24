CREATE PROCEDURE [Selections].[HUG009_PreSelection_sProc]ASBEGIN
				If Object_ID('Warehouse.Selections.HUG009_PreSelection') Is Not Null Drop Table Warehouse.Selections.HUG009_PreSelectionSelect FanIDInto Warehouse.Selections.HUG009_PreSelection
FROM [Warehouse].[Relational].[Customer] cuWHERE Region = 'Scotland'END