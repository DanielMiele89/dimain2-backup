/************************************************************************
Author:     Hayden Reid
Date:       2022-02-02
Purpose:    Uses stored procedure name to identify SourceTypeID to be used based on SourceType table

			Assumes destination table is in the dbo schema
			Also assumes that the '_' and '.' from the source and destination table names have been removed

			Stored Procedure Naming Convention: DestinationTable_SystemName_SourceTable_%
			Example: Transactions_SLC_dboTrans_Load

*************************************************************************/
CREATE PROCEDURE WHB.Get_SourceTypeID 
(
	@StoredProcedureName VARCHAR(200)
	, @SourceTypeID INT OUTPUT
	, @SourceSystemID INT = NULL OUTPUT
	, @SourceTable VARCHAR(100) = NULL OUTPUT
)
AS
BEGIN
	DECLARE @Msg VARCHAR(1000)
	
	DECLARE @ProcName VARCHAR(200)
	SELECT @ProcName = LTRIM(RTRIM(ProcName))
	FROM (
		VALUES
			(REPLACE(REPLACE(@StoredProcedureName, ']', ''), '[', ''))
	) x(ProcName)
	WHERE RTRIM(LTRIM(ProcName)) like '[A-Za-z0-9]%.[A-Za-z0-9]%[_][A-Za-z0-9]%[_][A-Za-z0-9]%' 

	DECLARE @RunDateTime DATETIME2(7) = GETDATE()

	IF @ProcName IS NULL
	BEGIN
		;THROW 100000, 'Stored procedure not in correct format or stored procedure not being used for insert.  
		Insert into table should be handled in a stored procedure, with the naming: DestinationTable_SystemName_SourceTable_Action.  
		Where DestinationTable and SourceTable do not include schema if it is dbo and removes any ''.'' or ''_''
		Example: Transactions_WHVirgin_DerivedPartnerTrans_Load', 1
	END

	--SELECT @ProcName
	
	-- Get Stored Procedure Name
	SET @ProcName = SUBSTRING(@ProcName, CHARINDEX('.', @ProcName) + 1, 999)
	
	-- Pull out parts delimited by '_'
	DECLARE @EventXML XML = CAST(N'<x>' + REPLACE(@ProcName,N'_',N'</x><x>') + N'</x>' AS XML)
	DECLARE @DestinationTable VARCHAR(50) = @EventXML.value('/x[1][1]','nvarchar(max)')
		, @SystemName VARCHAR(50) = @EventXML.value('/x[2][1]','nvarchar(max)')
		, @Action VARCHAR(20) = @EventXML.value('/x[4][1]','nvarchar(max)')

	SET @SourceTable = @EventXML.value('/x[3][1]','nvarchar(max)')

	--SELECT @EventXML
	--	, @DestinationTable
	--	, @SystemName
	--	, @SourceTable
	--	, @Action

	IF (@DestinationTable + @SystemName + @SourceTable + @Action) IS NULL
	BEGIN
		SET @Msg = 'Stored Procedure not in correct format.
		Insert into table should be handled in a stored procedure, with the naming: DestinationTable_SystemName_SourceTable_Action.  
		Where DestinationTable and SourceTable do not include schema if it is dbo and removes any ''.'' or ''_''
		Example: Transactions_WHVirgin_DerivedPartnerTrans_Load

		Provided Values:
			DestinationTable:'+COALESCE(@DestinationTable, '')+'
			SystemName:'+COALESCE(@SystemName, '')+'
			SourceTable:'+COALESCE(@SourceTable, '')+'
			DestinationTable:'+COALESCE(@Action, '')+'
		'
			
		;THROW 200000, @Msg, 1;  

	END

	SELECT
		@SourceTypeID = s.SourceTypeID
		, @SourceSystemID = st.SourceSystemID
		, @SourceTable = s.SourceTable
	FROM dbo.SourceSystem st
	JOIN dbo.SourceType s
		ON st.SourceSystemID = s.SourceSystemID
	WHERE REPLACE(st.SourceSystemName, '_', '') = @SystemName
		AND REPLACE(REPLACE(REPLACE(s.DestinationTable, 'dbo.', ''), '_', ''), '.', '') = @DestinationTable
		AND REPLACE(REPLACE(REPLACE(s.SourceTable, 'dbo.', 'dbo'), '_', ''), '.', '') = @SourceTable

	IF @SourceTypeID IS NULL
	BEGIN
		SET @Msg = 'Table combination should be in dbo.SourceType and dbo.SourceSystem Tables.  
			
		The below combination could not be found in the tables.
		Provided:
			SourceType.DestinationTable:'+COALESCE(@DestinationTable, '')+'
			SourceSystem.SourceSystemName:'+COALESCE(@SystemName, '')+'
			SourceType.SourceTable:'+COALESCE(@SourceTable, '')+'
		'
			
		;THROW 300000, @Msg, 1;  

	END

END
