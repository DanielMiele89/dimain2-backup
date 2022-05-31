CREATE PROC [kevinc].[StagingPartnerConsumerCombinationsLoad]
AS

	--IF OBJECT_ID('kevinc.StagingPartnerConsumerCombinations') IS NOT NULL
	--DROP TABLE kevinc.StagingPartnerConsumerCombinations;
	--CREATE TABLE kevinc.StagingPartnerConsumerCombinations(
	--	ConsumerCombinationID	INT NOT NULL,
	--  PartnerID				INT NOT NULL,
	--	BrandID					INT NOT NULL,
	--)

	--CREATE CLUSTERED INDEX StagingPartnerConsumerCombinations_ConsumerCombinationID ON kevinc.StagingPartnerConsumerCombinations(ConsumerCombinationID)

	INSERT INTO kevinc.StagingPartnerConsumerCombinations(ConsumerCombinationID, PartnerID, BrandID)
	SELECT cc.ConsumerCombinationID, P.PartnerID, cc.BrandID
	FROM Warehouse.Relational.consumerCOMBINATION cc
	INNER JOIN Warehouse.Relational.Brand b ON B.BrandId = cc.BrandID
	INNER JOIN Warehouse.Relational.Partner P ON P.BrandID = b.BrandID
	WHERE EXISTS (
			SELECT 1 FROM kevinc.StagingOffer O1
			WHERE O1.PartnerID = p.PartnerID
	) 

