CREATE PROC staging.ijaztest1
--WITH EXECUTE AS OWNER
AS
SELECT TOP 1 * 
FROM warehouse.relational.brand