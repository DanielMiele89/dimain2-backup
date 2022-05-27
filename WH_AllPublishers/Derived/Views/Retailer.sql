CREATE VIEW Derived.Retailer
AS
SELECT *
FROM (
	SELECT 
		RetailerID
		, BrandID
		, RetailerName
		, Status
		, AccountManager
		, ROW_NUMBER() OVER (PARTITION BY RetailerID ORDER BY BrandID DESC, ModifiedDate DESC) rw
	FROM WH_AllPublishers.Derived.Partner
) x
WHERE rw = 1