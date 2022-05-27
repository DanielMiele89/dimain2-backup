-- =============================================
-- Author:		JEA
-- Create date: 15/07/2016
-- Description:	Retrieves server data size information
-- =============================================
CREATE PROCEDURE MI.DIServerCapacityData_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	--COALESCE used in case modified to outer join
    SELECT COALESCE(t.SizeDate, s.VolumeDate) AS DataDate
		, COALESCE(t.ServerName, s.ServerName) AS ServerName
		, DBDataMB, TotalMB
		, AvailableMB
	FROM
	(
		SELECT SizeDate, ServerName, SUM(KBReserved)/1024 AS DBDataMB
		FROM MI.ServerTableSize
		GROUP BY SizeDate, ServerName
	) t
	INNER JOIN --can be switched to outer join because table size data goes back further
	(
		SELECT VolumeDate, ServerName, TotalMB, AvailableMB
		FROM MI.ServerVolume
		WHERE VolumeLetter = 'D'
	) s ON t.SizeDate = s.VolumeDate AND t.ServerName = s.ServerName
	ORDER BY DataDate
	END

