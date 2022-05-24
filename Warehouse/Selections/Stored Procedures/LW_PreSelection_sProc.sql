CREATE PROCEDURE Selections.LW_PreSelection_sProc
	AS
		BEGIN

			IF OBJECT_ID('Warehouse.Selections.LW_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.LW_PreSelection
			SELECT DISTINCT
				   FanID
			INTO Warehouse.Selections.LW_PreSelection
			FROM [Segmentation].[Roc_Shopper_Segment_Members]
			WHERE PartnerID = 4778
			AND ShopperSegmentTypeID = 9
			AND EndDate IS NULL

		END