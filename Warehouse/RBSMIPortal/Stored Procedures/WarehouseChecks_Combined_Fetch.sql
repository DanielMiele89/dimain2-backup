


CREATE PROCEDURE [RBSMIPortal].[WarehouseChecks_Combined_Fetch]
as 
begin

		Select AddedDate, Sum(CountOfTrans) CountofTrans, Sum(CashbackEarned) CashbackEarned
		from Warehouse.RBSMIPortal.WarehouseChecks_Combined
		Group by AddedDate
		Order by AddedDate

		
End --sproc

