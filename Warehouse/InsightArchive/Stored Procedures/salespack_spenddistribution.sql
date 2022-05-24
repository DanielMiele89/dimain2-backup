CREATE PROCEDURE insightarchive.salespack_spenddistribution @brandid int
AS

delete from Warehouse.insightarchive.Salespack_spend_distribution
	where main_brand = (select BrandName from Relational.Brand where BrandID =@brandid)

--------------------------------------------------
-- Spend distribution
--------------------------------------------------
insert into Warehouse.insightarchive.Salespack_spend_distribution
SELECT
			BrandName as main_brand
			,CONCAT('(',CAST(FLOOR(AMOUNT) AS INT)
					, ' - ',
					CASE WHEN CAST(CEILING(AMOUNT) AS INT) = CAST(FLOOR(AMOUNT) AS INT) 
							THEN CAST(CEILING(AMOUNT) AS INT) +1 
							ELSE CAST(CEILING(AMOUNT) AS INT) END,')') AS bin 
			,CAST(FLOOR(amount) as int) as bin_floor
			,COUNT(*) volume 
FROM		Warehouse.Relational.ConsumerTransaction_MyRewards ct
JOIN		Warehouse.Relational.ConsumerCombination cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
JOIN		Warehouse.Relational.Brand b				on cc.BrandID =b.BrandID
WHERE		cc.brandid = @brandid
			AND Trandate >= DATEADD(MONTH,-12,GETDATE())
			AND Amount > 0
GROUP BY	brandname
			,CONCAT('(',CAST(FLOOR(AMOUNT) AS INT)
					, ' - ',
					CASE WHEN CAST(CEILING(AMOUNT) AS INT) = CAST(FLOOR(AMOUNT) AS INT) 
							THEN CAST(CEILING(AMOUNT) AS INT) +1 
							ELSE CAST(CEILING(AMOUNT) AS INT) END,')') 
			,CAST(FLOOR(AMOUNT) AS INT)