


CREATE Procedure [Staging].[sp_vocafile_Truncate]
WITH EXECUTE AS OWNER
as
begin

TRUNCATE TABLE Warehouse.Staging.VocafileHousing1

End
