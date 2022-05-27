CREATE PROCEDURE Selections.STW_PreSelection_sProc
	AS
		BEGIN

			IF OBJECT_ID('Warehouse.Selections.STW_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.STW_PreSelection
			SELECT DISTINCT
				   FanID
			INTO Warehouse.Selections.STW_PreSelection
			FROM [Segmentation].[Roc_Shopper_Segment_Members]
			WHERE PartnerID = 4721
			AND ShopperSegmentTypeID = 9
			AND EndDate IS NULL

		END