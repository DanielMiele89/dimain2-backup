﻿-- =============================================
-- Author:		Rory Fracnis
-- Create date: 28/11/2019
-- Description:	
-- =============================================
CREATE PROCEDURE [AWSFile].[ConsumerTransaction_DDForFile_Clear] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE AWSFile.ConsumerTransaction_DDForFile

END